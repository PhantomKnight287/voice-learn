import 'dart:async';
import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/lesson.dart';
import 'package:app/screens/home/main.dart';
import 'package:app/screens/questions/main.dart';
import 'package:app/utils/error.dart';
import 'package:app/utils/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

class QuestionsGenerationLoadingScreen extends StatefulWidget {
  final String lessonId;
  final QuestionsStatus status;
  const QuestionsGenerationLoadingScreen({
    super.key,
    required this.lessonId,
    required this.status,
  });

  @override
  State<QuestionsGenerationLoadingScreen> createState() => _QuestionsGenerationLoadingScreenState();
}

class _QuestionsGenerationLoadingScreenState extends State<QuestionsGenerationLoadingScreen> {
  String message = "Your questions are being generated.";
  late Timer? timer;
  void _fetchStatus() async {
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
        "$API_URL/lessons/${widget.lessonId}",
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
          Navigator.of(context).pushReplacement(
            NoSwipePageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
          return;
        }

        Navigator.of(context).pushReplacement(
          NoSwipePageRoute(
            builder: (context) => QuestionsScreen(
              lessonId: widget.lessonId,
            ),
          ),
        );
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
    _fetchStatus();
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Generating your personalized questions. Please wait...",
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: BASE_MARGIN * 3,
          ),
          Text(
            message,
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SpinKitRipple(
            color: PRIMARY_COLOR,
            size: 100,
          ),
        ],
      ),
    );
  }
}
