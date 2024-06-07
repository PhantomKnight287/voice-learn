enum AnswerType { correct, incorrect }

class Answer {
  final AnswerType type;
  final String answer;

  const Answer({
    required this.type,
    required this.answer,
  });
  factory Answer.fromJSON(Map<String, dynamic> json) {
    return Answer(
      type: json['type'] == "correct" ? AnswerType.correct : AnswerType.incorrect,
      answer: json['answer'],
    );
  }
}
