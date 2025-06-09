import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/competition.dart';
import '../models/team.dart';
import '../models/player.dart';

class ApiService {
  // Correction : pas de const ici, juste final
  final String apiKey = '2e41e44e31754e48b9b91087ee7a5f67';

  // Constructeur (optionnel ici, mais utile pour futures options)
  ApiService();

  Future<List<Team>> fetchTeamsFromApi() async {
    final response = await http.get(
      Uri.parse('https://api.football-data.org/v4/competitions/PL/teams'),
      headers: {'X-Auth-Token': apiKey},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List teamsJson = decoded['teams'] ?? [];

      return teamsJson.map((json) => Team.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors du chargement des équipes');
    }
  }
  Future<List<Competition>> fetchCompetitionsFromApi() async {
    final response = await http.get(
      Uri.parse('https://api.football-data.org/v4/competitions'),
      headers: {'X-Auth-Token': apiKey},
    );

    if (response.statusCode == 200) {
      final List competitionsJson = json.decode(response.body)['competitions'];
      return competitionsJson.map((json) => Competition.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors du chargement des compétitions');
    }
  }

  Future<List<Team>> searchTeams(String query) async {
    List<Team> allTeams = await fetchTeamsFromApi();
    return allTeams.where((team) =>
        team.name.toLowerCase().contains(query.toLowerCase())).toList();
  }


  Future<List<Player>> fetchPlayersFromApi(Team team) async {
    final response = await http.get(
      Uri.parse('https://api.football-data.org/v4/teams/${team.id}'),
      headers: {'X-Auth-Token': apiKey},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List playersJson = decoded['squad'] ?? [];

      return playersJson
          .map<Player>((json) => Player.fromJson(json, team.id, team.name))
          .toList();
    } else {
      throw Exception('Erreur lors du chargement des joueurs de l\'équipe ${team.id}');
    }
  }

  // Dans api_service.dart
  Future<List<Team>> fetchTeamsByCompetition(int competitionId) async {
    final response = await http.get(
      Uri.parse('https://api.football-data.org/v4/competitions/$competitionId/teams'),
      headers: {'X-Auth-Token': apiKey},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List teamsJson = decoded['teams'] ?? [];
      return teamsJson.map((json) => Team.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors du chargement des équipes de la compétition');
    }
  }
}
