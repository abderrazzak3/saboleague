import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../models/competition.dart';
import '../services/api_service.dart';
import 'team_detail.dart';
import 'player_detail.dart';
import 'competition_detail.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService apiService = ApiService();

  String _searchQuery = '';
  int _selectedTab = 0; // 0 = Competitions, 1 = Teams, 2 = Players
  List<Team> _teams = [];
  List<Player> _players = [];
  List<Competition> _competitions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final fetchedTeams = await apiService.fetchTeamsFromApi();
      final fetchedCompetitions = await apiService.fetchCompetitionsFromApi();

      final fetchedPlayers = fetchedTeams.isNotEmpty
          ? await apiService.fetchPlayersFromApi(fetchedTeams.first)
          : <Player>[];

      setState(() {
        _teams = fetchedTeams;
        _players = fetchedPlayers;
        _competitions = fetchedCompetitions;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur de chargement: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recherche Sportive')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Row(
            children: [
              _buildTabButton('Compétitions', 0),
              _buildTabButton('Équipes', 1),
              _buildTabButton('Joueurs', 2),
            ],
          ),
          Expanded(
            child: _getCurrentTabView(),
          ),
        ],
      ),
    );
  }

  Widget _getCurrentTabView() {
    switch (_selectedTab) {
      case 0:
        return _buildCompetitionsList();
      case 1:
        return _buildTeamsList();
      case 2:
        return _buildPlayersList();
      default:
        return _buildCompetitionsList();
    }
  }

  Widget _buildTabButton(String text, int index) {
    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor:
          _selectedTab == index ? Colors.blue[100] : Colors.transparent,
        ),
        onPressed: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Text(text),
      ),
    );
  }

  Widget _buildTeamsList() {
    final filtered = _teams
        .where((team) =>
        team.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final team = filtered[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: team.logo.isNotEmpty
                ? Image.network(team.logo, width: 40, height: 40)
                : CircleAvatar(child: Text(team.name[0])),
            title: Text(team.name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.venue),
                Text('Fondé en ${team.founded}'),
              ],
            ),
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

  Widget _buildPlayersList() {
    final filtered = _players
        .where((p) =>
        p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final player = filtered[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: player.photo.isNotEmpty
                ? CircleAvatar(backgroundImage: NetworkImage(player.photo))
                : CircleAvatar(child: Text(player.name[0])),
            title: Text(player.name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.position),
                Text('Date de naissance : ${player.birthDate}'),
                Text('Nationalité : ${player.nationality}'),
              ],
            ),
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

  Widget _buildCompetitionsList() {
    final filtered = _competitions
        .where((comp) =>
        comp.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final competition = filtered[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: competition.logo.isNotEmpty
                ? Image.network(competition.logo, width: 40, height: 40)
                : CircleAvatar(child: Text(competition.name[0])),
            title: Text(competition.name,
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(competition.country),
                Text('Type : ${competition.type}'),
              ],
            ),
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