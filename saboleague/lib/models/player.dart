/// Modèle représentant un joueur de football
/// Contient toutes les informations d'un joueur et ses méthodes associées
class Player {
  /// Identifiant unique du joueur
  final int id;
  /// Nom complet du joueur
  final String name;
  /// Poste du joueur sur le terrain
  final String position;
  /// Date de naissance du joueur
  final String birthDate;
  /// Nationalité du joueur
  final String nationality;
  /// URL de la photo du joueur
  final String photo;
  /// ID de l'équipe du joueur
  final int teamId;
  /// Nom de l'équipe du joueur
  final String teamName;

  /// Constructeur du modèle Player
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

  /// Crée une instance de Player à partir des données JSON de l'API
  /// [json] : Données JSON du joueur
  /// [teamId] : ID de l'équipe du joueur
  /// [teamName] : Nom de l'équipe du joueur
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

  /// Convertit l'objet Player en Map pour le stockage en base de données
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

  /// Calcule l'âge du joueur à partir de sa date de naissance
  /// Retourne 0 si la date de naissance n'est pas valide
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
