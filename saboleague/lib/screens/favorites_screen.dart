import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/team.dart';
import '../models/player.dart';
import 'team_detail.dart';
import 'player_detail.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Future<List<Team>> _favoriteTeams;
  late Future<List<Player>> _favoritePlayers;
  int _selectedTab = 0; // 0 = Équipes, 1 = Joueurs

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _favoriteTeams = _dbService.getFavoriteTeams();
      _favoritePlayers = _dbService.getFavoritePlayers();
    });
  }

  Future<void> _removeTeam(Team team) async {
    await _dbService.removeTeam(team.id);
    _refreshData();
  }

  Future<void> _removePlayer(Player player) async {
    await _dbService.removePlayer(player.id);
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Favoris'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildTabButton('Équipes', 0),
                  _buildTabButton('Joueurs', 1),
                ],
              ),
            ),
            Expanded(
              child: _selectedTab == 0
                  ? FutureBuilder<List<Team>>(
                      future: _favoriteTeams,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text('Aucune équipe favorite'));
                        }
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final team = snapshot.data![index];
                            return Dismissible(
                              key: Key(team.id.toString()),
                              background: Container(color: Colors.red),
                              onDismissed: (direction) => _removeTeam(team),
                              child: ListTile(
                                leading: team.logo.isNotEmpty
                                    ? Image.network(team.logo, width: 40, height: 40)
                                    : Icon(Icons.people),
                                title: Text(team.name),
                                subtitle: Text(team.country),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeamDetail(team: team),
                                    ),
                                  ).then((_) => _refreshData());
                                },
                              ),
                            );
                          },
                        );
                      },
                    )
                  : FutureBuilder<List<Player>>(
                      future: _favoritePlayers,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text('Aucun joueur favori'));
                        }
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final player = snapshot.data![index];
                            return Dismissible(
                              key: Key(player.id.toString()),
                              background: Container(color: Colors.red),
                              onDismissed: (direction) => _removePlayer(player),
                              child: ListTile(
                                leading: player.photo.isNotEmpty
                                    ? Image.network(player.photo, width: 40, height: 40)
                                    : Icon(Icons.person),
                                title: Text(player.name),
                                subtitle: Text(player.position),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlayerDetail(player: player),
                                    ),
                                  ).then((_) => _refreshData());
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          foregroundColor: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}