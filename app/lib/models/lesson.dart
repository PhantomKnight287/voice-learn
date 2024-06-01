class Lesson {
  final String id;
  final String name;
  final String? description;
  final int? questions;
  Lesson({
    required this.id,
    required this.name,
    required this.description,
    this.questions,
  });

  factory Lesson.fromJSON(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? null,
      questions: json['questionsCount'] ?? 0,
    );
  }
}
