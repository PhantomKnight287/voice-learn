import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/bloc/application/application_bloc.dart';
import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/home/main.dart';
import 'package:app/screens/loading/learning.dart';
import 'package:app/screens/onboarding/main.dart';
import 'package:app/screens/onboarding/questions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';

class ViewHandler extends StatefulWidget {
  const ViewHandler({super.key});

  @override
  State<ViewHandler> createState() => _ViewHandlerState();
}

class _ViewHandlerState extends State<ViewHandler> {
  bool _showOnBoarding = true;
  String pathId = '';
  bool _showLoading = true;

  Future<void> _setApplicationState() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    final hasAmplituteControl = await Vibration.hasAmplitudeControl() ?? false;

    if (context.mounted) {
      context.read<ApplicationBloc>().add(
            SetApplicationVibrationOption(
              hasAmplituteControl: hasAmplituteControl,
              hasVibrator: hasVibrator,
            ),
          );
    }
  }

  void _checkOnBoardingStatus() async {
    final time = DateTime.now();
    logger.t("User is residing in ${time.timeZoneName} timezone with offset ${time.timeZoneOffset.toString()}");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token != null && token.isNotEmpty) {
      logger.i("Authentication Token Present, Hydrating User");
      setState(() {
        _showOnBoarding = false;
      });
      final req = await http.get(
        Uri.parse(
          "$API_URL/auth/hydrate?timezone=${time.timeZoneName}&timeZoneOffset=${time.timeZoneOffset.toString()}",
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
        logger.i("User State Hydrated");
        await OneSignal.login(user.id);
        logger.i("Logged into onesignal");
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
          setState(() {});
        }
      } else if (req.statusCode == 401 || req.statusCode == 403) {
        logger.e("Hydrate API Threw Error, Deleting Saved token.");
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
    _setApplicationState();
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
            body: VoiceLearnLoading(),
          ),
      ],
    );
  }
}

class VoiceLearnLoading extends StatelessWidget {
  const VoiceLearnLoading({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RiveAnimation.asset(
        AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? "assets/animations/loading_dark.riv" : "assets/animations/loading_light.riv",
      ),
    );
  }
}
