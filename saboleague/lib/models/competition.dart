/// Modèle représentant une compétition de football
/// Contient les informations de base d'une compétition
class Competition {
  /// Identifiant unique de la compétition
  final int id;
  /// Nom de la compétition
  final String name;
  /// Type de compétition (ex: LEAGUE, CUP)
  final String type;
  /// URL du logo de la compétition
  final String logo;
  /// Pays où se déroule la compétition
  final String country;

  /// Constructeur du modèle Competition
  Competition({
    required this.id,
    required this.name,
    required this.type,
    required this.logo,
    required this.country,
  });

  /// Crée une instance de Competition à partir des données JSON de l'API
  /// [json] : Données JSON de la compétition
  factory Competition.fromJson(Map<String, dynamic> json) {
    return Competition(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      logo: json['emblem'] ?? json['logo'] ?? '',
      country: json['area']['name'],
    );
  }
}