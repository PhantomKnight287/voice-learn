class Language {
  final String id;
  final String name;
  final String flagUrl;

  const Language({
    required this.id,
    required this.name,
    required this.flagUrl,
  });

  factory Language.fromJSON(Map<String, dynamic> json) {
    return Language(
      id: json['id'],
      name: json['name'],
      flagUrl: json['flagUrl'],
    );
  }
}
