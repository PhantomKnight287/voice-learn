// ignore_for_file: constant_identifier_names

import 'package:app/models/answer.dart';

enum QuestionType {
  select_one,
  sentence,
  fill_in_the_blank,
}

class QuestionQuestion {
  final String word;
  final String translation;
  const QuestionQuestion({
    required this.word,
    required this.translation,
  });
  factory QuestionQuestion.toJSON(Map<String, dynamic> json) {
    return QuestionQuestion(
      word: json['word'],
      translation: json['translation'],
    );
  }
}

class Question {
  final String id;
  final String? lessonId;
  final String instruction;
  final String correctAnswer;
  final String? createdAt;
  final List<QuestionQuestion> question;
  final QuestionType type;
  final List<String> options;
  final Answer? answer;

  const Question({
    required this.id,
    this.lessonId,
    required this.instruction,
    required this.correctAnswer,
    this.createdAt,
    required this.question,
    required this.type,
    required this.options,
    this.answer,
  });

  factory Question.toJSON(Map<String, dynamic> json) {
    List<QuestionQuestion> questionArray = (json['question'] as List).map((q) => QuestionQuestion.toJSON(q)).toList();
    Answer? answer = (json['answers'] != null && json['answers'].length > 0) ? Answer.fromJSON(json['answers'][0]) : null;

    return Question(
      id: json['id'],
      instruction: json['instruction'],
      correctAnswer: json['correctAnswer'],
      question: questionArray,
      createdAt: json['createdAt'],
      lessonId: json['lessonId'],
      type: json['type'] == "select_one"
          ? QuestionType.select_one
          : json['type'] == 'sentence'
              ? QuestionType.sentence
              : QuestionType.fill_in_the_blank,
      options: (json['options'] as List).map((item) => item as String).toList(),
      answer: answer,
    );
  }
}
