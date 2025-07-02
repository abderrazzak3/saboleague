// Importations des packages et fichiers nécessaires
import 'package:flutter/material.dart'; // Pour les widgets de base de Flutter
import '../models/team.dart'; // Modèle pour les équipes
import '../models/player.dart'; // Modèle pour les joueurs
import '../models/competition.dart'; // Modèle pour les compétitions
import '../services/api_service.dart'; // Service pour les appels API
import 'team_detail.dart'; // Écran de détail d'une équipe
import 'player_detail.dart'; // Écran de détail d'un joueur
import 'competition_detail.dart'; // Écran de détail d'une compétition

/// Écran de recherche permettant de rechercher parmi les compétitions, équipes et joueurs
/// Utilise un système d'onglets pour naviguer entre les différents types de contenu
class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Service pour effectuer les appels API
  final ApiService apiService = ApiService();

  // État de la recherche
  String _searchQuery = ''; // Terme de recherche saisi par l'utilisateur
  
  // Gestion des onglets
  int _selectedTab = 0; // 0 = Compétitions, 1 = Équipes, 2 = Joueurs
  
  // Listes des données chargées
  List<Team> _teams = []; // Liste des équipes
  List<Player> _players = []; // Liste des joueurs
  List<Competition> _competitions = []; // Liste des compétitions
  
  // État de chargement
  bool _isLoading = true; // Indique si les données sont en cours de chargement

  @override
  void initState() {
    super.initState();
    // Au chargement du widget, on récupère les données
    _fetchData();
  }

  /// Récupère les données depuis l'API et met à jour l'état du widget
  Future<void> _fetchData() async {
    try {
      // Récupération des équipes et compétitions en parallèle
      final fetchedTeams = await apiService.fetchTeamsFromApi();
      final fetchedCompetitions = await apiService.fetchCompetitionsFromApi();

      // On récupère les joueurs de la première équipe (à des fins de démonstration)
      final fetchedPlayers = fetchedTeams.isNotEmpty
          ? await apiService.fetchPlayersFromApi(fetchedTeams.first)
          : <Player>[];

      // Mise à jour de l'état avec les nouvelles données
      setState(() {
        _teams = fetchedTeams;
        _players = fetchedPlayers;
        _competitions = fetchedCompetitions;
        _isLoading = false; // Fin du chargement
      });
    } catch (e) {
      // En cas d'erreur, on affiche l'erreur dans la console
      print('Erreur de chargement: $e');
      setState(() {
        _isLoading = false; // On arrête le chargement même en cas d'erreur
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barre d'application avec titre
      appBar: AppBar(title: Text('Recherche Sportive')),
      
      // Contenu principal
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Indicateur de chargement
          : Column(
              children: [
                // Champ de recherche
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: Icon(Icons.search), // Icône de recherche
                      border: OutlineInputBorder(), // Bordure arrondie
                    ),
                    onChanged: (value) {
                      // Mise à jour du terme de recherche à chaque frappe
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                
                // Barre d'onglets
                Row(
                  children: [
                    _buildTabButton('Compétitions', 0), // Onglet Compétitions
                    _buildTabButton('Équipes', 1),      // Onglet Équipes
                    _buildTabButton('Joueurs', 2),      // Onglet Joueurs
                  ],
                ),
                
                // Contenu de l'onglet sélectionné
                Expanded(
                  child: _getCurrentTabView(),
                ),
              ],
            ),
    );
  }

  /// Retourne la vue correspondant à l'onglet sélectionné
  /// 
  /// Retourne:
  /// - La liste des compétitions si l'onglet 0 est sélectionné
  /// - La liste des équipes si l'onglet 1 est sélectionné
  /// - La liste des joueurs si l'onglet 2 est sélectionné
  Widget _getCurrentTabView() {
    switch (_selectedTab) {
      case 0:
        return _buildCompetitionsList(); // Affiche les compétitions
      case 1:
        return _buildTeamsList(); // Affiche les équipes
      case 2:
        return _buildPlayersList(); // Affiche les joueurs
      default:
        return _buildCompetitionsList(); // Par défaut, affiche les compétitions
    }
  }

  /// Construit un bouton d'onglet avec un style conditionnel
  /// 
  /// Paramètres:
  /// - [text]: Le texte à afficher dans le bouton
  /// - [index]: L'index de l'onglet que ce bouton représente
  Widget _buildTabButton(String text, int index) {
    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          // Fond coloré si l'onglet est sélectionné, transparent sinon
          backgroundColor: _selectedTab == index 
              ? Colors.blue[100] 
              : Colors.transparent,
        ),
        onPressed: () {
          // Changement d'onglet au clic
          setState(() {
            _selectedTab = index;
          });
        },
        child: Text(text), // Texte du bouton
      ),
    );
  }

  /// Construit la liste des équipes filtrée par la recherche
  Widget _buildTeamsList() {
    // Filtrage des équipes selon le terme de recherche
    final filtered = _teams
        .where((team) => team.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filtered.length, // Nombre d'éléments dans la liste filtrée
      itemBuilder: (context, index) {
        final team = filtered[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Marge autour de la carte
          child: ListTile(
            // Affichage du logo de l'équipe ou de la première lettre du nom
            leading: team.logo.isNotEmpty
                ? Image.network(team.logo, width: 40, height: 40)
                : CircleAvatar(child: Text(team.name[0])),
            // Nom de l'équipe en gras
            title: Text(team.name, style: TextStyle(fontWeight: FontWeight.bold)),
            // Informations supplémentaires sous forme de colonne
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
              children: [
                Text(team.venue), // Stade de l'équipe
                Text('Fondé en ${team.founded}'), // Année de fondation
              ],
            ),
            // Navigation vers l'écran de détail de l'équipe au clic
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TeamDetail(team: team)),
              );
            },
          ),
        );
      },
    );
  }

  /// Construit la liste des joueurs filtrée par la recherche
  Widget _buildPlayersList() {
    // Filtrage des joueurs selon le terme de recherche
    final filtered = _players
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filtered.length, // Nombre d'éléments dans la liste filtrée
      itemBuilder: (context, index) {
        final player = filtered[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Marge autour de la carte
          child: ListTile(
            // Photo du joueur ou initiale si pas de photo
            leading: player.photo.isNotEmpty
                ? CircleAvatar(backgroundImage: NetworkImage(player.photo))
                : CircleAvatar(child: Text(player.name[0])),
            // Nom du joueur en gras
            title: Text(player.name, style: TextStyle(fontWeight: FontWeight.bold)),
            // Informations supplémentaires sous forme de colonne
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
              children: [
                Text(player.position), // Poste du joueur
                Text('Date de naissance : ${player.birthDate}'), // Date de naissance
                Text('Nationalité : ${player.nationality}'), // Nationalité
              ],
            ),
            // Navigation vers l'écran de détail du joueur au clic
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlayerDetail(player: player)),
              );
            },
          ),
        );
      },
    );
  }

  /// Construit la liste des compétitions filtrée par la recherche
  Widget _buildCompetitionsList() {
    // Filtrage des compétitions selon le terme de recherche
    final filtered = _competitions
        .where((comp) => comp.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filtered.length, // Nombre d'éléments dans la liste filtrée
      itemBuilder: (context, index) {
        final competition = filtered[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Marge autour de la carte
          child: ListTile(
            // Logo de la compétition ou première lettre du nom
            leading: competition.logo.isNotEmpty
                ? Image.network(competition.logo, width: 40, height: 40)
                : CircleAvatar(child: Text(competition.name[0])),
            // Nom de la compétition en gras
            title: Text(
              competition.name,
              style: TextStyle(fontWeight: FontWeight.bold)
            ),
            // Informations supplémentaires sous forme de colonne
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
              children: [
                Text(competition.country), // Pays de la compétition
                Text('Type : ${competition.type}'), // Type de compétition
              ],
            ),
            // Navigation vers l'écran de détail de la compétition au clic
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompetitionDetail(competition: competition),
                ),
              );
            },
          ),
        );
      },
    );
  }
}