// ignore_for_file: constant_identifier_names

enum MessageAuthor {
  Bot,
  User,
}

class Message {
  final String id;
  final dynamic content;
  final MessageAuthor author;
  final String? audioUrl;
  final String createdAt;
  final String? refId;
  final int? audioDuration;
  final String? audioId;

  const Message({
    required this.id,
    this.audioUrl,
    required this.author,
    required this.content,
    required this.createdAt,
    this.refId,
    this.audioDuration,
    this.audioId,
  });

  factory Message.fromJSON(Map<String, dynamic> json) {
    return Message(
      author: MessageAuthor.values.firstWhere(
        (e) => e.toString().split('.').last == json['author'],
      ),
      content: json['content'],
      createdAt: json['createdAt'],
      id: json['id'],
      audioUrl: json['attachment']?['url'],
      audioDuration: json['audioDuration'],
      audioId: json['attachment']?['id'],
    );
  }
}
