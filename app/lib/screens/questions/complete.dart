import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/responses/lessons/stats.dart';
import 'package:app/screens/questions/stats.dart';
import 'package:app/utils/string.dart';
import 'package:async_builder/async_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LessonCompleteScreen extends StatefulWidget {
  final String questionId; //! last question Id as getting lesson id will be hectic in previous screen
  final bool showAd;
  const LessonCompleteScreen({
    super.key,
    required this.questionId,
    required this.showAd,
  });

  @override
  State<LessonCompleteScreen> createState() => LessonCompleteScreenState();
}

class LessonCompleteScreenState extends State<LessonCompleteScreen> {
  late BannerAd _bannerAd;

  @override
  void dispose() {
    super.dispose();
    _bannerAd.dispose();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: LESSON_STATS_AD_ID,
      request: const AdRequest(),
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );

    // Start loading.
    _bannerAd.load();
  }

  Future<LessonStats> _fetchLessonStats() async {
    final userBloc = context.read<UserBloc>();
    final userState = userBloc.state;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final req = await http.get(Uri.parse("$API_URL/lessons/${widget.questionId}/stats"), headers: {
      "Authorization": "Bearer $token",
    });
    final body = jsonDecode(req.body);
    if (req.statusCode == 200) {
      userBloc.add(
        UserLoggedInEvent(
          id: userState.id,
          name: userState.name,
          createdAt: userState.createdAt,
          paths: userState.paths,
          updatedAt: userState.updatedAt,
          token: userState.token,
          emeralds: body['user']['emeralds'],
          lives: body['user']['lives'],
          streaks: body['user']['streaks'],
          xp: body['user']['xp'].toDouble(),
          isStreakActive: body['user']['isStreakActive'],
          tier: userState.tier,
        ),
      );
      return LessonStats.fromJSON(body);
    }
    throw 'Failed to Fetch';
  }

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Lesson Completed",
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BASE_MARGIN * 2,
            0,
            BASE_MARGIN * 2,
            BASE_MARGIN * 2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: BASE_MARGIN * 3,
              ),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    BASE_MARGIN * 5,
                  ),
                  child: Image.asset(
                    'assets/animations/good-anime.gif',
                    width: double.infinity,
                  ),
                ),
              ),
              const Spacer(),
              _bannerAd != null
                  ? SizedBox(
                      width: AdSize.fullBanner.width.toDouble(),
                      height: AdSize.fullBanner.height.toDouble(),
                      child: AdWidget(
                        ad: _bannerAd,
                      ),
                    )
                  : const SizedBox(),
              if (_bannerAd != null) const Spacer(),
              AsyncBuilder(
                waiting: (context) {
                  return const Column(
                    children: [
                      SpinKitRipple(
                        color: PRIMARY_COLOR,
                        size: 100,
                      ),
                    ],
                  );
                },
                builder: (context, value) {
                  return Wrap(
                    children: [
                      StatCard(
                        backgroundColor: const Color(0xFFFFF5F5),
                        borderColor: const Color(0xFFFEE2E2),
                        iconBackgroundColor: const Color(0xFFFEE2E2),
                        icon: const Icon(
                          LucideIcons.locateFixed,
                          color: Color(0xFFF87171),
                        ),
                        title: 'Accuracy',
                        value: "${((value!.correctAnswers / (value.correctAnswers + value.incorrectAnswers)) * 100).toStringAsFixed(0)}%",
                        valueColor: const Color(0xFFEF4444),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 2,
                      ),
                      StatCard(
                        backgroundColor: const Color(0xFFF0FEFF),
                        borderColor: const Color(0xFFCCFBF1),
                        iconBackgroundColor: const Color(0xFFCCFBF1),
                        icon: const Icon(
                          LucideIcons.timer,
                          color: Color(0xFF06B6D4),
                        ),
                        title: 'Time Taken',
                        value: calculateTimeDifference(
                          value.startDate,
                          value.endDate,
                        ),
                        valueColor: const Color(0xFF0891B2),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 2,
                      ),
                      StatCard(
                        backgroundColor: const Color(0xFFF5F3FF),
                        borderColor: const Color(0xFFE9D5FF),
                        iconBackgroundColor: const Color(0xFFE9D5FF),
                        icon: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFA855F7),
                        ),
                        title: 'XP Earned',
                        value: value!.xpEarned.toString(),
                        valueColor: const Color(0xFF8B5CF6),
                      ),
                    ],
                  );
                },
                future: _fetchLessonStats(),
              ),
              const SizedBox(
                height: BASE_MARGIN * 5,
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                },
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
                child: Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(
                height: BASE_MARGIN * 2,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    NoSwipePageRoute(
                      builder: (context) => LessonStatsScreen(
                        lessonId: widget.questionId,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Review",
                        style: TextStyle(
                          color: PRIMARY_COLOR,
                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBackgroundColor;
  final Widget icon;
  final String title;
  final String value;
  final Color valueColor;

  const StatCard({
    super.key,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBackgroundColor,
    required this.icon,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.transparent : backgroundColor,
        border: Border.all(
          color: getSecondaryColor(context),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(
        8,
      ),
      margin: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.all(8),
            child: icon,
          ),
          const SizedBox(
            width: 8,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
