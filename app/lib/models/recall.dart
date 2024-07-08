class RecallStack {
  final String name;
  final String id;
  final int notes;

  const RecallStack({
    required this.name,
    required this.id,
    this.notes = 0,
  });

  factory RecallStack.fromJSON(Map<String, dynamic> json) {
    return RecallStack(
      id: json['id'],
      name: json['name'],
      notes: json['_count']?['notes'] ?? 0,
    );
  }
}
