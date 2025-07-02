/// Modèle représentant une équipe de football
/// Contient toutes les informations d'une équipe et ses méthodes associées
class Team {
  /// Identifiant unique de l'équipe
  final int id;
  /// Nom complet de l'équipe
  final String name;
  /// Nom court de l'équipe
  final String shortName;
  /// URL du logo de l'équipe
  final String logo;
  /// Pays d'origine de l'équipe
  final String country;
  /// Année de création de l'équipe
  final int founded;
  /// Nom du stade de l'équipe
  final String venue;

  /// Constructeur du modèle Team
  Team({
    required this.id,
    required this.name,
    required this.shortName,
    required this.logo,
    required this.country,
    required this.founded,
    required this.venue,
  });

  /// Crée une instance de Team à partir des données JSON de l'API
  /// [json] : Données JSON de l'équipe
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      shortName: json['shortName'] ?? json['name'],
      logo: json['crest'] ?? '',
      country: json['area']?['name'] ?? 'Inconnu',
      founded: json['founded'] ?? 0,
      venue: json['venue'] ?? 'Inconnu',
    );
  }

  /// Crée une instance de Team à partir des données de la base de données
  /// [map] : Données de l'équipe stockées en base
  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'],
      name: map['name'],
      shortName: map['shortName'],
      logo: map['logo'],
      country: map['country'],
      founded: map['founded'],
      venue: map['venue'],
    );
  }

  /// Convertit l'objet Team en Map pour le stockage en base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'logo': logo,
      'country': country,
      'founded': founded,
      'venue': venue,
    };
  }
}