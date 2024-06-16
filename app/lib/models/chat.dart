class Chat {
  final String id;
  final String name;
  final String? initialPrompt;
  final String language;
  final String? flag;
  final String lastMessage;
  final String voice;

  Chat({
    required this.id,
    required this.name,
    this.initialPrompt,
    required this.language,
    required this.lastMessage,
    required this.voice,
    this.flag,
  });

  factory Chat.fromJSON(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      name: json['name'],
      initialPrompt: json['initialPrompt'],
      language: json['language']['name'],
      lastMessage: (json['messages'] != null && json['messages'].isNotEmpty)
          ? (json['messages'][json['messages'].length - 1]['content'] as List).map((e) => e['word']).join(
                " ",
              )
          : '',
      flag: json['language']['flagUrl'],
      voice: json['voice']['name'],
    );
  }
}
