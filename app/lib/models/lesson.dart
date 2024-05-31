class Lesson {
  final String id;
  final String name;
  final String? description;

  Lesson({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Lesson.fromJSON(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? null,
    );
  }
}
