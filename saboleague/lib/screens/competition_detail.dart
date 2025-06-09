import 'package:flutter/material.dart';
import '../models/competition.dart';
import '../models/team.dart';
import '../services/api_service.dart';
import 'team_detail.dart';

class CompetitionDetail extends StatefulWidget {
  final Competition competition;

  CompetitionDetail({required this.competition});

  @override
  _CompetitionDetailState createState() => _CompetitionDetailState();
}

class _CompetitionDetailState extends State<CompetitionDetail> {
  final ApiService apiService = ApiService();
  late Future<List<Team>> _teamsFuture;

  @override
  void initState() {
    super.initState();
    _teamsFuture = apiService.fetchTeamsByCompetition(widget.competition.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.competition.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.competition.logo.isNotEmpty)
              Center(
                child: Image.network(
                  widget.competition.logo,
                  width: 150,
                  height: 150,
                ),
              ),
            SizedBox(height: 20),
            Text(
              widget.competition.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Pays : ${widget.competition.country}'),
            Text('Type : ${widget.competition.type}'),
            SizedBox(height: 20),
            Text('Équipes participantes :', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            FutureBuilder<List<Team>>(
              future: _teamsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Erreur : ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('Aucune équipe trouvée.');
                } else {
                  final teams = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: team.logo.isNotEmpty
                              ? Image.network(team.logo, width: 40, height: 40)
                              : CircleAvatar(child: Text(team.name[0])),
                          title: Text(team.name),
                          subtitle: Text(team.venue),
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
