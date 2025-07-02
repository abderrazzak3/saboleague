import 'package:flutter/material.dart';
import '../models/competition.dart';
import '../models/team.dart';
import '../services/api_service.dart';
import 'team_detail.dart';

// Widget qui affiche les détails d'une compétition
class CompetitionDetail extends StatefulWidget {
  // La compétition à afficher, passée en paramètre obligatoire
  final Competition competition;

  // Constructeur avec une compétition requise
  CompetitionDetail({required this.competition});

  @override
  _CompetitionDetailState createState() => _CompetitionDetailState();
}

class _CompetitionDetailState extends State<CompetitionDetail> {
  // Service pour effectuer des appels API
  final ApiService apiService = ApiService();
  // Future qui contiendra la liste des équipes de la compétition
  late Future<List<Team>> _teamsFuture;

  @override
  void initState() {
    super.initState();
    // Au chargement du widget, on récupère les équipes de la compétition
    _teamsFuture = apiService.fetchTeamsByCompetition(widget.competition.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barre d'application avec le nom de la compétition
      appBar: AppBar(
        title: Text(widget.competition.name),
      ),
      // Contenu défilable
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage du logo de la compétition s'il existe
            if (widget.competition.logo.isNotEmpty)
              Center(
                child: Image.network(
                  widget.competition.logo,
                  width: 150,
                  height: 150,
                ),
              ),
            SizedBox(height: 20),
            // Nom de la compétition
            Text(
              widget.competition.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Informations sur la compétition
            Text('Pays : ${widget.competition.country}'),
            Text('Type : ${widget.competition.type}'),
            SizedBox(height: 20),
            // Section des équipes participantes
            Text('Équipes participantes :', 
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            // FutureBuilder pour gérer le chargement asynchrone des équipes
            FutureBuilder<List<Team>>(
              future: _teamsFuture,
              builder: (context, snapshot) {
                // Pendant le chargement
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } 
                // En cas d'erreur
                else if (snapshot.hasError) {
                  return Text('Erreur : ${snapshot.error}');
                } 
                // Si aucune donnée n'est disponible
                else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('Aucune équipe trouvée.');
                } 
                // Affichage de la liste des équipes
                else {
                  final teams = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    // Désactive le défilement de cette liste (géré par le parent)
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          // Logo de l'équipe ou première lettre du nom si pas de logo
                          leading: team.logo.isNotEmpty
                              ? Image.network(team.logo, width: 40, height: 40)
                              : CircleAvatar(child: Text(team.name[0])),
                          title: Text(team.name),
                          subtitle: Text(team.venue),
                          // Navigation vers le détail de l'équipe au clic
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TeamDetail(team: team)),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}