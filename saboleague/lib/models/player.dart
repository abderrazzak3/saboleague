class Player {
  final int id;
  final String name;
  final String position;
  final String birthDate;
  final String nationality;
  final String photo;
  final int teamId;
  final String teamName;

  Player({
    required this.id,
    required this.name,
    required this.position,
    required this.birthDate,
    required this.nationality,
    required this.photo,
    required this.teamId,
    required this.teamName,
  });

  factory Player.fromJson(Map<String, dynamic> json, int teamId, String teamName) {
    String birthDateFromApi = json['dateOfBirth'] ?? '';

    return Player(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Nom inconnu',
      position: json['position'] ?? 'Inconnue',
      birthDate: birthDateFromApi,
      nationality: json['nationality'] ?? 'Inconnue',
      photo: json['photo'] ?? '',
      teamId: teamId,
      teamName: teamName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'birthDate': birthDate,
      'nationality': nationality,
      'photo': photo,
      'teamId': teamId,
      'teamName': teamName,
    };
  }

  // Optionnel : calculer l'âge à partir de birthDate
  int get age {
    if (birthDate.isEmpty) return 0;
    try {
      final dob = DateTime.parse(birthDate);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }
}
