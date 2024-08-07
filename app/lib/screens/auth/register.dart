import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/input.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/responses/auth/main.dart';
import 'package:app/screens/auth/login.dart';
import 'package:app/screens/onboarding/questions.dart';
import 'package:app/utils/error.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _passwordVisible = false;
  bool _accepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate() == false) {
      return;
    }
    if (_loading) return;

    if (_accepted == false) {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        description: const Text("Please accept privacy policy."),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    }
    setState(() {
      _loading = true;
    });
    final req = await http.post(
      Uri.parse(
        "$API_URL/auth/sign-up",
      ),
      body: jsonEncode(
        {
          "email": _emailController.text,
          "password": _passwordController.text,
          "name": _nameController.text,
          "timezone": DateTime.now().timeZoneName,
          "timeZoneOffset": DateTime.now().timeZoneOffset.toString(),
        },
      ),
      headers: {
        "Content-Type": "application/json",
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
        title: const Text("An Error Occurred"),
        description: Text(
          ApiResponseHelper.getErrorMessage(body),
        ),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    }
    final response = RegisterResponse.fromJSON(body);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("token", response.token);
    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      autoCloseDuration: const Duration(seconds: 5),
      title: Text("Welcome ${response.user.name.split(" ")[0]}!"),
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
            paths: 0,
            updatedAt: response.user.updatedAt,
            emeralds: response.user.emeralds,
            lives: response.user.lives,
            xp: response.user.xp,
            streaks: response.user.streaks,
            tier: response.user.tier,
            avatarHash: response.user.avatarHash,
            voiceMessages: response.user.voiceMessages,
          ),
        );
    await OneSignal.login(response.user.id);
    logger.i("Logged into onesignal");
    await Purchases.logIn(response.user.id);
    logger.i("Logged into revenue cat");
    Navigator.of(context).pushAndRemoveUntil(
      NoSwipePageRoute(
        builder: (context) => const OnboardingQuestionsScreen(),
      ),
      (Route<dynamic> route) => false,
    );
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
                    "Lets get you started",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(
                    height: BASE_MARGIN.toDouble(),
                  ),
                  Text(
                    "Welcome! Let’s get started on your journey. Please fill in details below to create your account.",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 5,
                  ),
                  Text(
                    "Name",
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 2,
                  ),
                  InputField(
                    hintText: "John Doe",
                    keyboardType: TextInputType.name,
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 6,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CupertinoCheckbox(
                        value: _accepted,
                        onChanged: (value) {
                          setState(
                            () {
                              _accepted = value ?? false;
                            },
                          );
                        },
                      ),
                      const Text("I accept the"),
                      SizedBox(
                        width: BASE_MARGIN.toDouble(),
                      ),
                      TextButton(
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(
                            EdgeInsets.zero,
                          ),
                        ),
                        onPressed: () async {
                          if (!await launchUrl(Uri.parse("https://voicelearn.tech/legal/privacy"))) {}
                        },
                        child: Text(
                          "Privacy Policy",
                          style: TextStyle(
                            color: Colors.blue.shade500,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 6,
                  ),
                  ElevatedButton(
                    onPressed: _signUp,
                    style: ButtonStyle(
                      alignment: Alignment.center,
                      foregroundColor: WidgetStateProperty.all(Colors.black),
                      padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>(
                        (Set<WidgetState> states) {
                          return const EdgeInsets.all(15);
                        },
                      ),
                      backgroundColor: WidgetStateProperty.all(
                        _accepted
                            ? PRIMARY_COLOR
                            : PRIMARY_COLOR.withAlpha(
                                100,
                              ),
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
                            "Sign Up",
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
                              return const LoginScreen();
                            },
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(
                            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                          ),
                          children: [
                            TextSpan(
                              text: "Sign In",
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
