// Import des widgets de base de Flutter
import 'package:flutter/material.dart';
// Import pour les fonctionnalités système comme les vibrations
import 'package:flutter/services.dart';

// Import des modèles de données
import '../models/team.dart'; // Modèle pour les équipes
import '../models/player.dart'; // Modèle pour les joueurs

// Import des services
import '../services/database_service.dart'; // Service pour la base de données locale
import '../services/api_service.dart'; // Service pour les appels API

// Import des écrans
import 'player_detail.dart'; // Écran de détail d'un joueur

/// Écran affichant les détails d'une équipe
/// 
/// Cet écran affiche les informations détaillées d'une équipe, y compris ses joueurs,
/// et permet d'ajouter/l'équipe aux favoris.
class TeamDetail extends StatefulWidget {
  /// L'équipe dont on veut afficher les détails
  final Team team;

  /// Constructeur de l'écran de détail d'une équipe
  const TeamDetail({required this.team});

  @override
  _TeamDetailState createState() => _TeamDetailState();
}

/// État de l'écran de détail d'une équipe
///
/// Gère l'affichage des informations de l'équipe, la liste des joueurs,
/// et les interactions utilisateur comme l'ajout aux favoris.
class _TeamDetailState extends State<TeamDetail> with TickerProviderStateMixin {
  // Services
  final DatabaseService _dbService = DatabaseService(); // Pour la gestion des favoris
  final ApiService _apiService = ApiService(); // Pour les appels API

  // État de l'interface
  bool _isFavorite = false; // Si l'équipe est dans les favoris
  List<Player> _players = []; // Liste des joueurs de l'équipe
  bool _isLoadingPlayers = true; // État de chargement des joueurs
  
  // Contrôleurs d'animation
  late AnimationController _animationController; // Contrôle les animations
  late Animation<double> _fadeAnimation; // Animation de fondu

  @override
  void initState() {
    super.initState();
    // Initialisation du contrôleur d'animation
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800), // Durée de l'animation
      vsync: this, // Synchronisation avec les frames d'écran
    );
    
    // Configuration de l'animation de fondu
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut, // Courbe d'animation fluide
      ),
    );
    
    // Vérification si l'équipe est dans les favoris
    _checkIfFavorite();
    // Chargement de la liste des joueurs
    _loadPlayers();
    // Démarrage de l'animation
    _animationController.forward();
  }

  @override
  void dispose() {
    // Nettoyage des ressources utilisées par le contrôleur d'animation
    // pour éviter les fuites de mémoire
    _animationController.dispose();
    
    // Appel de la méthode dispose de la classe parente
    // Toujours appeler super.dispose() en dernier
    super.dispose();
  }

  /// Vérifie si l'équipe actuelle est dans les favoris
  Future<void> _checkIfFavorite() async {
    try {
      // Récupération de la liste des équipes favorites
      final favoriteTeams = await _dbService.getFavoriteTeams();
      // Vérification si le widget est toujours monté avant de mettre à jour l'état
      if (mounted) {
        setState(() {
          // Vérifie si l'équipe actuelle est dans les favoris
          _isFavorite = favoriteTeams.any((team) => team.id == widget.team.id);
        });
      }
    } catch (e) {
      // En cas d'erreur, on l'affiche dans la console
      print('Erreur vérification favori: $e');
    }
  }

  /// Bascule l'état de favori de l'équipe
  Future<void> _toggleFavorite() async {
    try {
      // Ajout ou suppression de l'équipe des favoris
      if (_isFavorite) {
        await _dbService.removeTeam(widget.team.id);
      } else {
        await _dbService.insertTeam(widget.team);
      }
      
      // Mise à jour de l'interface si le widget est toujours monté
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
      
      // Rétroaction haptique
      HapticFeedback.lightImpact();
      
      // Affichage d'un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border, 
                color: Colors.white,
              ),
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
      // En cas d'erreur, on l'affiche dans la console et on montre un message d'erreur
      print('Erreur toggle favori: $e');
      if (mounted) {
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
  }

  /// Charge la liste des joueurs de l'équipe depuis l'API
  /// 
  /// Cette méthode effectue un appel asynchrone pour récupérer les joueurs de l'équipe
  /// et met à jour l'état de l'interface utilisateur en conséquence.
  /// En cas d'erreur, un message est affiché dans la console et l'état de chargement est mis à jour.
  Future<void> _loadPlayers() async {
    try {
      // Récupération des joueurs via l'API en utilisant l'objet équipe
      final players = await _apiService.fetchPlayersFromApi(widget.team);
      
      // Tri des joueurs par ordre alphabétique
      players.sort((a, b) => a.name.compareTo(b.name));
      
      // Vérification que le widget est toujours monté avant de mettre à jour l'état
      if (mounted) {
        setState(() {
          _players = players; // Mise à jour de la liste des joueurs
          _isLoadingPlayers = false; // Désactivation de l'indicateur de chargement
        });
      }
    } catch (e) {
      // En cas d'erreur, on affiche l'erreur dans la console
      print('Erreur lors du chargement des joueurs: $e');
      
      // Mise à jour de l'interface pour indiquer la fin du chargement
      if (mounted) {
        setState(() {
          _isLoadingPlayers = false; // Désactivation de l'indicateur de chargement
        });
      }
      
      // Optionnel : afficher un message d'erreur à l'utilisateur
      // _showErrorSnackBar('Impossible de charger les joueurs');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond gris clair pour l'ensemble de l'écran
      backgroundColor: Colors.grey[50],
      // Utilisation d'une CustomScrollView pour un défilement personnalisé
      body: CustomScrollView(
        slivers: [
          // Barre d'application extensible avec l'image de l'équipe
          SliverAppBar(
            expandedHeight: 300, // Hauteur maximale de la barre d'application
            pinned: true, // La barre reste visible lors du défilement
            elevation: 0, // Suppression de l'ombre sous la barre
            backgroundColor: Color(0xFF1A365D), // Couleur de fond bleu foncé
            flexibleSpace: FlexibleSpaceBar(
              // Contenu qui s'étend et se contracte
              background: Container(
                // Dégradé de couleur pour le fond
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A365D), // Bleu foncé
                      Color(0xFF1A365D).withOpacity(0.8), // Bleu foncé légèrement transparent
                    ],
                  ),
                ),
                child: Center(
                  // Animation de fondu à l'apparition
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo de l'équipe avec animation Hero pour la transition
                        Hero(
                          tag: 'team_logo_${widget.team.id}',
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white, // Fond blanc pour le logo
                              shape: BoxShape.circle, // Forme circulaire
                              boxShadow: [
                                // Ombre portée pour le relief
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            // Affichage du logo ou d'une icône par défaut
                            child: ClipOval(
                              child: widget.team.logo.isNotEmpty
                                  ? Image.network(
                                      widget.team.logo,
                                      fit: BoxFit.cover,
                                      // Gestion des erreurs de chargement d'image
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(Icons.people, size: 60, color: Color(0xFF1A365D)),
                                    )
                                  : Icon(Icons.people, size: 60, color: Color(0xFF1A365D)),
                            ),
                          ),
                        ),
                        SizedBox(height: 16), // Espacement

                        // Nom de l'équipe
                        Text(
                          widget.team.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center, // Centrage du texte
                        ),
                        SizedBox(height: 8),

                        // Badge du pays de l'équipe
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2), // Fond blanc semi-transparent
                            borderRadius: BorderRadius.circular(20), // Coins arrondis
                          ),
                          child: Text(
                            widget.team.country,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500, // Demi-gras
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bouton d'action dans la barre d'application
            actions: [
              // Conteneur pour le bouton favori avec marge
              Container(
                margin: EdgeInsets.only(right: 16), // Marge à droite
                child: Material(
                  color: Colors.white.withOpacity(0.2), // Fond blanc semi-transparent
                  borderRadius: BorderRadius.circular(25), // Forme circulaire
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25), // Effet de clic circulaire
                    onTap: _toggleFavorite, // Gestion du clic
                    child: Container(
                      width: 50,
                      height: 50,
                      child: Icon(
                        // Icône de cœur pleine ou vide selon l'état
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white, // Rouge si favori, blanc sinon
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
        
          // Contenu principal sous la barre d'application
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation, // Animation de fondu
              child: Padding(
                padding: EdgeInsets.all(20), // Marge autour du contenu
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
                  children: [
                    _buildInfoCard(), // Carte d'informations de l'équipe
                    SizedBox(height: 24), // Espacement
                    
                    _buildPlayersSection(), // Section des joueurs
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la carte d'informations de l'équipe
  Widget _buildInfoCard() {
    return Container(
      width: double.infinity, // Largeur maximale
      decoration: BoxDecoration(
        color: Colors.white, // Fond blanc
        borderRadius: BorderRadius.circular(20), // Coins arrondis
        boxShadow: [
          // Ombre portée légère pour le relief
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Ombre très légère
            blurRadius: 20, // Flou de l'ombre
            offset: Offset(0, 5), // Décalage vers le bas
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24), // Marge intérieure
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
          children: [
            // Titre de la section
            Text(
              'Informations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A365D), // Bleu foncé
              ),
            ),
            SizedBox(height: 20), // Espacement
            // Ligne d'information : Année de fondation
            _buildInfoRow(Icons.calendar_today, 'Fondé en', widget.team.founded.toString()),
            SizedBox(height: 16), // Espacement
            // Ligne d'information : Stade
            _buildInfoRow(Icons.stadium, 'Stade', widget.team.venue),
            SizedBox(height: 16), // Espacement
            // Ligne d'information : Nom court
            _buildInfoRow(Icons.short_text, 'Nom court', widget.team.shortName),
          ],
        ),
      ),
    );
  }

  /// Construit une ligne d'information avec une icône, un libellé et une valeur
  /// 
  /// Paramètres:
  /// - [icon]: L'icône à afficher
  /// - [label]: Le libellé de l'information
  /// - [value]: La valeur de l'information
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        // Conteneur pour l'icône avec fond coloré
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(0xFF14B8A6).withOpacity(0.1), // Teal clair
            borderRadius: BorderRadius.circular(10), // Coins arrondis
          ),
          // Icône centrée
          child: Icon(icon, color: Color(0xFF14B8A6), size: 20), // Icône teal
        ),
        SizedBox(width: 16), // Espacement
        Expanded(
          // Colonne pour le libellé et la valeur
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
            children: [
              // Libellé en petit texte gris
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500, // Demi-gras
                ),
              ),
              // Valeur en plus grand et en bleu foncé
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // Gras
                  color: Color(0xFF1A365D), // Bleu foncé
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construit la section des joueurs de l'équipe
  Widget _buildPlayersSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Fond blanc
        borderRadius: BorderRadius.circular(20), // Coins arrondis
        boxShadow: [
          // Ombre portée légère
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Ombre très légère
            blurRadius: 20, // Flou de l'ombre
            offset: Offset(0, 5), // Décalage vers le bas
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24), // Marge intérieure
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
          children: [
            // En-tête de la section avec titre et compteur
            Row(
              children: [
                // Titre de la section
                Text(
                  'Joueurs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A365D), // Bleu foncé
                  ),
                ),
                Spacer(), // Espacement flexible
                // Badge avec le nombre de joueurs (uniquement quand le chargement est terminé)
                if (!_isLoadingPlayers)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF14B8A6).withOpacity(0.1), // Fond teal clair
                      borderRadius: BorderRadius.circular(15), // Coins arrondis
                    ),
                    child: Text(
                      '${_players.length}', // Nombre de joueurs
                      style: TextStyle(
                        color: Color(0xFF14B8A6), // Texte teal
                        fontWeight: FontWeight.bold, // Gras
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20), // Espacement
            
            // Affichage conditionnel en fonction de l'état de chargement
            if (_isLoadingPlayers)
              _buildLoadingPlayers() // Indicateur de chargement
            else if (_players.isEmpty)
              _buildEmptyPlayers() // Message si pas de joueurs
            else
              _buildPlayersList(), // Liste des joueurs
          ],
        ),
      ),
    );
  }

  /// Construit un indicateur de chargement pour la liste des joueurs
  Widget _buildLoadingPlayers() {
    return Center(
      child: Column(
        children: [
          // Indicateur de progression circulaire
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)), // Teal
          ),
          SizedBox(height: 16), // Espacement
          // Texte d'indication
          Text(
            'Chargement des joueurs...',
            style: TextStyle(color: Colors.grey[600]), // Texte gris
          ),
        ],
      ),
    );
  }

  /// Construit un message lorsque la liste des joueurs est vide
  Widget _buildEmptyPlayers() {
    return Center(
      child: Column(
        children: [
          // Icône de personnes pour indiquer l'absence de joueurs
          Icon(
            Icons.people_outline, // Icône de personnes vides
            size: 64, // Taille augmentée
            color: Colors.grey[400], // Couleur grise
          ),
          SizedBox(height: 16), // Espacement
          // Message d'information
          Text(
            'Aucun joueur trouvé',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600], // Texte gris foncé
              fontWeight: FontWeight.w500, // Demi-gras
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la liste des joueurs de l'équipe
  Widget _buildPlayersList() {
    return Column(
      // Conversion de la liste de joueurs en widgets
      children: _players.map((player) {
        return Container(
          margin: EdgeInsets.only(bottom: 12), // Marge en bas
          decoration: BoxDecoration(
            color: Colors.grey[50], // Fond gris très clair
            borderRadius: BorderRadius.circular(15), // Coins arrondis
            border: Border.all(color: Colors.grey[200]!), // Bordure légère
          ),
          // Tuile pour chaque joueur
          child: ListTile(
            contentPadding: EdgeInsets.all(16), // Marge intérieure
            // Photo du joueur avec animation Hero
            leading: Hero(
              tag: 'player_photo_${player.id}', // Tag unique pour l'animation
              child: Container(
                width: 50, // Largeur fixe
                height: 50, // Hauteur fixe
                decoration: BoxDecoration(
                  shape: BoxShape.circle, // Forme circulaire
                  boxShadow: [
                    // Ombre portée légère
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // Ombre légère
                      blurRadius: 8, // Flou de l'ombre
                      offset: Offset(0, 2), // Décalage vers le bas
                    ),
                  ],
                ),
                // Affichage de la photo du joueur ou d'une icône par défaut
                child: ClipOval(
                  child: player.photo?.isNotEmpty == true
                      ? Image.network(
                          player.photo!, // URL de la photo
                          fit: BoxFit.cover, // Rognage de l'image
                          // Gestion des erreurs de chargement
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Color(0xFF14B8A6).withOpacity(0.1), // Fond teal clair
                            child: Icon(Icons.person, color: Color(0xFF14B8A6)),
                          ),
                        )
                      : Container(
                          // Conteneur par défaut si pas de photo
                          color: Color(0xFF14B8A6).withOpacity(0.1), // Fond teal clair
                          child: Icon(Icons.person, color: Color(0xFF14B8A6)),
                        ),
                ),
              ),
            ),
            // Nom du joueur
            title: Text(
              player.name,
              style: TextStyle(
                fontWeight: FontWeight.w600, // Gras moyen
                fontSize: 16,
                color: Color(0xFF1A365D), // Bleu foncé
              ),
            ),
            // Informations supplémentaires sous le nom
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
              children: [
                SizedBox(height: 4), // Petit espacement
                // Position du joueur
                Text(
                  player.position ?? "Position inconnue",
                  style: TextStyle(
                    color: Color(0xFF14B8A6), // Teal
                    fontWeight: FontWeight.w500, // Demi-gras
                  ),
                ),
                // Nationalité si disponible
                if (player.nationality?.isNotEmpty == true) ...[
                  SizedBox(height: 2), // Très petit espacement
                  Text(
                    player.nationality!,
                    style: TextStyle(
                      color: Colors.grey[600], // Gris foncé
                      fontSize: 12, // Taille de police plus petite
                    ),
                  ),
                ],
              ],
            ),
            // Icône de flèche à droite
            trailing: Icon(
              Icons.arrow_forward_ios, // Icône de flèche
              color: Colors.grey[400], // Gris clair
              size: 16, // Taille réduite
            ),
            // Action au clic sur un joueur
            onTap: () {
              // Navigation vers l'écran de détail du joueur avec une animation de glissement
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      PlayerDetail(player: player), // Écran de détail du joueur
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    // Animation de transition par glissement depuis la droite
                    return SlideTransition(
                      position: animation.drive(
                        Tween(begin: Offset(1.0, 0.0), end: Offset.zero) // De droite à gauche
                            .chain(CurveTween(curve: Curves.easeInOut)), // Courbe d'animation
                      ),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
        );
      }).toList(), // Conversion de l'itérable en liste
    );
  }
}