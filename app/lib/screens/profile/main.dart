import 'dart:convert';
import 'dart:math';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/developer/logs.dart';
import 'package:app/screens/settings/main.dart';
import 'package:app/utils/error.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gravatar/utils.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gravatar/flutter_gravatar.dart';
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
                    widget.userId != null ? "profile_${widget.userId}" : 'profile_stats',
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
                              userState.email != null && userState.email!.isValidEmail() ? Gravatar(userState.email!).imageUrl() : "https://api.dicebear.com/8.x/initials/png?seed=${userState.name}",
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
                              userState.email != null && userState.email!.isValidEmail() ? Gravatar(userState.email!).imageUrl() : "https://api.dicebear.com/8.x/initials/png?seed=${userState.name}",
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
                      final url = gravatar.imageUrl();
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
                          Row(
                            children: [
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
                                    Image.asset(
                                      "assets/images/coin.png",
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
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 2,
                          ),
                          Row(
                            children: [
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
                                    Image.asset(
                                      "assets/images/emerald.png",
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
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 3,
                          ),
                          if ((data?['xpHistory'] as List).isNotEmpty)
                            Text(
                              "XP History",
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if ((data?['xpHistory'] as List).isNotEmpty)
                            const SizedBox(
                              height: BASE_MARGIN * 3,
                            ),
                          if ((data?['xpHistory'] as List).isNotEmpty) _buildGraph(data),
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
                      final avatar = data['avatarHash'] != null ? "$BASE_GRAVATAR_URL/${data['avatarHash']}?d=404" : "https://api.dicebear.com/8.x/initials/png?seed=${data['name']}";
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
                          Row(
                            children: [
                              Expanded(
                                  child: Container(
                                padding: const EdgeInsets.all(
                                  BASE_MARGIN * 2.5,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      "assets/images/coin.png",
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
                                    color: Colors.grey,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      "assets/images/emerald.png",
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
                          ),
                          if ((data?['xpHistory'] as List).isNotEmpty)
                            Text(
                              "XP History",
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if ((data?['xpHistory'] as List).isNotEmpty)
                            const SizedBox(
                              height: BASE_MARGIN * 3,
                            ),
                          if ((data?['xpHistory'] as List).isNotEmpty) _buildGraph(data),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  AspectRatio _buildGraph(data) {
    return AspectRatio(
      aspectRatio: 1,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: ((data?['xpHistory'] as List) ?? [])
                  .map(
                    (history) => FlSpot(
                      DateTime.parse(history['date']).day.toDouble(),
                      double.parse(history['earned']),
                    ),
                  )
                  .toList(),
              isCurved: true,
              dotData: FlDotData(
                show: true,
              ),
              belowBarData: BarAreaData(
                color: Colors.blue.withOpacity(0.3),
                show: true,
              ),
            )
          ],
          minY: 0,
          gridData: FlGridData(
            show: false,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()} ${MONTHS[DateTime.now().month - 1]}');
                },
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );
    String text;
    switch (value.toInt()) {
      case 1:
        text = '10K';
        break;
      case 3:
        text = '30k';
        break;
      case 5:
        text = '50k';
        break;
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.left);
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;
    switch (value.toInt()) {
      case 2:
        text = const Text('MAR', style: style);
        break;
      case 5:
        text = const Text('JUN', style: style);
        break;
      case 8:
        text = const Text('SEP', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
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
                  Image.asset(
                    "assets/images/coin.png",
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
                  Image.asset(
                    "assets/images/emerald.png",
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
                child: Image.network(
                  profileUrl.toString(),
                  errorBuilder: (context, error, stackTrace) {
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
