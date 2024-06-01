import 'dart:async';
import 'dart:convert';

import 'package:app/constants/main.dart';
import 'package:app/utils/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class QuestionsGenerationLoadingScreen extends StatefulWidget {
  final String lessonId;
  const QuestionsGenerationLoadingScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<QuestionsGenerationLoadingScreen> createState() => _QuestionsGenerationLoadingScreenState();
}

class _QuestionsGenerationLoadingScreenState extends State<QuestionsGenerationLoadingScreen> {
  String message = "Your questions are being generated.";
  late Timer timer;
  void _fetchStatus() async {
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token")!;
        final req = await http.get(
            Uri.parse(
              "$API_URL/lessons/${widget.lessonId}",
            ),
            headers: {"Authorization": "Bearer $token"});
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
            // Navigator.of(context).pushReplacement(
            //   CupertinoPageRoute(
            //     builder: (context) {
            //       return const HomeScreen();
            //     },
            //   ),
            // );
          }
        }
      },
    );
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
