// ignore: constant_identifier_names
enum QuestionsStatus { not_generated, generated, generating }

class Lesson {
  final String id;
  final String name;
  final String? description;
  final int? questions;
  final QuestionsStatus status;
  Lesson({
    required this.id,
    required this.name,
    required this.description,
    this.questions,
    required this.status,
  });

  factory Lesson.fromJSON(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? null,
      questions: json['questionsCount'] ?? 0,
      status: QuestionsStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['questionsStatus'],
      ),
    );
  }
}
