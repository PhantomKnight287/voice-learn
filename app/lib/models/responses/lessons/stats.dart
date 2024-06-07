import 'package:app/models/question.dart';

class LessonStats {
  final int correctAnswers;
  final int incorrectAnswers;
  final int xpEarned;
  final int emeraldsEarned;
  final String endDate;
  final String startDate;
  // final List<Question> questions;

  const LessonStats({
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.xpEarned,
    required this.emeraldsEarned,
    // required this.questions,
    required this.endDate,
    required this.startDate,
  });

  factory LessonStats.fromJSON(Map<String, dynamic> json) {
    // List<Question> questions = (json['questions'] as List).map((q) => Question.toJSON(q)).toList();
    return LessonStats(
        correctAnswers: json['correctAnswers'],
        incorrectAnswers: json['incorrectAnswers'],
        xpEarned: json['xpEarned'],
        emeraldsEarned: json['emeraldsEarned'],
        endDate: json['endDate'],
        startDate: json['startDate']
        // questions: questions,
        );
  }
}
