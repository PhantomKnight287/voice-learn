import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/input.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/responses/auth/main.dart';
import 'package:app/screens/auth/register.dart';
import 'package:app/screens/auth/reset_password.dart';
import 'package:app/screens/home/main.dart';
import 'package:app/screens/loading/learning.dart';
import 'package:app/screens/onboarding/questions.dart';
import 'package:app/utils/error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate() == false) {
      return;
    }
    if (_loading) return;
    setState(() {
      _loading = true;
    });

    final req = await http.post(
      Uri.parse(
        "$API_URL/auth/sign-in",
      ),
      body: jsonEncode({
        "email": _emailController.text,
        "password": _passwordController.text,
        "timezone": DateTime.now().timeZoneName,
        "timeZoneOffset": DateTime.now().timeZoneOffset.toString(),
      }),
      headers: {
        "Content-Type": "application/json",
      },
    );
    setState(() {
      _loading = false;
    });
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      final message = ApiResponseHelper.getErrorMessage(body);
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(message),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      logger.e("Failed to login: $message");
      return;
    }
    final response = LoginResponse.fromJSON(body);
    final prefs = await SharedPreferences.getInstance();

    prefs.setString("token", response.token);

    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      autoCloseDuration: const Duration(seconds: 5),
      title: Text("Welcome Back ${response.user.name.split(" ")[0]}!"),
      alignment: Alignment.topCenter,
      showProgressBar: false,
    );
    context.read<UserBloc>().add(
          UserLoggedInEvent(
            id: response.user.id,
            name: response.user.name,
            token: response.token,
            email: response.user.email,
            createdAt: response.user.createdAt,
            paths: response.user.paths,
            updatedAt: response.user.updatedAt,
            emeralds: response.user.emeralds,
            lives: response.user.lives,
            xp: response.user.xp,
            streaks: response.user.streaks,
            isStreakActive: response.user.isStreakActive,
            tier: response.user.tier,
            avatarHash: response.user.avatarHash,
          ),
        );
    logger.d("Login Successful. User Id:${response.user.id}. Email:${response.user.email}");
    await OneSignal.login(response.user.id);
    logger.d("Logged into OneSignal");

    if (body['path']?['type'] == 'created') {
      Navigator.of(context).pushReplacement(
        NoSwipePageRoute(
          builder: (context) => LearningPathLoadingScreen(pathId: body['path']['id']),
        ),
      );
      return;
    } else if (body['path'] == null) {
      Navigator.of(context).pushReplacement(
        NoSwipePageRoute(
          builder: (context) => const OnboardingQuestionsScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        NoSwipePageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(
              BASE_MARGIN * 4,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(
                    height: BASE_MARGIN * 2,
                  ),
                  Text(
                    "Lets sign you in",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(
                    height: BASE_MARGIN.toDouble(),
                  ),
                  Text(
                    "Welcome back! We're glad to see you again. Please enter your details to sign in.",
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 6,
                  ),
                  Text(
                    "Password",
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 2,
                  ),
                  InputField(
                    hintText: "*******",
                    keyboardType: TextInputType.visiblePassword,
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        height: BASE_MARGIN * 6,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            NoSwipePageRoute(
                              builder: (context) {
                                return const ResetPasswordScreen();
                              },
                            ),
                          );
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Colors.blue.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _login,
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
                            "Sign In",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  Align(
                    alignment: FractionalOffset.bottomCenter,
                    child: TextButton(
                      style: const ButtonStyle(
                        splashFactory: NoSplash.splashFactory,
                      ),
                      onPressed: () {
                        if (_loading) return;
                        Navigator.of(context).pushReplacement(
                          NoSwipePageRoute(
                            builder: (context) {
                              return const RegisterScreen();
                            },
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                          ),
                          children: [
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
                                color: Colors.blue.shade500,
                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
