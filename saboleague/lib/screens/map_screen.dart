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
  LatLng _center = LatLng(48.8566, 2.3522);
  Team? _selectedTeam;

  @override
  void initState() {
    super.initState();
    _onSearchChanged();
  }

  void _onSearchChanged() async {
    if (_isShowingFavorites) return; 
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
      final favorites = await _dbService.getFavoriteTeams();
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

  /// Génère une position simulée basée sur l'ID de l'équipe
  /// Utilisé quand la géolocalisation de l'adresse échoue
  LatLng _simulatePosition(int id) {
    // Génère des coordonnées autour de Paris avec un décalage basé sur l'ID
    double lat = 48.8566 + (id % 10) * 0.02 - 0.1;
    double lng = 2.3522 + (id % 10) * 0.02 - 0.1;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barre d'application avec titre dynamique selon le mode (recherche/favoris)
      appBar: AppBar(
        title: Text(_isShowingFavorites
            ? 'Favoris sur la carte'  // Titre en mode favoris
            : 'Carte des équipes'),  // Titre en mode recherche
        actions: [
          // Bouton pour revenir à la recherche quand on est en mode favoris
          if (_isShowingFavorites)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Retour à la recherche',
              onPressed: () {
                setState(() {
                  _isShowingFavorites = false;  // Désactive le mode favoris
                  _searchController.clear();    // Vide le champ de recherche
                });
                _onSearchChanged();  // Rafraîchit les résultats
              },
            )
        ],
      ),
      // Corps de l'écran avec une pile de widgets
      body: Stack(
        children: [
          // Colonne principale contenant la barre de recherche et la carte
          Column(
            children: [
              // Affiche la barre de recherche uniquement en mode recherche (pas en mode favoris)
              if (!_isShowingFavorites)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,  // Contrôle le texte saisi
                    onChanged: (val) => _onSearchChanged(),  // Déclenche la recherche à chaque frappe
                    decoration: InputDecoration(
                      hintText: 'Rechercher une équipe...',
                      prefixIcon: const Icon(Icons.search),  // Icône de recherche
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                  ),
                ),
              // Zone d'affichage principale (carte ou indicateur de chargement)
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())  // Indicateur de chargement
                    : _errorMessage != null
                        ? Center(child: Text(_errorMessage!))  // Message d'erreur
                        : FlutterMap(
                            options: MapOptions(
                              center: _center,  // Centre de la carte
                              zoom: 5.5,  // Niveau de zoom initial
                            ),
                            children: [
                              // Couche de tuiles OpenStreetMap
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],  // Sous-domaines pour le load balancing
                              ),
                              // Couche des marqueurs d'équipes
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
                    onTap: () {},
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

/// Popup affichant les détails d'une équipe sur la carte
class _TeamPopup extends StatefulWidget {
  final Team team;  // Équipe à afficher
  final VoidCallback onClose;  // Callback de fermeture
  
  const _TeamPopup({required this.team, required this.onClose});

  @override
  State<_TeamPopup> createState() => _TeamPopupState();
}

class _TeamPopupState extends State<_TeamPopup> {
  bool _isFavorite = false;  // Indique si l'équipe est dans les favoris

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();  // Vérifie si l'équipe est dans les favoris au chargement
  }

  /// Vérifie si l'équipe actuelle est dans les favoris
  Future<void> _checkIfFavorite() async {
    final db = DatabaseService();
    final favs = await db.getFavoriteTeams();  // Récupère tous les favoris
    setState(() {
      // Vérifie si l'équipe actuelle est dans les favoris
      _isFavorite = favs.any((t) => t.id == widget.team.id);
    });
  }

  /// Supprime l'équipe des favoris
  Future<void> _removeFavorite() async {
    final db = DatabaseService();
    await db.removeTeam(widget.team.id);  // Supprime de la base de données
    setState(() {
      _isFavorite = false;  // Met à jour l'état local
    });
    // Affiche un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Équipe retirée des favoris')),
    );
    widget.onClose();  // Ferme la popup
  }

  /// Ouvre Google Maps avec l'emplacement du stade
  void _openGoogleMaps() async {
    // Encode l'adresse ou le nom de l'équipe pour l'URL
    final query = Uri.encodeComponent(widget.team.venue.isNotEmpty ? widget.team.venue : widget.team.name);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    
    // Ouvre Google Maps dans une application externe
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // Affiche une erreur si l'ouverture échoue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupère l'équipe à afficher depuis les propriétés du widget
    final team = widget.team;
    // Définit les contraintes de largeur pour la popup
    final maxWidth = MediaQuery.of(context).size.width * 0.92;  // 92% de la largeur de l'écran
    final minWidth = 320.0;  // Largeur minimale fixe
    // Crée un fond transparent pour la popup
    return Material(
      color: Colors.transparent,  // Fond transparent pour voir la carte en dessous
      child: Center(
        // Conteneur principal de la popup
        child: Container(
          // Contraintes de dimensionnement
          constraints: BoxConstraints(
            maxWidth: maxWidth,  // Largeur maximale
            minWidth: minWidth,  // Largeur minimale
          ),
          // Marge extérieure
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 32),
          // Remplissage intérieur
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          // Style de la popup
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,  // Couleur de fond adaptée au thème
            borderRadius: BorderRadius.circular(32),  // Coins arrondis
            // Ombre portée pour l'effet de flottement
            boxShadow: [
              BoxShadow(
                color: Colors.black26,  // Couleur de l'ombre
                blurRadius: 24,  // Flou de l'ombre
                offset: Offset(0, 8),  // Décalage vertical de l'ombre
              ),
            ],
          ),
          // Contenu défilable pour les petits écrans
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,  // La colonne ne prend que l'espace nécessaire
              crossAxisAlignment: CrossAxisAlignment.center,  // Centrage horizontal
              children: [
                // Bouton de fermeture en haut à droite
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close),  // Icône de fermeture
                    onPressed: widget.onClose,  // Appel du callback de fermeture
                  ),
                ),
                // Logo de l'équipe dans un cercle
                CircleAvatar(
                  backgroundImage: team.logo.isNotEmpty ? NetworkImage(team.logo) : null,
                  radius: 48,  // Taille du cercle
                  // Affiche une icône par défaut si pas de logo
                  child: team.logo.isEmpty ? Icon(Icons.people, size: 10) : null,
                ),
                SizedBox(height: 16),  // Espacement
                // Nom de l'équipe
                Text(
                  team.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,  // Centrage du texte
                ),
                SizedBox(height: 4),  // Petit espacement
                // Nom du stade
                Text(
                  'Stade: ${team.venue}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                Divider(height: 24),  // Ligne de séparation
                // Ligne pour l'année de fondation
                Row(
                  children: [
                    // Icône de calendrier
                    Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),  // Espacement
                    // Libellé
                    Text('Année de fondation', style: Theme.of(context).textTheme.bodyMedium),
                    Spacer(),  // Pousse le texte suivant vers la droite
                    // Valeur en gras
                    Text('${team.founded}', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),  // Espacement entre les lignes
                
                // Ligne pour le pays
                Row(
                  children: [
                    // Icône de drapeau
                    Icon(Icons.flag, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    // Libellé
                    Text('Pays', style: Theme.of(context).textTheme.bodyMedium),
                    Spacer(),
                    // Valeur en gras
                    Text(team.country, style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),  // Espacement entre les lignes
                
                // Ligne pour l'adresse du stade
                Row(
                  children: [
                    // Icône de localisation
                    Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    // Libellé
                    Text('Adresse', style: Theme.of(context).textTheme.bodyMedium),
                    Spacer(),
                    // Valeur en gras (adresse complète du stade)
                    Text(team.venue, style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 20),  // Grand espace avant les boutons
                
                // Bouton pour retirer des favoris (uniquement si l'équipe est dans les favoris)
                if (_isFavorite)
                  Row(
                    children: [
                      // Le bouton prend toute la largeur disponible
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.favorite, color: Colors.white),  // Icône de cœur
                          label: Text('Retirer des favoris'),
                          // Style personnalisé du bouton
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,  // Couleur rouge pour l'action de suppression
                            minimumSize: Size(0, 48),  // Hauteur minimale
                            padding: EdgeInsets.symmetric(vertical: 12),  // Remplissage vertical
                            textStyle: TextStyle(fontSize: 16),  // Taille du texte
                          ),
                          onPressed: _removeFavorite,  // Appel de la fonction de suppression
                        ),
                      ),
                    ],
                  ),
                // Espacement conditionnel si le bouton de favoris est affiché
                if (_isFavorite) SizedBox(height: 10),
                // Bouton pour voir les détails complets de l'équipe
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.info_outline),  // Icône d'information
                        label: Text('Détails'),
                        // Style personnalisé en orange
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,  // Couleur orange
                          foregroundColor: Colors.white,  // Texte blanc
                          minimumSize: Size(0, 48),  // Hauteur minimale
                          padding: EdgeInsets.symmetric(vertical: 12),  // Remplissage
                          textStyle: TextStyle(fontSize: 16),  // Taille du texte
                        ),
                        // Navigation vers l'écran de détail de l'équipe
                        onPressed: () {
                          // Ouvre l'écran de détail
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => TeamDetail(team: team),
                          ));
                          // Ferme la popup
                          widget.onClose();
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),  // Petit espace entre les boutons
                // Bouton pour ouvrir l'emplacement dans Google Maps
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.map),  // Icône de carte
                        label: Text('Google Maps'),
                        // Style personnalisé en vert
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,  // Couleur verte
                          foregroundColor: Colors.white,  // Texte blanc
                          minimumSize: Size(0, 48),  // Hauteur minimale
                          padding: EdgeInsets.symmetric(vertical: 12),  // Remplissage
                          textStyle: TextStyle(fontSize: 16),  // Taille du texte
                        ),
                        // Ouvre Google Maps avec l'emplacement
                        onPressed: _openGoogleMaps,  // Appel de la fonction d'ouverture de Google Maps
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
