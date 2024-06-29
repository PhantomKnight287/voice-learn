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
  final int xpPerQuestion;
  final int emeralds;
  final String? explanation;

  Lesson({
    required this.id,
    required this.name,
    required this.description,
    this.questions,
    required this.status,
    required this.completed,
    required this.correctAnswers,
    required this.incorrectAnswers,
    this.xpPerQuestion = 4,
    this.emeralds = 1,
    this.explanation,
  });

  factory Lesson.fromJSON(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      questions: json['questionsCount'] ?? 0,
      status: QuestionsStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['questionsStatus'],
      ),
      completed: json['completed'],
      correctAnswers: json['correctAnswers'],
      incorrectAnswers: json['incorrectAnswers'],
      xpPerQuestion: json['xpPerQuestion'],
      emeralds: json['emeralds'],
      explanation: json['explanation'],
    );
  }
}
