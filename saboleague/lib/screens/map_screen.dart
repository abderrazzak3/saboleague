import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/team.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import 'team_detail.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isShowingFavorites = false;
  String? _errorMessage;
  List<Team> _searchResults = [];
  List<Marker> _markers = [];
  LatLng _center = LatLng(48.8566, 2.3522); // Paris
  Team? _selectedTeam;

  @override
  void initState() {
    super.initState();
    _onSearchChanged(); // Charger toutes les équipes au départ
  }

  void _onSearchChanged() async {
    if (_isShowingFavorites) return; // Ne rien faire si on affiche les favoris
    final query = _searchController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _markers = [];
    });

    try {
      final results = query.isEmpty
          ? await _apiService.fetchTeamsFromApi()
          : await _apiService.searchTeams(query);

      _searchResults = results;
      await _buildMarkersFromTeams(_searchResults);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de recherche : $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _buildMarkersFromTeams(List<Team> teams) async {
    List<Marker> markers = [];
    LatLng? firstTeamPosition;

    for (var team in teams) {
      LatLng position;

      try {
        if (team.venue != null && team.venue.isNotEmpty) {
          List<Location> locations = await locationFromAddress(team.venue);
          if (locations.isNotEmpty) {
            position = LatLng(locations[0].latitude, locations[0].longitude);
          } else {
            position = _simulatePosition(team.id);
          }
        } else {
          position = _simulatePosition(team.id);
        }
      } catch (e) {
        position = _simulatePosition(team.id);
      }

      firstTeamPosition ??= position;

      markers.add(Marker(
        width: 40,
        height: 40,
        point: position,
        builder: (ctx) => GestureDetector(
          onTap: () {
            setState(() {
              _selectedTeam = team;
            });
          },
          child: ClipOval(
            child: Image.network(
              team.logo,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 40),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const CircularProgressIndicator();
              },
            ),
          ),
        ),
      ));
    }

    setState(() {
      _markers = markers;
      _center = firstTeamPosition ?? _center;
    });
  }

  Future<void> _loadFavoriteTeams() async {
    setState(() {
      _isLoading = true;
      _isShowingFavorites = true;
      _markers = [];
    });

    try {
      final favorites = await _dbService.getFavoriteTeams(); // SQLite
      await _buildMarkersFromTeams(favorites);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur chargement favoris : $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  LatLng _simulatePosition(int id) {
    double lat = 48.8566 + (id % 10) * 0.02 - 0.1;
    double lng = 2.3522 + (id % 10) * 0.02 - 0.1;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isShowingFavorites
            ? 'Favoris sur la carte'
            : 'Carte des équipes'),
        actions: [
          if (_isShowingFavorites)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Retour à la recherche',
              onPressed: () {
                setState(() {
                  _isShowingFavorites = false;
                  _searchController.clear();
                });
                _onSearchChanged();
              },
            )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (!_isShowingFavorites)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _onSearchChanged(),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une équipe...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(child: Text(_errorMessage!))
                        : FlutterMap(
                            options: MapOptions(
                              center: _center,
                              zoom: 5.5,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              MarkerLayer(markers: _markers),
                            ],
                          ),
              ),
            ],
          ),
          if (_selectedTeam != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTeam = null),
                behavior: HitTestBehavior.translucent,
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // Empêche la propagation du tap au popup
                    child: _TeamPopup(
                      team: _selectedTeam!,
                      onClose: () => setState(() => _selectedTeam = null),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Voir favoris',
        child: const Icon(Icons.favorite),
        onPressed: _loadFavoriteTeams,
      ),
    );
  }
}

class _TeamPopup extends StatefulWidget {
  final Team team;
  final VoidCallback onClose;
  const _TeamPopup({required this.team, required this.onClose});

  @override
  State<_TeamPopup> createState() => _TeamPopupState();
}

class _TeamPopupState extends State<_TeamPopup> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    // On suppose que DatabaseService est accessible via context ou singleton
    final db = DatabaseService();
    final favs = await db.getFavoriteTeams();
    setState(() {
      _isFavorite = favs.any((t) => t.id == widget.team.id);
    });
  }

  Future<void> _removeFavorite() async {
    final db = DatabaseService();
    await db.removeTeam(widget.team.id);
    setState(() {
      _isFavorite = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Équipe retirée des favoris')),
    );
    widget.onClose();
  }

  void _openGoogleMaps() async {
    final query = Uri.encodeComponent(widget.team.venue.isNotEmpty ? widget.team.venue : widget.team.name);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.team;
    final maxWidth = MediaQuery.of(context).size.width * 0.92;
    final minWidth = 320.0;
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            minWidth: minWidth,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 32),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ),
                CircleAvatar(
                  backgroundImage: team.logo.isNotEmpty ? NetworkImage(team.logo) : null,
                  radius: 48,
                  child: team.logo.isEmpty ? Icon(Icons.people, size: 10) : null,
                ),
                SizedBox(height: 16),
                Text(
                  team.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Stade: ${team.venue}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Text('Année de fondation', style: Theme.of(context).textTheme.bodyMedium),
                    Spacer(),
                    Text('${team.founded}', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.flag, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Text('Pays', style: Theme.of(context).textTheme.bodyMedium),
                    Spacer(),
                    Text(team.country, style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Text('Adresse', style: Theme.of(context).textTheme.bodyMedium),
                    Spacer(),
                    Text(team.venue, style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 20),
                if (_isFavorite)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.favorite, color: Colors.white),
                          label: Text('Retirer des favoris'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: Size(0, 48),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                          onPressed: _removeFavorite,
                        ),
                      ),
                    ],
                  ),
                if (_isFavorite) SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.info_outline),
                        label: Text('Détails'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: Size(0, 48),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => TeamDetail(team: team),
                          ));
                          widget.onClose();
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.map),
                        label: Text('Google Maps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: Size(0, 48),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                        onPressed: _openGoogleMaps,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
