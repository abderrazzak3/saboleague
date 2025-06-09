class Team {
  final int id;
  final String name;
  final String shortName;
  final String logo;
  final String country;
  final int founded;
  final String venue;

  Team({
    required this.id,
    required this.name,
    required this.shortName,
    required this.logo,
    required this.country,
    required this.founded,
    required this.venue,
  });

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