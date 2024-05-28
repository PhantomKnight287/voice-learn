import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/home/main.dart';
import 'package:app/screens/onboarding/main.dart';
import 'package:app/screens/onboarding/questions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ViewHandler extends StatefulWidget {
  const ViewHandler({super.key});

  @override
  State<ViewHandler> createState() => _ViewHandlerState();
}

class _ViewHandlerState extends State<ViewHandler> {
  bool _showOnBoarding = false;
  void _checkOnBoardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token != null && token.isNotEmpty) {
      setState(() {
        _showOnBoarding = false;
      });
      final req = await http.get(
        Uri.parse(
          "$API_URL/auth/hydrate",
        ),
        headers: {"Authorization": "Bearer $token"},
      );
      final body = jsonDecode(req.body);
      final user = UserModel.fromJSON(
        body,
        token,
      );
      if (req.statusCode == 200) {
        context.read<UserBloc>().add(
              UserLoggedInEvent(
                id: user.id,
                name: user.name,
                token: token,
                email: user.email,
                createdAt: user.createdAt,
                gems: user.gems,
                updatedAt: user.updatedAt,
              ),
            );
      }
    } else {
      setState(() {
        _showOnBoarding = true;
      });
    }
  }

  @override
  void initState() {
    _checkOnBoardingStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingQuestionsScreen();
    final userBloc = context.read<UserBloc>();
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state.id.isNotEmpty) return const HomeScreen();
        if (_showOnBoarding) return const OnboardingScreen();
        return const Scaffold(
          appBar: null,
          body: Center(
            child: CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 3,
            ),
          ),
        );
      },
      bloc: userBloc,
    );
  }
}
