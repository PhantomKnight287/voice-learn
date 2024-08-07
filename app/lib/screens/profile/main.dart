import 'dart:convert';
import 'dart:math' as math;

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/developer/logs.dart';
import 'package:app/screens/notifications/main.dart';
import 'package:app/screens/settings/main.dart';
import 'package:app/utils/error.dart';
import 'package:async_builder/async_builder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';
import 'package:flutter_gravatar/utils.dart';
import 'package:flutter_svg/svg.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({
    super.key,
    this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final imageHeight = 100;
  List<Color> gradientColors = [
    Colors.cyan,
    Colors.blue,
  ];
  bool _devEnabled = false;
  Future<dynamic> _getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final req = await http.get(Uri.parse(widget.userId != null ? "$API_URL/profile/${widget.userId}" : "$API_URL/profile/@me"), headers: {"Authorization": "Bearer $token"});
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      throw ApiResponseHelper.getErrorMessage(body);
    }
    return body;
  }

  Future<int?> _getUnreadNotificationsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final url = Uri.parse("$API_URL/notifications/unread-count");
    logger.t("Fetching unread notifications count: ${url.toString()}");
    final req = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to fetch unread notifications count: $message");
      return null;
    }
    return body['count'];
  }

  @override
  void initState() {
    super.initState();
    _checkDevMode();
  }

  void _checkDevMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDevEnabled = prefs.getBool("dev_enabled");

    setState(() {
      _devEnabled = isDevEnabled ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.read<UserBloc>().state;
    DateTime dateTime = DateTime.parse(userState.createdAt);
    String monthName = DateFormat.MMMM().format(dateTime);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
        ),
        centerTitle: true,
        actions: widget.userId != null
            ? null
            : [
                if (_devEnabled)
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(NoSwipePageRoute(
                        builder: (context) {
                          return const LogsScreen();
                        },
                      ));
                    },
                    icon: const HeroIcon(
                      HeroIcons.exclamationTriangle,
                    ),
                  ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      NoSwipePageRoute(
                        builder: (context) {
                          return const SettingsScreen();
                        },
                      ),
                    ).then(
                      (value) {
                        _checkDevMode();
                      },
                    );
                  },
                  icon: const Icon(
                    Icons.settings_rounded,
                  ),
                ),
                AsyncBuilder(
                  future: _getUnreadNotificationsCount(),
                  builder: (context, value) {
                    return Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              NoSwipePageRoute(
                                builder: (context) {
                                  return const NotificationsScreen();
                                },
                              ),
                            ).then(
                              (value) {
                                setState(() {});
                              },
                            );
                          },
                          icon: const Icon(Icons.notifications_rounded),
                        ),
                        if (value != null && value != 0)
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                (value) > 99 ? "99+" : value.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  waiting: (context) {
                    return IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          NoSwipePageRoute(
                            builder: (context) {
                              return const NotificationsScreen();
                            },
                          ),
                        ).then(
                          (value) {
                            setState(() {});
                          },
                        );
                      },
                      icon: const Icon(Icons.notifications_rounded),
                    );
                  },
                ),
              ],
        scrolledUnderElevation: 0.0,
        elevation: 0,
        bottom: BOTTOM(
          context,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(
              10,
            ),
            child: widget.userId == null
                ? QueryBuilder<dynamic, dynamic>(
                    'profile_stats',
                    _getUserProfile,
                    builder: (context, query) {
                      if (query.isLoading) {
                        return Column(
                          children: [
                            _buildBaseProfile(
                              userState,
                              context,
                              monthName,
                              dateTime,
                              userState.email != null && userState.email!.isValidEmail()
                                  ? Gravatar(userState.email!).imageUrl(defaultImage: "404")
                                  : "https://api.dicebear.com/8.x/initials/png?seed=${userState.name}",
                            ),
                            _buildStatsLoader(context),
                          ],
                        );
                      }
                      if (query.hasError) {
                        return Column(
                          children: [
                            _buildBaseProfile(
                              userState,
                              context,
                              monthName,
                              dateTime,
                              userState.email != null && userState.email!.isValidEmail()
                                  ? Gravatar(userState.email!).imageUrl(defaultImage: "404")
                                  : "https://api.dicebear.com/8.x/initials/png?seed=${userState.name}",
                            ),
                            _buildStatsLoader(context),
                          ],
                        );
                      }
                      final data = query.data;
                      if (data == null) {
                        return const SizedBox();
                      }
                      final gravatar = Gravatar(data['email']);
                      final url = data['avatar'] ?? gravatar.imageUrl();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBaseProfile(
                            userState,
                            context,
                            monthName,
                            dateTime,
                            url,
                            flags: data?['paths']?[0]?['language']?['flagUrl'] != null
                                ? [
                                    data?['paths']?[0]?['language']?['flagUrl'],
                                  ]
                                : [],
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 3,
                          ),
                          Text(
                            "Statistics",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 3,
                          ),
                          _buildTopStatsRow(context, data),
                          const SizedBox(
                            height: BASE_MARGIN * 2,
                          ),
                          _buildBottomStatsRow(context, data),
                          const SizedBox(
                            height: BASE_MARGIN * 3,
                          ),
                          Text(
                            "XP History",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 3,
                          ),
                          if (data['xpHistory'].isNotEmpty) _buildGraph(data),
                          if (data['xpHistory'].isEmpty)
                            const Center(
                              child: Text(
                                "No XP history found",
                              ),
                            ),
                          const SizedBox(
                            height: BASE_MARGIN * 3,
                          ),
                          Text(
                            "Answers History",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 3,
                          ),
                          (data['answerHistory']['correctAnswers'].isEmpty && data['answerHistory']['incorrectAnswers'].isEmpty)
                              ? const Center(
                                  child: Text(
                                    "No answer history found",
                                  ),
                                )
                              : _buildAnswersGraph(data),
                        ],
                      );
                    },
                  )
                : QueryBuilder<dynamic, dynamic>(
                    "profile_${widget.userId}",
                    _getUserProfile,
                    builder: (context, query) {
                      if (query.isLoading) {
                        return Column(
                          children: [
                            _buildLoader(),
                            _buildStatsLoader(context),
                          ],
                        );
                      }
                      if (query.hasError) {
                        return Center(
                          child: Text(
                            query.error.toString(),
                          ),
                        );
                      }
                      final data = query.data;
                      if (data == null) {
                        return Column(
                          children: [
                            _buildLoader(),
                            _buildStatsLoader(context),
                          ],
                        );
                      }
                      final avatar =
                          data['avatar'] ?? (data['avatarHash'] != null ? "$BASE_GRAVATAR_URL/${data['avatarHash']}?d=404" : "https://api.dicebear.com/8.x/initials/png?seed=${data['name']}");
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBaseProfile(
                            UserInitial(
                              createdAt: data['createdAt'],
                              emeralds: data['emeralds'],
                              id: data['id'],
                              lives: data['lives'],
                              name: data['name'],
                              paths: 0,
                              streaks: data['activeStreaks'],
                              token: data['token'] ?? "",
                              updatedAt: data['updatedAt'],
                              xp: data['xp'].toDouble(),
                              email: data['email'],
                              isStreakActive: false,
                              tier: Tiers.free,
                              voiceMessages: data['voiceMessages'],
                            ),
                            context,
                            monthName,
                            dateTime,
                            avatar,
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 3,
                          ),
                          Text(
                            "Statistics",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 3,
                          ),
                          _buildTopStatsRow(context, data),
                          const SizedBox(
                            height: BASE_MARGIN * 2,
                          ),
                          _buildBottomStatsRow(context, data),
                          Text(
                            "XP History",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 3,
                          ),
                          if (data['xpHistory'].isNotEmpty) _buildGraph(data),
                          if (data['xpHistory'].isEmpty)
                            const Center(
                              child: Text(
                                "No XP history found",
                              ),
                            ),
                          const SizedBox(
                            height: BASE_MARGIN * 3,
                          ),
                          Text(
                            "Answers History",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 3,
                          ),
                          (data['answerHistory']['correctAnswers'].isEmpty && data['answerHistory']['incorrectAnswers'].isEmpty)
                              ? const Center(
                                  child: Text(
                                    "No answer history found",
                                  ),
                                )
                              : _buildAnswersGraph(data),
                        ],
                      );
                    },
                    refreshConfig: RefreshConfig.withDefaults(
                      context,
                      staleDuration: const Duration(
                        seconds: 10,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Row _buildBottomStatsRow(BuildContext context, data) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(
              BASE_MARGIN * 2.5,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: getSecondaryColor(context),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeroIcon(
                  HeroIcons.bolt,
                  color: PRIMARY_COLOR,
                  size: 30,
                  style: HeroIconStyle.solid,
                ),
                const SizedBox(
                  width: BASE_MARGIN * 2,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['longestStreak'].toString(),
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: BASE_MARGIN * 1,
                    ),
                    Text(
                      "Longest streak",
                      style: Theme.of(context).textTheme.titleSmall,
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          width: BASE_MARGIN * 2,
        ),
        Expanded(
            child: Container(
          padding: const EdgeInsets.all(
            BASE_MARGIN * 2.5,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: getSecondaryColor(context),
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(
              10,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                "assets/images/emerald.svg",
                width: 25,
                height: 25,
              ),
              const SizedBox(
                width: BASE_MARGIN * 2,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['emeralds'].toString(),
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 1,
                  ),
                  Text(
                    "Emeralds",
                    style: Theme.of(context).textTheme.titleSmall,
                  )
                ],
              ),
            ],
          ),
        ))
      ],
    );
  }

  Row _buildTopStatsRow(BuildContext context, data) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(
              BASE_MARGIN * 2.5,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: getSecondaryColor(context),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeroIcon(
                  HeroIcons.bolt,
                  color: PRIMARY_COLOR,
                  size: 30,
                  style: HeroIconStyle.solid,
                ),
                const SizedBox(
                  width: BASE_MARGIN * 2,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['activeStreaks'].toString(),
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: BASE_MARGIN * 1,
                    ),
                    Text(
                      "Active streak",
                      style: Theme.of(context).textTheme.titleSmall,
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          width: BASE_MARGIN * 2,
        ),
        Expanded(
            child: Container(
          padding: const EdgeInsets.all(
            BASE_MARGIN * 2.5,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: getSecondaryColor(context),
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(
              10,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                "assets/svgs/xp.svg",
                width: 30,
                height: 30,
              ),
              const SizedBox(
                width: BASE_MARGIN * 2,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['xp'].toString(),
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 1,
                  ),
                  Text(
                    "Total XP",
                    style: Theme.of(context).textTheme.titleSmall,
                  )
                ],
              ),
            ],
          ),
        ))
      ],
    );
  }

  AspectRatio _buildAnswersGraph(data) {
    return AspectRatio(
      aspectRatio: 2,
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(
            show: false,
          ),
          lineBarsData: [
            LineChartBarData(
              color: Colors.green,
              spots: ((data?['answerHistory']['correctAnswers'] as List?) ?? [])
                  .map(
                    (history) => FlSpot(
                      DateTime.parse(history['date']).day.toDouble(),
                      double.parse(history['count']),
                    ),
                  )
                  .toList(),
              isCurved: true,
              dotData: const FlDotData(
                show: true,
              ),
              belowBarData: BarAreaData(
                color: Colors.green.withOpacity(
                  0.5,
                ),
                show: true,
              ),
            ),
            LineChartBarData(
              color: Colors.red,
              spots: ((data?['answerHistory']['incorrectAnswers'] as List?) ?? [])
                  .map(
                    (history) => FlSpot(
                      DateTime.parse(history['date']).day.toDouble(),
                      double.parse(history['count']),
                    ),
                  )
                  .toList(),
              isCurved: true,
              dotData: const FlDotData(
                show: true,
              ),
              belowBarData: BarAreaData(
                color: Colors.red.withOpacity(
                  0.5,
                ),
                show: true,
              ),
            )
          ],
          minY: 0,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Transform.rotate(
                    angle: -math.pi / 2.5,
                    child: Text('${value.toInt()} ${MONTHS[DateTime.now().month - 1]}'),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  AspectRatio _buildGraph(data) {
    return AspectRatio(
      aspectRatio: 2,
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(
            show: false,
          ),
          lineBarsData: [
            LineChartBarData(
              spots: ((data?['xpHistory'] as List?) ?? [])
                  .map(
                    (history) => FlSpot(
                      DateTime.parse(history['date']).day.toDouble(),
                      double.parse(history['earned']),
                    ),
                  )
                  .toList(),
              isCurved: true,
              dotData: const FlDotData(
                show: true,
              ),
              belowBarData: BarAreaData(
                color: Colors.blue.withOpacity(
                  0.2,
                ),
                show: true,
              ),
            )
          ],
          minY: 0,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Transform.rotate(
                    angle: -math.pi / 2.5,
                    child: Text('${value.toInt()} ${MONTHS[DateTime.now().month - 1]}'),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Column _buildStatsLoader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: BASE_MARGIN * 3,
        ),
        Text(
          "Statistics",
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(
          height: BASE_MARGIN * 3,
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(
                  BASE_MARGIN * 2.5,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: getSecondaryColor(context),
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HeroIcon(
                      HeroIcons.bolt,
                      color: PRIMARY_COLOR,
                      size: 30,
                      style: HeroIconStyle.solid,
                    ),
                    const SizedBox(
                      width: BASE_MARGIN * 2,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade400,
                          child: Container(
                            height: 20,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: BASE_MARGIN * 1,
                        ),
                        Text(
                          "Active streak",
                          style: Theme.of(context).textTheme.titleSmall,
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              width: BASE_MARGIN * 2,
            ),
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(
                BASE_MARGIN * 2.5,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: getSecondaryColor(context),
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    "assets/svgs/xp.svg",
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(
                    width: BASE_MARGIN * 2,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade400,
                        child: Container(
                          height: 20,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 1,
                      ),
                      Text(
                        "Total XP",
                        style: Theme.of(context).textTheme.titleSmall,
                      )
                    ],
                  ),
                ],
              ),
            ))
          ],
        ),
        const SizedBox(
          height: BASE_MARGIN * 2,
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(
                  BASE_MARGIN * 2.5,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: getSecondaryColor(context),
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HeroIcon(
                      HeroIcons.bolt,
                      color: PRIMARY_COLOR,
                      size: 30,
                      style: HeroIconStyle.solid,
                    ),
                    const SizedBox(
                      width: BASE_MARGIN * 2,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade400,
                          child: Container(
                            height: 20,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: BASE_MARGIN * 1,
                        ),
                        Text(
                          "Longest streak",
                          style: Theme.of(context).textTheme.titleSmall,
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              width: BASE_MARGIN * 2,
            ),
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(
                BASE_MARGIN * 2.5,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: getSecondaryColor(context),
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    "assets/images/emerald.svg",
                    width: 25,
                    height: 25,
                  ),
                  const SizedBox(
                    width: BASE_MARGIN * 2,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade400,
                        child: Container(
                          height: 20,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 1,
                      ),
                      Text(
                        "Emeralds",
                        style: Theme.of(context).textTheme.titleSmall,
                      )
                    ],
                  ),
                ],
              ),
            ))
          ],
        )
      ],
    );
  }

  Row _buildLoader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade400,
              child: Container(
                height: 20,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(
              height: BASE_MARGIN * 2,
            ),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade400,
              child: Container(
                height: 10,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade400,
          highlightColor: getSecondaryColor(context),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 40,
              child: SizedBox(
                height: 30,
                width: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Column _buildBaseProfile(
    UserState userState,
    BuildContext context,
    String monthName,
    DateTime dateTime,
    String profileUrl, {
    List<String>? flags,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: BASE_MARGIN * 3,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  userState.name,
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: BASE_MARGIN * 2,
                ),
                Text(
                  "Joined $monthName ${dateTime.year}",
                  style: const TextStyle(
                    color: SECONDARY_TEXT_COLOR,
                  ),
                ),
                const SizedBox(
                  height: BASE_MARGIN * 2,
                ),
              ],
            ),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.transparent,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: profileUrl.toString(),
                  progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(
                    value: downloadProgress.progress,
                  ),
                  errorWidget: (context, error, stackTrace) {
                    return const Icon(
                      Icons.account_circle_rounded,
                      size: 80,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
