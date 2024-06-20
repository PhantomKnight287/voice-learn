class Streak {
  final String id;
  final DateTime createdAt;

  const Streak({
    required this.id,
    required this.createdAt,
  });

  factory Streak.fromJSON(Map<String, dynamic> json) {
    return Streak(
      id: json['id'],
      createdAt: DateTime.parse(
        json['createdAt'],
      ),
    );
  }
}
