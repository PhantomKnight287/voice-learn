import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/components/input.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/chat.dart';
import 'package:app/models/message.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:app/utils/string.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:toastification/toastification.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

class ChatScreen extends StatefulWidget {
  final String id;
  const ChatScreen({
    super.key,
    required this.id,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isWriting = false;
  late IO.Socket? socket;
  final record = AudioRecorder();
  String? lastMessageId;
  List<Message> messages = [];
  bool disabled = false;
  bool eolReceived = true;
  String botResponse = "";
  final uuid = const Uuid();
  String queueMessage = "";
  Timer? timer;
  String? lastMessageReceivedId;
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  bool _isPreview = false;
  final audio = AudioPlayer();
  String filePath = "";

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (mounted) {
      if (View.of(context).viewInsets.bottom > 0.0) {
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  Future<Chat> _fetchChat() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final req = await http.get(Uri.parse("$API_URL/chats/${widget.id}"), headers: {
      "Authorization": "Bearer $token",
    });
    final body = jsonDecode(
      req.body,
    );
    final messages = (body['messages'] as List).map((e) => Message.fromJSON(e)).toList();
    if (context.mounted) {
      setState(() {
        this.messages = messages.reversed.toList();
      });
      _scrollToBottom();
    }
    return Chat.fromJSON(body);
  }

  Future<void> _initSocket() async {
    final storage = await SharedPreferences.getInstance();
    final token = storage.getString("token");

    socket = IO.io(
      removeVersionAndTrailingSlash(API_URL),
      IO.OptionBuilder()
          .setTransports(['websocket']) // for Flutter or Dart VM
          .enableAutoConnect()
          .setQuery({
            'chatId': widget.id,
          })
          .setAuth({"token": token})
          .build(),
    );
    socket!.connect();
    socket!.onConnect((data) => {print("connected")});
    socket!.on(
      "message",
      (data) async {
        await Future.delayed(
          const Duration(seconds: 10),
        );
        if (data['refId'] == lastMessageId) {
          if (context.mounted) {
            setState(() {
              lastMessageId = '';
              disabled = true;
              eolReceived = false;
              lastMessageReceivedId = data['id'];
            });
          }
        }
        timer = Timer.periodic(
          const Duration(seconds: 5),
          (timer) {
            socket?.emit("queue");
          },
        );
      },
    );
    socket!.on("queue", (data) async {
      setState(() {
        queueMessage = data == -1 ? " • Typing..." : " • You are ${numberToOrdinal(data)} in queue.";
        eolReceived = false;
      });
    });
    socket!.on("response_end", (data) async {
      if (context.mounted) {
        setState(() {
          lastMessageId = '';
          disabled = false;
          eolReceived = true;
          botResponse = '';
          lastMessageReceivedId = "";
        });
        timer?.cancel();
        messages.add(
          Message.fromJSON(
            data,
          ),
        );
        _scrollToBottom();
      }
    });
    socket!.on("error", (data) {
      print("err $data");
    });
  }

  void _fetchOlderMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final req = await http.get(Uri.parse("$API_URL/chats/${widget.id}/messages?id=${this.messages.first.id}"), headers: {
      "Authorization": "Bearer $token",
    });
    final body = jsonDecode(
      req.body,
    );
    final messages = (body as List).map((e) => Message.fromJSON(e)).toList();
    if (context.mounted) {
      this.messages.insertAll(0, messages);
      setState(() {});
    }
  }

  void _startRecording() async {
    print('recording started');
    Map<Permission, PermissionStatus> permissions = await [
      Permission.storage,
      Permission.microphone,
    ].request();

    bool granted = permissions[Permission.storage]!.isGranted && permissions[Permission.microphone]!.isGranted;

    if (granted) {
      final directory = (await getApplicationDocumentsDirectory()).path;
      String recording = '$directory/recordings';
      Directory appFolder = Directory(recording);
      bool appFolderExists = await appFolder.exists();
      if (!appFolderExists) {
        await appFolder.create(recursive: true);
      }

      final filepath = '$recording/${DateTime.now().millisecondsSinceEpoch}.mp3';

      const config = RecordConfig();

      await record.start(
        config,
        path: filepath,
      );

      setState(() {
        _isRecording = true;
        filePath = filepath;
        _recordingDuration = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration += 1;
        });
        if (_recordingDuration >= 10) {
          _stopRecording();
        }
      });
    } else {
      // Handle permission denied
    }
  }

  void _stopRecording() async {
    _recordingTimer?.cancel();
    final str = await record.stop();

    if (str != null && _recordingDuration >= 2) {
      setState(() {
        _isRecording = false;
        _isPreview = true;
      });
    } else {
      setState(() {
        _isRecording = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSocket();
    _controller.addListener(() {
      setState(() {
        _isWriting = _controller.text.isNotEmpty;
      });
    });
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge) {
        bool isTop = _scrollController.position.pixels == 0;
        if (isTop) {
          _fetchOlderMessages();
        }
      }
    });
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    timer?.cancel();
    _recordingTimer?.cancel();
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QueryBuilder(
      'chat_${widget.id}',
      _fetchChat,
      refreshConfig: RefreshConfig.withDefaults(
        context,
        staleDuration: const Duration(
          seconds: 0,
        ),
      ),
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
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            forceMaterialTransparency: true,
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
                Row(
                  children: [
                    Text(
                      data.voice,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (eolReceived == false && queueMessage.isNotEmpty)
                      Text(
                        queueMessage,
                        style: Theme.of(context).textTheme.titleSmall,
                      )
                  ],
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.separated(
                    controller: _scrollController,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final bubble = ChatBubble(
                        text: message.content,
                        isSentByMe: message.author == MessageAuthor.User,
                        sent: message.id == lastMessageId ? false : true,
                      );
                      if (index != messages.length - 1) {
                        return bubble;
                      } else {
                        if (eolReceived == true) {
                          return bubble;
                        } else if (botResponse.isEmpty) {
                          return bubble;
                        } else {
                          return Column(
                            children: [
                              bubble,
                              const SizedBox(
                                height: BASE_MARGIN * 2,
                              ),
                              ChatBubble(
                                text: botResponse,
                                isSentByMe: false,
                                sent: true,
                              ),
                            ],
                          );
                        }
                      }
                    },
                    separatorBuilder: (context, index) {
                      return const SizedBox(
                        height: BASE_MARGIN * 0,
                      );
                    },
                    itemCount: messages.length),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _isRecording
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Replace with your waveform widget
                                // YourWaveformWidget(filepath: _recordingPath),
                                Text('Recording... ${_recordingDuration}s'),
                              ],
                            )
                          : _isPreview
                              ? Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      onPressed: () async {
                                        print(filePath);
                                        if (filePath.isNotEmpty) {
                                          await audio.play(
                                            DeviceFileSource(filePath),
                                            volume: 1,
                                          );
                                          audio.onPlayerComplete.listen(
                                            (event) {
                                              print("played");
                                            },
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.send),
                                      onPressed: () {},
                                    ),
                                  ],
                                )
                              : InputField(
                                  controller: _controller,
                                  hintText: "Send a message",
                                  keyboardType: TextInputType.text,
                                  enabled: !disabled,
                                  maxLines: 5,
                                  minLines: 1,
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
                              decoration: BoxDecoration(
                                color: disabled == false ? Colors.blue : Colors.blue.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.white),
                                onPressed: () {
                                  if (disabled == true) return;
                                  if (_controller.text.isNotEmpty) {
                                    final refId = uuid.v4();
                                    setState(() {
                                      disabled = true;
                                      lastMessageId = refId;
                                      botResponse = "";
                                      eolReceived = false;
                                    });
                                    socket?.emit("message", {
                                      "message": _controller.text,
                                      "refId": refId,
                                    });
                                    messages.add(Message(
                                      author: MessageAuthor.User,
                                      content: _controller.text.split(" ").map((e) => {"word": e}).toList(),
                                      createdAt: DateTime.now().toIso8601String(),
                                      id: refId,
                                    ));
                                    _controller.clear();
                                    _scrollToBottom();
                                  }
                                },
                              ),
                            )
                          : GestureDetector(
                              key: const ValueKey('mic'),
                              onLongPressStart: (_) => _startRecording(),
                              onLongPressEnd: (_) => _stopRecording(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: disabled == false ? Colors.blue : Colors.blue.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    _isPreview ? Icons.send : Icons.mic,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {}, // Disable onPressed to use onLongPress instead
                                ),
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
  final dynamic text;
  final bool isSentByMe;
  final bool? sent;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isSentByMe,
    this.sent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: isSentByMe ? PRIMARY_COLOR : Colors.grey[300],
            borderRadius: isSentByMe
                ? const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(0),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(10),
                  ),
          ),
          child: Wrap(
            children: [
              Wrap(
                alignment: WrapAlignment.start,
                children: [
                  for (var word in text) ...{
                    if (word != null)
                      word['translation'] != null
                          ? Tooltip(
                              message: word['translation'],
                              triggerMode: TooltipTriggerMode.tap,
                              child: Text(
                                word['word'],
                                style: const TextStyle(
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dashed,
                                ),
                              ),
                            )
                          : Text(
                              word['word'],
                            ),
                    SizedBox(
                      width: BASE_MARGIN.toDouble(),
                    ),
                  },
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
