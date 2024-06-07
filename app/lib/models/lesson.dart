// ignore: constant_identifier_names
enum QuestionsStatus { not_generated, generated, generating }

class Lesson {
  final String id;
  final String name;
  final String? description;
  final int? questions;
  final QuestionsStatus status;
  final bool completed;
  final int correctAnswers;
  final int incorrectAnswers;
  Lesson({
    required this.id,
    required this.name,
    required this.description,
    this.questions,
    required this.status,
    required this.completed,
    required this.correctAnswers,
    required this.incorrectAnswers,
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
      completed: json['completed'],
      correctAnswers: json['correctAnswers'],
      incorrectAnswers: json['incorrectAnswers'],
    );
  }
}
