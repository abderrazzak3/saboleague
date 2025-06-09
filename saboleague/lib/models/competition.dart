class Competition {
  final int id;
  final String name;
  final String type;
  final String logo;
  final String country;

  Competition({
    required this.id,
    required this.name,
    required this.type,
    required this.logo,
    required this.country,
  });

  factory Competition.fromJson(Map<String, dynamic> json) {
    return Competition(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      logo: json['emblem'] ?? json['logo'] ?? '', // Supporte les deux champs possibles
      country: json['area']['name'],
    );
  }
}