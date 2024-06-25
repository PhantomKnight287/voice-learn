import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/input.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/chat.dart';
import 'package:app/models/message.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:app/utils/string.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:toastification/toastification.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:http_parser/http_parser.dart';

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
  final record = RecorderController()
    ..androidEncoder = AndroidEncoder.aac
    ..androidOutputFormat = AndroidOutputFormat.mpeg4
    ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
    ..sampleRate = 16000;

  final playerController = PlayerController();
  bool _loading = false;
  final chatKey = GlobalKey();

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
    final id = widget.id;
    socket = IO.io(
      removeVersionAndTrailingSlash(API_URL),
      IO.OptionBuilder()
          .setTransports(['websocket']) // for Flutter or Dart VM
          .enableAutoConnect()
          .setQuery({'chatId': widget.id, "id": id})
          .setAuth({
            "token": token,
            "id": widget.id,
          })
          .build(),
    );
    socket!.connect();
    socket!.onConnect(
      (data) {
        _setupTutorial();
      },
    );
    socket!.on(
      "message",
      (data) async {
        await Future.delayed(
          const Duration(seconds: 10),
        );
        if (data['refId'] == lastMessageId) {
          if (context.mounted) {
            // ignore: no_leading_underscores_for_local_identifiers
            final _messages = messages;
            _messages[_messages.length - 1] = Message.fromJSON(data);

            setState(() {
              lastMessageId = '';
              disabled = true;
              eolReceived = false;
              lastMessageReceivedId = data['id'];
              messages = _messages;
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
        QueryClient.of(context).refreshInfiniteQuery("chats");
        _scrollToBottom();
      }
    });
    socket!.on("user_update", (data) {
      final userBloc = context.read<UserBloc>();
      final userState = userBloc.state;
      userBloc.add(
        UserLoggedInEvent.setEmeraldsAndLives(
          userState,
          data['emeralds'],
          data['lives'],
        ),
      );
    });
    socket!.on("error", (data) {
      if ((data as String).contains("emeralds")) {
        setState(() {
          lastMessageId = '';
          disabled = false;
          eolReceived = true;
          botResponse = '';
          lastMessageReceivedId = "";
        });
      } else if ((data as String).startsWith("This chat is using a premium voice.")) {
        setState(() {
          if (messages.isNotEmpty) {
            messages.removeLast();
          }
        });
      }
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        description: Text(data),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
    });
  }

  Future<void> _setupTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool("chat_tutorial");
    if (shown == null || !shown) {
      TutorialCoachMark tutorial = TutorialCoachMark(
        colorShadow: Colors.white,
        textSkip: "SKIP",
        alignSkip: Alignment.bottomCenter,
        textStyleSkip: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
        paddingFocus: 10,
        opacityShadow: 0.5,
        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        targets: [
          TargetFocus(
            keyTarget: chatKey,
            identify: "streaks",
            alignSkip: Alignment.topRight,
            enableOverlayTab: true,
            shape: ShapeLightFocus.RRect,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (context, controller) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Send a message",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                        ),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 2,
                      ),
                      Text(
                        "Send a message by typing it in input box and pressing this button. Hold this button to record an audio and release to get a preview(minimum duration should be 1s)",
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                        ),
                      )
                    ],
                  );
                },
              ),
            ],
          ),
        ],
        onFinish: () async {
          final prefs = await SharedPreferences.getInstance();
          prefs.setBool("chat_tutorial", true);
        },
        onSkip: () {
          SharedPreferences.getInstance().then(
            (value) {
              value.setBool("chat_tutorial", true);
            },
          );
          return true;
        },
      );
      tutorial.show(context: context);
    }
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
    Map<Permission, PermissionStatus> permissions = await [
      Permission.microphone,
    ].request();

    bool granted = permissions[Permission.microphone]!.isGranted;

    if (granted) {
      final directory = (await getApplicationDocumentsDirectory()).path;
      String recording = '$directory/recordings';
      Directory appFolder = Directory(recording);
      bool appFolderExists = await appFolder.exists();
      if (!appFolderExists) {
        await appFolder.create(recursive: true);
      }

      final filepath = '$recording/${DateTime.now().millisecondsSinceEpoch}.mp3';

      await record.record(
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
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("Permission Denied"),
        description: const Text("Please allow microphone and storage permission."),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
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
      await playerController.preparePlayer(path: filePath).then(
            (value) {},
          );
    } else {
      setState(() {
        _recordingDuration = 0;
        filePath = "";
        _isPreview = false;
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
    super.dispose();
    socket?.disconnect();
    socket?.dispose();
    timer?.cancel();
    _recordingTimer?.cancel();
    _controller.dispose();
    playerController.dispose();
    record.dispose();
    WidgetsBinding.instance.removeObserver(this);
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
              bottom: BOTTOM,
            ),
          );
        }
        final data = query.data;
        if (data == null) return _buildLoader();
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            forceMaterialTransparency: true,
            bottom: BOTTOM,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                    fontWeight: Theme.of(context).textTheme.titleMedium!.fontWeight,
                    fontFamily: "CalSans",
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
                        audioUrl: message.audioUrl,
                        audioDuration: message.audioDuration,
                        audioId: message.audioId,
                        chatId: widget.id,
                      );

                      return bubble;
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
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AudioWaveforms(
                                  recorderController: record,
                                  size: Size(MediaQuery.of(context).size.width / 2, 50),
                                  waveStyle: const WaveStyle(
                                    waveColor: Colors.white,
                                    extendWaveform: true,
                                    showMiddleLine: false,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    color: const Color(0xFF1E1B26),
                                  ),
                                  padding: const EdgeInsets.only(left: 18),
                                  margin: const EdgeInsets.symmetric(horizontal: 15),
                                ),
                                Text('${_recordingDuration}s/10s'),
                              ],
                            )
                          : _isPreview
                              ? Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      onPressed: () async {
                                        if (filePath.isNotEmpty) {
                                          await playerController.startPlayer(
                                            finishMode: FinishMode.pause,
                                          );
                                          playerController.onCompletion.listen(
                                            (event) async {
                                              await playerController.seekTo(0);
                                            },
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      color: Colors.red,
                                      onPressed: () async {
                                        setState(() {
                                          _loading = false;
                                          disabled = false;
                                          lastMessageId = "";
                                          botResponse = "";
                                          eolReceived = false;
                                          _recordingDuration = 0;
                                          filePath = "";
                                          _isPreview = false;
                                          _isRecording = false;
                                        });
                                      },
                                    ),
                                    AudioFileWaveforms(
                                      size: Size(
                                        MediaQuery.of(context).size.width / 2,
                                        50,
                                      ),
                                      playerController: playerController,
                                      waveformType: WaveformType.long,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12.0),
                                        color: const Color(0xFF1E1B26),
                                      ),
                                      // padding: const EdgeInsets.only(left: 18),
                                      animationCurve: Curves.linear,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      enableSeekGesture: true,
                                      playerWaveStyle: const PlayerWaveStyle(
                                        showSeekLine: true,
                                        showBottom: true,
                                        showTop: true,
                                      ),
                                      continuousWaveform: true,
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
                      key: chatKey,
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
                                    messages.add(
                                      Message(
                                        author: MessageAuthor.User,
                                        content: _controller.text.split(" ").map((e) => {"word": e}).toList(),
                                        createdAt: DateTime.now().toIso8601String(),
                                        id: refId,
                                      ),
                                    );
                                    _controller.clear();
                                    _scrollToBottom();
                                  }
                                },
                              ),
                            )
                          : GestureDetector(
                              key: const ValueKey('mic'),
                              onTap: () async {
                                if (!_isPreview || filePath.isEmpty || _loading || disabled) return;
                                setState(() {
                                  disabled = true;
                                  _loading = true;
                                });
                                final prefs = await SharedPreferences.getInstance();
                                final token = prefs.getString("token");
                                final prepare = http.MultipartRequest(
                                  "POST",
                                  Uri.parse(
                                    "$API_URL/uploads",
                                  ),
                                );
                                prepare.files.add(
                                  await http.MultipartFile.fromPath(
                                    "file",
                                    filePath,
                                    contentType: MediaType.parse("audio/mp3"),
                                  ),
                                );
                                prepare.headers.addAll(
                                  {
                                    "Authorization": "Bearer $token",
                                  },
                                );

                                final req = await prepare.send();
                                final res = await http.Response.fromStream(req);
                                final body = jsonDecode(res.body);
                                final refId = uuid.v4();

                                socket?.emit("message", {
                                  "attachmentId": body['id'],
                                  "refId": refId,
                                  "audioDuration": _recordingDuration,
                                });
                                messages.add(Message(
                                  author: MessageAuthor.User,
                                  content: [],
                                  createdAt: DateTime.now().toIso8601String(),
                                  id: refId,
                                  audioUrl: filePath,
                                  audioDuration: _recordingDuration,
                                ));
                                setState(() {
                                  _loading = false;
                                  disabled = false;
                                  lastMessageId = refId;
                                  botResponse = "";
                                  eolReceived = false;
                                  _recordingDuration = 0;
                                  filePath = "";
                                  _isPreview = false;
                                  _isRecording = false;
                                });
                                _controller.clear();

                                _scrollToBottom();
                              },
                              onLongPressStart: (_) {
                                if (_loading || disabled) return;
                                _startRecording();
                              },
                              onLongPressEnd: (_) {
                                if (_loading || disabled) return;
                                _stopRecording();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: disabled == false ? Colors.blue : Colors.blue.shade200,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(
                                  BASE_MARGIN * 3,
                                ),
                                child: _loading == false
                                    ? Icon(
                                        _isPreview ? Icons.send : Icons.mic,
                                        color: Colors.white,
                                      )
                                    : const CupertinoActivityIndicator(
                                        animating: true,
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
        bottom: BOTTOM,
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

class ChatBubble extends StatefulWidget {
  final dynamic text;
  final bool isSentByMe;
  final bool? sent;
  final String? audioUrl;
  final int? audioDuration;
  final String? audioId;
  final String chatId;
  const ChatBubble({
    super.key,
    required this.text,
    required this.isSentByMe,
    required this.chatId,
    this.sent,
    this.audioUrl,
    this.audioDuration,
    this.audioId,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  final controller = AudioPlayer();
  int duration = 0;
  Timer? timer;
  bool playing = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<UserBloc>().state;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Align(
        alignment: widget.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: widget.isSentByMe ? PRIMARY_COLOR : Colors.grey[300],
            borderRadius: widget.isSentByMe
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.text != null) ...{
                    Wrap(
                      children: [
                        for (var word in widget.text!) ...{
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
                    )
                  },
                  if (widget.audioUrl != null || widget.audioId != null) ...{
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: HeroIcon(
                            playing == true ? HeroIcons.pauseCircle : HeroIcons.playCircle,
                            style: HeroIconStyle.solid,
                            size: 30,
                          ),
                          onPressed: () async {
                            if (playing) {
                              await controller.pause();
                              setState(() {
                                playing = false;
                              });
                              timer?.cancel();
                              return;
                            }
                            setState(() {
                              duration = 0;
                            });

                            await controller.play(
                              widget.audioId != null
                                  ? UrlSource(
                                      "$API_URL/uploads/${widget.audioId}?token=${state.token}&chatId=${widget.chatId}",
                                    )
                                  : widget.audioUrl!.startsWith("https")
                                      ? UrlSource(widget.audioId!)
                                      : DeviceFileSource(widget.audioUrl!),
                            );
                            setState(() {
                              playing = true;
                            });
                            timer = Timer.periodic(
                              const Duration(
                                seconds: 1,
                              ),
                              (timer) {
                                setState(() {
                                  duration++;
                                });
                              },
                            );
                            controller.onPlayerComplete.listen(
                              (event) async {
                                setState(() {
                                  playing = false;
                                });
                                timer?.cancel();
                              },
                            );
                          },
                        ),
                        const SizedBox(
                          width: BASE_MARGIN * 2,
                        ),
                        Text("${secInTime(duration)}/${secInTime(widget.audioDuration ?? 0)}")
                      ],
                    )
                  }
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
