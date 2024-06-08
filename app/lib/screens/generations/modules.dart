import 'dart:convert';

import 'package:app/components/input.dart';
import 'package:app/constants/main.dart';
import 'package:app/utils/error.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

class GenerationsScreen extends StatefulWidget {
  const GenerationsScreen({super.key});

  @override
  State<GenerationsScreen> createState() => _GenerationsScreenState();
}

class _GenerationsScreenState extends State<GenerationsScreen> {
  bool _loading = false;

  final _promptController = TextEditingController();

  Future<void> _createGenerationRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    setState(() {
      _loading = true;
    });
    final req = await http.post(
        Uri.parse(
          "$API_URL/generations",
        ),
        body: jsonEncode({
          "prompt": _promptController.text,
        }),
        headers: {"Authorization": "Bearer $token"});
    final body = jsonDecode(req.body);
    setState(() {
      _loading = false;
    });
    if (req.statusCode == 201) {
      toastification.show(
        type: ToastificationType.success,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        description: const Text("Your modules will be generated shortly."),
        title: Text(body['existing'] ? "Modules already generating." : "Generation added to queue"),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      Navigator.pop(context);
      return;
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
      Navigator.pop(context);

      return;
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Generate More Modules",
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(
          BASE_MARGIN * 4,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Prompt",
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
              ),
            ),
            const SizedBox(
              height: BASE_MARGIN * 2,
            ),
            InputField(
              hintText: "Tell AI if you want to generate modules on specific topic(optional).",
              keyboardType: TextInputType.text,
              controller: _promptController,
              maxLines: 5,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _createGenerationRequest,
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
                      "Generate",
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
