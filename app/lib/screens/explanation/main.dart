import 'dart:async';
import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/screens/questions/complete.dart';
import 'package:app/screens/questions/main.dart';
import 'package:app/utils/error.dart';
import 'package:app/utils/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as md;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

class ExplanationScreen extends StatefulWidget {
  final String explanation;
  final String title;
  final String id;
  final bool generated;
  final bool completed;
  const ExplanationScreen({
    super.key,
    required this.explanation,
    required this.title,
    required this.id,
    required this.generated,
    required this.completed,
  });

  @override
  State<ExplanationScreen> createState() => _ExplanationScreenState();
}

class _ExplanationScreenState extends State<ExplanationScreen> {
  String message = "Your questions are being generated.";
  Timer? timer;
  bool generated = false;

  void _fetchStatus() async {
    if (widget.generated) return;
    _fetchGenerationStatus(null);
    timer = Timer.periodic(
      const Duration(seconds: 5),
      _fetchGenerationStatus,
    );
  }

  void _fetchGenerationStatus(timer) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token")!;
    final req = await http.get(
      Uri.parse(
        "$API_URL/lessons/${widget.id}",
      ),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode == 200) {
      if (body['generated'] == false) {
        if (body['position'] == null) {
          setState(() {
            message = "Your questions are being generated.";
          });
        } else {
          setState(() {
            message = "You are ${numberToOrdinal(body['position'])} in queue.";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            generated = true;
          });
        }
      }
    } else {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(
          ApiResponseHelper.getErrorMessage(body),
        ),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    setState(() {
      generated = widget.generated;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: BOTTOM(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
            ),
            if (generated == false)
              Text(
                message,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: md.Markdown(
              data: widget.explanation,
              styleSheet: md.MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                ),
              ),
            ),
          ),
          if (generated)
            Padding(
              padding: const EdgeInsets.all(
                BASE_MARGIN * 4,
              ),
              child: ElevatedButton(
                style: ButtonStyle(
                  alignment: Alignment.center,
                  foregroundColor: WidgetStateProperty.all(Colors.black),
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
                onPressed: () async {
                  if (generated == false) {
                    toastification.show(
                      type: ToastificationType.warning,
                      style: ToastificationStyle.minimal,
                      autoCloseDuration: const Duration(seconds: 5),
                      description: const Text(
                        "Questions are not yet generated.",
                      ),
                      alignment: Alignment.topCenter,
                      showProgressBar: false,
                    );
                    return;
                  }
                  if (widget.completed == false) {
                    final userState = context.read<UserBloc>().state;
                    if (userState.lives < 1) {
                      toastification.show(
                        type: ToastificationType.warning,
                        style: ToastificationStyle.minimal,
                        autoCloseDuration: const Duration(seconds: 5),
                        title: const Text("Not enough lives"),
                        description: const Text(
                          "You don't have enough lives.",
                        ),
                        alignment: Alignment.topCenter,
                        showProgressBar: false,
                      );

                      return;
                    }

                    Navigator.of(context).pushReplacement(
                      NoSwipePageRoute(
                        builder: (context) => QuestionsScreen(
                          lessonId: widget.id,
                        ),
                      ),
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      NoSwipePageRoute(
                        builder: (context) {
                          return LessonCompleteScreen(questionId: widget.id, showAd: false);
                        },
                      ),
                    );
                  }
                },
                child: Text(
                  widget.completed ? "View Stats" : "Try the Questions",
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 0.95,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
