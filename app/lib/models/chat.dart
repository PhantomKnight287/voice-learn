class Chat {
  final String id;
  final String name;
  final String? initialPrompt;
  final String language;
  final String? flag;
  final String lastMessage;
  final String voice;
  final String voiceUrl;

  Chat({
    required this.id,
    required this.name,
    this.initialPrompt,
    required this.language,
    required this.lastMessage,
    required this.voice,
    required this.voiceUrl,
    this.flag,
  });

  factory Chat.fromJSON(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      name: json['name'],
      initialPrompt: json['initialPrompt'],
      language: json['language']['name'],
      lastMessage: getLastMessage(json),
      flag: json['language']['flagUrl'],
      voice: json['voice']['name'],
      voiceUrl: json['voice']['previewUrl'],
    );
  }
}

String getLastMessage(Map<String, dynamic> json) {
  if (json['messages'] != null && json['messages'].isNotEmpty) {
    var lastMessage = json['messages'].last;

    if (lastMessage is String) {
      // New format: array of strings
      return lastMessage;
    } else if (lastMessage is Map<String, dynamic> && lastMessage['content'] is List) {
      // Old format: array of objects
      return (lastMessage['content'] as List).map((e) => e is String ? e : (e['word'] ?? '')).join(" ");
    } else {
      // Unexpected format
      return '';
    }
  }
  return '';
}
