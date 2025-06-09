import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import 'player_detail.dart';
import 'package:flutter/services.dart';

class TeamDetail extends StatefulWidget {
  final Team team;

  const TeamDetail({required this.team});

  @override
  _TeamDetailState createState() => _TeamDetailState();
}

class _TeamDetailState extends State<TeamDetail> with TickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final ApiService _apiService = ApiService();

  bool _isFavorite = false;
  List<Player> _players = [];
  bool _isLoadingPlayers = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkIfFavorite();
    _loadPlayers();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    try {
      final favoriteTeams = await _dbService.getFavoriteTeams();
      if (mounted) {
        setState(() {
          _isFavorite = favoriteTeams.any((team) => team.id == widget.team.id);
        });
      }
    } catch (e) {
      print('Erreur vérification favori: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _dbService.removeTeam(widget.team.id);
      } else {
        await _dbService.insertTeam(widget.team);
      }
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
      
      // Feedback haptique
      HapticFeedback.lightImpact();
      
      // Snackbar moderne
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, 
                   color: Colors.white),
              SizedBox(width: 8),
              Text(_isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris'),
            ],
          ),
          backgroundColor: _isFavorite ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      print('Erreur toggle favori: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Erreur lors de la mise à jour des favoris'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _loadPlayers() async {
    try {
      final players = await _apiService.fetchPlayersFromApi(widget.team);
      players.sort((a, b) => a.name.compareTo(b.name));
      if (mounted) {
        setState(() {
          _players = players;
          _isLoadingPlayers = false;
        });
      }
    } catch (e) {
      print('Erreur chargement joueurs: $e');
      if (mounted) {
        setState(() {
          _isLoadingPlayers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar moderne avec image de fond
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            elevation: 0,
            backgroundColor: Color(0xFF1A365D),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A365D),
                      Color(0xFF1A365D).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo de l'équipe avec effet hero
                        Hero(
                          tag: 'team_logo_${widget.team.id}',
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: widget.team.logo.isNotEmpty
                                  ? Image.network(
                                      widget.team.logo,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(Icons.people, size: 60, color: Color(0xFF1A365D)),
                                    )
                                  : Icon(Icons.people, size: 60, color: Color(0xFF1A365D)),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        // Nom de l'équipe
                        Text(
                          widget.team.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        // Pays
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.team.country,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // Bouton favori dans l'app bar
              Container(
                margin: EdgeInsets.only(right: 16),
                child: Material(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: _toggleFavorite,
                    child: Container(
                      width: 50,
                      height: 50,
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Contenu principal
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carte d'informations
                    _buildInfoCard(),
                    SizedBox(height: 24),
                    
                    // Section joueurs
                    _buildPlayersSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A365D),
              ),
            ),
            SizedBox(height: 20),
            _buildInfoRow(Icons.calendar_today, 'Fondé en', widget.team.founded.toString()),
            SizedBox(height: 16),
            _buildInfoRow(Icons.stadium, 'Stade', widget.team.venue),
            SizedBox(height: 16),
            _buildInfoRow(Icons.short_text, 'Nom court', widget.team.shortName),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(0xFF14B8A6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Color(0xFF14B8A6), size: 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A365D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Joueurs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A365D),
                  ),
                ),
                Spacer(),
                if (!_isLoadingPlayers)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF14B8A6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${_players.length}',
                      style: TextStyle(
                        color: Color(0xFF14B8A6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20),
            
            if (_isLoadingPlayers)
              _buildLoadingPlayers()
            else if (_players.isEmpty)
              _buildEmptyPlayers()
            else
              _buildPlayersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlayers() {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement des joueurs...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlayers() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Aucun joueur trouvé',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList() {
    return Column(
      children: _players.map((player) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Hero(
              tag: 'player_photo_${player.id}',
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: player.photo?.isNotEmpty == true
                      ? Image.network(
                          player.photo!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Color(0xFF14B8A6).withOpacity(0.1),
                            child: Icon(Icons.person, color: Color(0xFF14B8A6)),
                          ),
                        )
                      : Container(
                          color: Color(0xFF14B8A6).withOpacity(0.1),
                          child: Icon(Icons.person, color: Color(0xFF14B8A6)),
                        ),
                ),
              ),
            ),
            title: Text(
              player.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF1A365D),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  player.position ?? "Position inconnue",
                  style: TextStyle(
                    color: Color(0xFF14B8A6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (player.nationality?.isNotEmpty == true) ...[
                  SizedBox(height: 2),
                  Text(
                    player.nationality!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      PlayerDetail(player: player),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
                            .chain(CurveTween(curve: Curves.easeInOut)),
                      ),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}