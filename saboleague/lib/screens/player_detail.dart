import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player.dart';
import '../services/database_service.dart';

class PlayerDetail extends StatefulWidget {
  final Player player;

  const PlayerDetail({Key? key, required this.player}) : super(key: key);

  @override
  _PlayerDetailState createState() => _PlayerDetailState();
}

class _PlayerDetailState extends State<PlayerDetail> with TickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  bool _isFavorite = false;
  late AnimationController _animationController;
  late AnimationController _favoriteAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animations
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _favoriteAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _checkIfFavorite();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _favoriteAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    try {
      final favoritePlayers = await _dbService.getFavoritePlayers();
      if (mounted) {
        setState(() {
          _isFavorite = favoritePlayers.any((p) => p.id == widget.player.id);
        });
      }
    } catch (e) {
      print('Erreur vérification favori joueur: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      // Animation du bouton
      _favoriteAnimationController.forward().then((_) {
        _favoriteAnimationController.reverse();
      });
      
      if (_isFavorite) {
        await _dbService.removePlayer(widget.player.id);
      } else {
        await _dbService.insertPlayer(widget.player);
      }
      
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
      
      // Feedback haptique
      HapticFeedback.lightImpact();
      
      // SnackBar moderne
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(_isFavorite ? 'Joueur ajouté aux favoris' : 'Joueur retiré des favoris'),
            ],
          ),
          backgroundColor: _isFavorite ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Erreur : $e'),
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

  String _calculateAge(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return 'N/A';
    
    try {
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return '$age ans';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Non spécifiée';
    
    try {
      final dateTime = DateTime.parse(date);
      final months = [
        'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
      ];
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar moderne avec photo de profil
          SliverAppBar(
            expandedHeight: 350,
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
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Photo du joueur avec effet hero
                        Hero(
                          tag: 'player_photo_${player.id}',
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: player.photo?.isNotEmpty == true
                                  ? Image.network(
                                      player.photo!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildDefaultAvatar(),
                                    )
                                  : _buildDefaultAvatar(),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Nom du joueur
                        Text(
                          player.name,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        // Position avec badge
                        if (player.position?.isNotEmpty == true)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Color(0xFF14B8A6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              player.position!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.2).animate(
                    CurvedAnimation(
                      parent: _favoriteAnimationController,
                      curve: Curves.elasticOut,
                    ),
                  ),
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
                  children: [
                    // Carte d'informations personnelles
                    _buildPersonalInfoCard(),
                    SizedBox(height: 20),
                    
                    // Carte d'informations professionnelles
                    _buildProfessionalInfoCard(),
                    SizedBox(height: 30),
                    
                    // Bouton d'action flottant
                    _buildActionButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF14B8A6),
            Color(0xFF14B8A6).withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          widget.player.name.isNotEmpty ? widget.player.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
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
              'Informations personnelles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A365D),
              ),
            ),
            SizedBox(height: 20),
            _buildInfoRow(
              Icons.cake,
              'Date de naissance',
              _formatDate(widget.player.birthDate),
              subtitle: _calculateAge(widget.player.birthDate),
            ),
            SizedBox(height: 16),
            _buildInfoRow(
              Icons.flag,
              'Nationalité',
              widget.player.nationality ?? 'Non spécifiée',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfoCard() {
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
              'Informations professionnelles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A365D),
              ),
            ),
            SizedBox(height: 20),
            _buildInfoRow(
              Icons.sports_soccer,
              'Position',
              widget.player.position ?? 'Non spécifiée',
            ),
            SizedBox(height: 16),
            _buildInfoRow(
              Icons.group,
              'Équipe',
              widget.player.teamName ?? 'Non spécifiée',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {String? subtitle}) {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Color(0xFF14B8A6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Color(0xFF14B8A6), size: 22),
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
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A365D),
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF14B8A6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(
          parent: _favoriteAnimationController,
          curve: Curves.easeInOut,
        ),
      ),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isFavorite 
                ? [Colors.red, Colors.red[700]!]
                : [Color(0xFF14B8A6), Color(0xFF0D9488)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_isFavorite ? Colors.red : Color(0xFF14B8A6)).withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggleFavorite,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}