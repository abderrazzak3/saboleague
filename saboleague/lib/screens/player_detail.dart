// Importations des packages et fichiers nécessaires
import 'package:flutter/material.dart'; // Pour les widgets Flutter de base
import 'package:flutter/services.dart'; // Pour les fonctionnalités système comme les retours haptiques
import '../models/player.dart'; // Modèle de données pour les joueurs
import '../services/database_service.dart'; // Service pour la gestion de la base de données locale

/// Widget d'affichage des détails d'un joueur
/// Ce widget affiche des informations détaillées sur un joueur et permet de l'ajouter/supprimer des favoris
class PlayerDetail extends StatefulWidget {
  final Player player; // Données du joueur à afficher

  const PlayerDetail({Key? key, required this.player}) : super(key: key);

  @override
  _PlayerDetailState createState() => _PlayerDetailState();
}

class _PlayerDetailState extends State<PlayerDetail> with TickerProviderStateMixin {
  // Service pour interagir avec la base de données locale
  final DatabaseService _dbService = DatabaseService();
  
  // État pour suivre si le joueur est dans les favoris
  bool _isFavorite = false;
  
  // Contrôleurs d'animation pour les effets visuels
  late AnimationController _animationController; // Pour l'animation d'entrée
  late AnimationController _favoriteAnimationController; // Pour l'animation du bouton favori
  
  // Animations
  late Animation<double> _fadeAnimation; // Effet de fondu
  late Animation<double> _scaleAnimation; // Effet d'échelle

  @override
  void initState() {
    super.initState();
    
    // Initialisation du contrôleur d'animation principale (800ms)
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this, // Nécessite le mixin TickerProviderStateMixin
    );
    
    // Initialisation du contrôleur d'animation pour le bouton favori (300ms)
    _favoriteAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Configuration de l'animation de fondu (de 0 à 1 d'opacité)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Configuration de l'animation d'échelle (de 80% à 100% de la taille)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    // Vérifier si le joueur est dans les favoris au chargement
    _checkIfFavorite();
    
    // Démarrer l'animation d'entrée
    _animationController.forward();
  }

  @override
  void dispose() {
    // Nettoyer les contrôleurs d'animation pour éviter les fuites de mémoire
    _animationController.dispose();
    _favoriteAnimationController.dispose();
    super.dispose();
  }

  /// Vérifie si le joueur actuel est dans les favoris
  Future<void> _checkIfFavorite() async {
    try {
      // Récupérer la liste des joueurs favoris
      final favoritePlayers = await _dbService.getFavoritePlayers();
      
      // Vérifier si le widget est toujours monté avant de mettre à jour l'état
      if (mounted) {
        setState(() {
          // Vérifier si le joueur actuel est dans la liste des favoris
          _isFavorite = favoritePlayers.any((p) => p.id == widget.player.id);
        });
      }
    } catch (e) {
      // En cas d'erreur, l'afficher dans la console
      print('Erreur vérification favori joueur: $e');
    }
  }

  /// Bascule l'état favori du joueur (ajoute/retire des favoris)
  Future<void> _toggleFavorite() async {
    try {
      // Jouer l'animation du bouton favori
      _favoriteAnimationController.forward().then((_) {
        _favoriteAnimationController.reverse();
      });
      
      // Ajouter ou supprimer le joueur des favoris selon l'état actuel
      if (_isFavorite) {
        await _dbService.removePlayer(widget.player.id);
      } else {
        await _dbService.insertPlayer(widget.player);
      }
      
      // Mettre à jour l'interface utilisateur si le widget est toujours monté
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
      
      // Retour haptique pour le feedback tactile
      HapticFeedback.lightImpact();
    
      // Afficher un message de confirmation
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
      // En cas d'erreur, afficher un message d'erreur
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

  /// Calcule l'âge à partir d'une date de naissance
  /// [birthDate] La date de naissance au format String (doit être parsable par DateTime.parse)
  /// Retourne une chaîne formatée avec l'âge ou 'N/A' en cas d'erreur
  String _calculateAge(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return 'N/A';
    
    try {
      // Parser la date de naissance
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      
      // Calculer l'âge
      int age = now.year - birth.year;
      
      // Ajuster l'âge si l'anniversaire n'est pas encore passé cette année
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      
      return '$age ans';
    } catch (e) {
      // En cas d'erreur de parsing, retourner 'N/A'
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
          
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildPersonalInfoCard(),
                    SizedBox(height: 20),

                    _buildProfessionalInfoCard(),
                    SizedBox(height: 30),

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

  /// Construit la carte des informations professionnelles du joueur
  /// Affiche la position et l'équipe du joueur
  Widget _buildProfessionalInfoCard() {
    return Container(
      width: double.infinity,
      // Style de la carte avec ombre et coins arrondis
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Ombre légère
            blurRadius: 20,
            offset: Offset(0, 5), // Décalage de l'ombre vers le bas
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24), // Espacement intérieur
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
          children: [
            // Titre de la section
            Text(
              'Informations professionnelles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A365D), // Bleu foncé
              ),
            ),
            SizedBox(height: 20), // Espacement après le titre
            
            // Ligne pour la position du joueur
            _buildInfoRow(
              Icons.sports_soccer, // Icône de ballon de foot
              'Position', // Libellé
              widget.player.position ?? 'Non spécifiée', // Position ou valeur par défaut
            ),
            SizedBox(height: 16), // Espacement entre les lignes
            
            // Ligne pour l'équipe du joueur
            _buildInfoRow(
              Icons.group, // Icône de groupe
              'Équipe', // Libellé
              widget.player.teamName ?? 'Non spécifiée', // Nom de l'équipe ou valeur par défaut
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une ligne d'information avec une icône, un libellé et une valeur
  /// [icon] L'icône à afficher à gauche
  /// [label] Le libellé de l'information
  /// [value] La valeur de l'information
  /// [subtitle] Un sous-titre optionnel à afficher sous la valeur
  Widget _buildInfoRow(IconData icon, String label, String value, {String? subtitle}) {
    return Row(
      children: [
        // Conteneur pour l'icône avec fond coloré
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Color(0xFF14B8A6).withOpacity(0.1), // Teal avec opacité réduite
            borderRadius: BorderRadius.circular(12), // Coins arrondis
          ),
          // Icône centrée dans le conteneur
          child: Icon(icon, color: Color(0xFF14B8A6), size: 22), // Icône teal
        ),
        SizedBox(width: 16), // Espacement entre l'icône et le texte
        
        // Conteneur pour le texte (libellé et valeur)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
            children: [
              // Libellé de l'information
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600], // Gris foncé
                  fontWeight: FontWeight.w500, // Demi-gras
                ),
              ),
              SizedBox(height: 2), // Petit espacement
              
              // Valeur de l'information
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // Gras
                  color: Color(0xFF1A365D), // Bleu foncé
                ),
              ),
              
              // Sous-titre optionnel (comme l'âge pour la date de naissance)
              if (subtitle != null) ...[
                SizedBox(height: 2), // Petit espacement
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF14B8A6), // Teal
                    fontWeight: FontWeight.w500, // Demi-gras
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Construit le bouton d'action principal (Ajouter/Retirer des favoris)
  Widget _buildActionButton() {
    return ScaleTransition(
      // Animation de mise à l'échelle au toucher
      scale: Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(
          parent: _favoriteAnimationController,
          curve: Curves.easeInOut, // Courbe d'animation fluide
        ),
      ),
      child: Container(
        width: double.infinity, // Largeur maximale
        height: 56, // Hauteur fixe
        // Style du conteneur avec dégradé et ombre
        decoration: BoxDecoration(
          // Dégradé de couleur qui change selon l'état des favoris
          gradient: LinearGradient(
            colors: _isFavorite 
                ? [Colors.red, Colors.red[700]!] // Rouge pour retirer des favoris
                : [Color(0xFF14B8A6), Color(0xFF0D9488)], // Teal pour ajouter aux favoris
          ),
          borderRadius: BorderRadius.circular(16), // Coins arrondis
          boxShadow: [
            // Ombre portée qui change de couleur selon l'état des favoris
            BoxShadow(
              color: (_isFavorite ? Colors.red : Color(0xFF14B8A6)).withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5), // Décalage de l'ombre vers le bas
            ),
          ],
        ),
        // Conteneur Material pour l'effet de touche (ripple)
        child: Material(
          color: Colors.transparent, // Fond transparent pour voir le dégradé
          child: InkWell(
            borderRadius: BorderRadius.circular(16), // Même rayon que le conteneur parent
            onTap: _toggleFavorite, // Gestionnaire de clic
            // Contenu du bouton (icône + texte)
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Centrage horizontal
              children: [
                // Icône de cœur (plein ou vide selon l'état)
                Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12), // Espacement entre l'icône et le texte
                // Texte du bouton qui change selon l'état
                Text(
                  _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600, // Gras
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