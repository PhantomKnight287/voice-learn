class Note {
  final String id;
  final String title;
  final String description;

  const Note({
    required this.id,
    required this.title,
    required this.description,
  });
  factory Note.fromJSON(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      description: json['description'],
    );
  }
}
