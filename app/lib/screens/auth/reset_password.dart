import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/components/input.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/utils/error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gravatar/utils.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  Future<void> _resetPassword() async {
    if (_loading) return;
    if (_emailController.text.isEmpty) return;
    if (!_emailController.text.isValidEmail()) {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("Invalid email"),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    }
    setState(() {
      _loading = true;
    });
    final url = Uri.parse("$API_URL/auth/forgot-password/email");
    logger.d("Requesting ${url.toString()}");
    final req = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(
        {
          "email": _emailController.text,
        },
      ),
    );
    setState(() {
      _loading = false;
    });
    final body = jsonDecode(req.body);
    if (req.statusCode != 201) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to send reset email: $message");
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(message),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    }
    logger.d("Password Reset Email Requested");
    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      autoCloseDuration: const Duration(seconds: 5),
      title: const Text("Email Sent"),
      description: const Text("Check your email and spam box."),
      alignment: Alignment.topCenter,
      showProgressBar: false,
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 0,
              bottom: BASE_MARGIN * 4,
              left: BASE_MARGIN * 4,
              right: BASE_MARGIN * 4,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Reset Password",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(
                  height: BASE_MARGIN.toDouble(),
                ),
                Text(
                  "Need a fresh start? Let's get you a new password in no time!",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(
                  height: BASE_MARGIN * 5,
                ),
                Text(
                  "Email",
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: BASE_MARGIN * 2,
                ),
                InputField(
                  hintText: "johndoe@gmail.com",
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                ),
                const SizedBox(
                  height: BASE_MARGIN * 6,
                ),
                ElevatedButton(
                  onPressed: _resetPassword,
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
                          child: CircularProgressIndicator(
                            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          "Reset",
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
