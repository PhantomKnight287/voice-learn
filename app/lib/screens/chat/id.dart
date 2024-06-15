import 'dart:convert';

import 'package:app/components/input.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/chat.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => _messages;

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }
}

class ChatMessage {
  final String text;
  final bool isSentByMe;

  ChatMessage({required this.text, required this.isSentByMe});
}

class ChatScreen extends StatefulWidget {
  final String id;
  const ChatScreen({
    super.key,
    required this.id,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isWriting = false;

  Future<Chat> _fetchChat() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final req = await http.get(Uri.parse("$API_URL/chats/${widget.id}"), headers: {
      "Authorization": "Bearer $token",
    });
    final body = jsonDecode(
      req.body,
    );
    return Chat.fromJSON(body);
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isWriting = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QueryBuilder(
      'chat_${widget.id}',
      _fetchChat,
      builder: (context, query) {
        if (query.isLoading) {
          return _buildLoader();
        }
        if (query.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                query.error.toString(),
              ),
            ),
            appBar: AppBar(
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: Container(
                  color: PRIMARY_COLOR,
                  height: 2.0,
                ),
              ),
            ),
          );
        }
        final data = query.data;
        if (data == null) return _buildLoader();
        return Scaffold(
          appBar: AppBar(
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4.0),
              child: Container(
                color: PRIMARY_COLOR,
                height: 2.0,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                  ),
                ),
                Text(
                  data.voice,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: InputField(
                        controller: _controller,
                        hintText: "Message ${data.voice}",
                        keyboardType: TextInputType.text,
                      ),
                    ),
                    const SizedBox(
                      width: BASE_MARGIN * 2,
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isWriting
                          ? Container(
                              key: const ValueKey('send'),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.white),
                                onPressed: () {
                                  if (_controller.text.isNotEmpty) {
                                    _controller.clear();
                                  }
                                },
                              ),
                            )
                          : Container(
                              key: const ValueKey('mic'),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.mic, color: Colors.white),
                                onPressed: () {
                                  // Handle mic button press
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Scaffold _buildLoader() {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: PRIMARY_COLOR,
            height: 2.0,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade400,
              child: Container(
                height: 15,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(
              height: BASE_MARGIN * 2,
            ),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade400,
              child: Container(
                height: 10,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isSentByMe;

  ChatBubble({required this.text, required this.isSentByMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: isSentByMe ? Colors.teal : Colors.grey[300],
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSentByMe ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
