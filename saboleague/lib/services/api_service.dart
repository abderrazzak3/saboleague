import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/competition.dart';
import '../models/team.dart';
import '../models/player.dart';

/// Service qui gère toutes les requêtes API vers football-data.org
/// Permet de récupérer les données des équipes, joueurs et compétitions
class ApiService {
    /// Clé d'API pour l'authentification auprès de football-data.org
    final String apiKey = '2e41e44e31754e48b9b91087ee7a5f67';

    /// Constructeur du service API
    ApiService();

    /// Récupère la liste des équipes de la Premier League
    /// Retourne une liste d'objets Team
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

    /// Récupère la liste de toutes les compétitions disponibles
    /// Retourne une liste d'objets Competition
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

    /// Recherche des équipes par nom
    /// [query] : Le terme de recherche
    /// Retourne une liste filtrée d'équipes
    Future<List<Team>> searchTeams(String query) async {
        List<Team> allTeams = await fetchTeamsFromApi();
        return allTeams.where((team) =>
            team.name.toLowerCase().contains(query.toLowerCase())).toList();
    }

    /// Récupère la liste des joueurs d'une équipe spécifique
    /// [team] : L'équipe dont on veut récupérer les joueurs
    /// Retourne une liste d'objets Player
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

    /// Récupère la liste des équipes d'une compétition spécifique
    /// [competitionId] : L'ID de la compétition
    /// Retourne une liste d'objets Team
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
