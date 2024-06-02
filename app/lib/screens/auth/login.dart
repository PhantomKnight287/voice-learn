import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/input.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/responses/auth/main.dart';
import 'package:app/screens/auth/register.dart';
import 'package:app/screens/home/main.dart';
import 'package:app/utils/error.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
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
        }),
        headers: {"Content-Type": "application/json"});
    final body = jsonDecode(req.body);
    setState(() {
      _loading = false;
    });
    if (req.statusCode != 200) {
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
          ),
        );
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
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
                    keyboardType: TextInputType.name,
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
                  const SizedBox(
                    height: BASE_MARGIN * 6,
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
                            child: const CircularProgressIndicator(
                              color: Colors.black,
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
                          CupertinoPageRoute(
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
                            color: Colors.black,
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
