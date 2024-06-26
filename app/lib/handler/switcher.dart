import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/home/main.dart';
import 'package:app/screens/loading/learning.dart';
import 'package:app/screens/onboarding/main.dart';
import 'package:app/screens/onboarding/questions.dart';
import 'package:flutter/cupertino.dart';
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
  bool _showOnBoarding = true;
  String pathId = '';
  bool _showLoading = true;
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
      if (req.statusCode == 200) {
        final user = UserModel.fromJSON(
          body,
          token,
        );
        context.read<UserBloc>().add(
              UserLoggedInEvent(
                id: user.id,
                name: user.name,
                token: token,
                email: user.email,
                createdAt: user.createdAt,
                paths: user.paths,
                updatedAt: user.updatedAt,
                emeralds: user.emeralds,
                lives: user.lives,
                xp: user.xp,
                streaks: user.streaks,
                isStreakActive: user.isStreakActive,
                tier: user.tier,
                avatarHash: user.avatarHash,
              ),
            );
        if (body['path']?['type'] == 'created') {
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(
              builder: (context) => LearningPathLoadingScreen(pathId: body['path']['id']),
            ),
          );
          return;
        } else if (body['path'] == null) {
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(
              builder: (context) => const OnboardingQuestionsScreen(),
            ),
          );
        } else {
          setState(() {});
        }
      } else if (req.statusCode == 401 || req.statusCode == 403) {
        await prefs.remove("token");
        setState(() {
          _showOnBoarding = true;
        });
      }
    } else {
      setState(() {
        _showOnBoarding = true;
      });
    }
    setState(() {
      _showLoading = false;
    });
  }

  @override
  void initState() {
    _checkOnBoardingStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userBloc = context.read<UserBloc>();
    final state = userBloc.state;
    return Stack(
      children: [
        if (state.id.isNotEmpty) const HomeScreen(),
        if (_showOnBoarding) const OnboardingScreen(),
        if (state.paths == 0 && state.id.isNotEmpty) const OnboardingQuestionsScreen(),
        if (state.paths == 0 && state.id.isEmpty) const OnboardingScreen(),
        if (_showLoading)
          const Scaffold(
            appBar: null,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 3,
              ),
            ),
          ),
      ],
    );
  }
}
