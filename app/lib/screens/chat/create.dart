import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/components/input.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/language.dart';
import 'package:app/models/voice.dart';
import 'package:app/screens/chat/id.dart';
import 'package:app/screens/languages/main.dart';
import 'package:app/screens/voices/main.dart';
import 'package:app/utils/error.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final _titleController = TextEditingController();
  final _promptController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Voice? voice;
  Language? language;
  bool _loading = false;

  void _createChat() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_loading) return;
    if (voice == null) {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("Please select a voice"),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    }
    if (language == null) {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("Please select a language"),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    }
    setState(() {
      _loading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final req = await http.post(
      Uri.parse("$API_URL/chats"),
      body: jsonEncode(
        {
          "name": _titleController.text,
          "initialPrompt": _promptController.text,
          "languageId": language!.id,
          "voiceId": voice!.id,
        },
      ),
      headers: {
        "authorization": "Bearer $token",
        "content-type": "application/json",
      },
    );
    final body = jsonDecode(req.body);
    setState(() {
      _loading = false;
    });
    if (req.statusCode != 201) {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An error occured"),
        description: Text(
          ApiResponseHelper.getErrorMessage(body),
        ),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    } else {
      QueryClient.of(context).refreshQuery('chats');
      Navigator.of(context).pushReplacement(
        NoSwipePageRoute(
          builder: (context) {
            return ChatScreen(id: body['id']);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BASE_MARGIN * 3,
              vertical: BASE_MARGIN * 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Create new chat",
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleLarge!.fontSize! * 0.85,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: BASE_MARGIN * 1,
                ),
                Text(
                  "Create new chat to practice your ${language == null ? "language" : language!.name} skills.",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(
                  height: BASE_MARGIN * 5,
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Title",
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 2,
                      ),
                      InputField(
                        hintText: "In a mall",
                        keyboardType: TextInputType.text,
                        controller: _titleController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter title of your chat.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 6,
                      ),
                      Text(
                        "Voice",
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 2,
                      ),
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            NoSwipePageRoute(
                              builder: (context) {
                                return const VoicesScreen();
                              },
                            ),
                          );
                          if (!context.mounted) return;

                          setState(() {
                            voice = result;
                          });
                        },
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Color(0xffe7e0e8) : Color(0xff36343a),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              voice == null ? "Select a voice" : voice!.name,
                              style: TextStyle(
                                color: voice == null
                                    ? Theme.of(context).hintColor
                                    : AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light
                                        ? Colors.black
                                        : Colors.white,
                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 6,
                      ),
                      Text(
                        "Language",
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 2,
                      ),
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            NoSwipePageRoute(
                              builder: (context) {
                                return const LanguagesScreen();
                              },
                            ),
                          );
                          if (!context.mounted) return;

                          setState(() {
                            language = result;
                          });
                        },
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? const Color(0xffe7e0e8) : const Color(0xff36343a),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                if (language != null) ...{
                                  CachedNetworkImage(
                                    imageUrl: language!.flagUrl,
                                    width: 35,
                                    height: 35,
                                  ),
                                  const SizedBox(
                                    width: BASE_MARGIN * 1,
                                  )
                                },
                                Text(
                                  language == null ? "Select a language" : language!.name,
                                  style: TextStyle(
                                    color: language == null
                                        ? Theme.of(context).hintColor
                                        : AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light
                                            ? Colors.black
                                            : Colors.white,
                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 6,
                      ),
                      Text(
                        "Scenario",
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 2,
                      ),
                      InputField(
                        hintMaxLines: 3,
                        hintText: "Tell how the AI should act and what is the scenario. Example: You are a cashier at a mall...",
                        keyboardType: TextInputType.text,
                        minLines: 5,
                        controller: _promptController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: BASE_MARGIN * 5,
                ),
                ElevatedButton(
                  onPressed: _createChat,
                  style: ButtonStyle(
                    alignment: Alignment.center,
                    foregroundColor: WidgetStateProperty.all(
                      Colors.black,
                    ),
                    padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>(
                      (Set<WidgetState> states) {
                        return const EdgeInsets.all(15);
                      },
                    ),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  child: _loading
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          "Create",
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(
                  height: BASE_MARGIN * 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
