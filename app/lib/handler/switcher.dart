import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/screens/auth/login.dart';
import 'package:app/screens/home/main.dart';
import 'package:app/screens/onboarding/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewHandler extends StatefulWidget {
  const ViewHandler({super.key});

  @override
  State<ViewHandler> createState() => _ViewHandlerState();
}

class _ViewHandlerState extends State<ViewHandler> {
  bool showOnBoarding = true;
  void checkOnBoardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token != null && token.isNotEmpty) {
      setState(() {
        showOnBoarding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (showOnBoarding) return const OnboardingScreen();
    return const Placeholder();
  }
}
