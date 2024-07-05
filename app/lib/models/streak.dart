class Streak {
  final String id;
  final DateTime createdAt;
  final String type;

  const Streak({
    required this.id,
    required this.createdAt,
    required this.type,
  });

  factory Streak.fromJSON(Map<String, dynamic> json) {
    return Streak(
      id: json['id'],
      createdAt: DateTime.parse(
        json['createdAt'],
      ),
      type: json['type'],
    );
  }
}
