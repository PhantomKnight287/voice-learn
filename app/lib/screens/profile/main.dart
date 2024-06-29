import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/settings/main.dart';
import 'package:app/utils/error.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) {
                          return const SettingsScreen();
                        },
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.settings_rounded,
                  ),
                ),
              ],
        scrolledUnderElevation: 0.0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        bottom: BOTTOM,
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
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    BASE_MARGIN * 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: SECONDARY_BG_COLOR,
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
                                    color: SECONDARY_BG_COLOR,
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
                                      color: SECONDARY_BG_COLOR,
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
                                    color: SECONDARY_BG_COLOR,
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
                          // AspectRatio(
                          //   aspectRatio: 1.7,
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(
                          //       right: 18,
                          //       left: 12,
                          //       top: 24,
                          //       bottom: 12,
                          //     ),
                          //     child: LineChart(
                          //       LineChartData(
                          //         gridData: FlGridData(
                          //           show: true,
                          //           drawVerticalLine: true,
                          //           horizontalInterval: 1,
                          //           verticalInterval: 1,
                          //           getDrawingHorizontalLine: (value) {
                          //             return const FlLine(
                          //               color: Colors.transparent,
                          //               strokeWidth: 1,
                          //             );
                          //           },
                          //           getDrawingVerticalLine: (value) {
                          //             return const FlLine(
                          //               color: Colors.transparent,
                          //               strokeWidth: 1,
                          //             );
                          //           },
                          //         ),
                          //         titlesData: FlTitlesData(
                          //           show: true,
                          //           rightTitles: const AxisTitles(
                          //             sideTitles: SideTitles(showTitles: false),
                          //           ),
                          //           topTitles: const AxisTitles(
                          //             sideTitles: SideTitles(showTitles: false),
                          //           ),
                          //           bottomTitles: AxisTitles(
                          //             sideTitles: SideTitles(
                          //               showTitles: true,
                          //               reservedSize: 30,
                          //               interval: 1,
                          //               getTitlesWidget: bottomTitleWidgets,
                          //             ),
                          //           ),
                          //           leftTitles: AxisTitles(
                          //             sideTitles: SideTitles(
                          //               showTitles: true,
                          //               interval: 1,
                          //               getTitlesWidget: leftTitleWidgets,
                          //               reservedSize: 42,
                          //             ),
                          //           ),
                          //         ),
                          //         borderData: FlBorderData(
                          //           show: true,
                          //           border: Border.all(color: const Color(0xff37434d)),
                          //         ),
                          //         minX: 0,
                          //         maxX: 11,
                          //         minY: 0,
                          //         maxY: 6,
                          //         lineBarsData: [
                          //           LineChartBarData(
                          //             spots: const [
                          //               FlSpot(0, 3),
                          //               FlSpot(2.6, 2),
                          //               FlSpot(4.9, 5),
                          //               FlSpot(6.8, 3.1),
                          //               FlSpot(8, 4),
                          //               FlSpot(9.5, 3),
                          //               FlSpot(11, 4),
                          //             ],
                          //             isCurved: true,
                          //             gradient: LinearGradient(
                          //               colors: gradientColors,
                          //             ),
                          //             barWidth: 5,
                          //             isStrokeCapRound: true,
                          //             dotData: const FlDotData(
                          //               show: false,
                          //             ),
                          //             belowBarData: BarAreaData(
                          //               show: true,
                          //               gradient: LinearGradient(
                          //                 colors: gradientColors.map((color) => color.withOpacity(0.3)).toList(),
                          //               ),
                          //             ),
                          //           ),
                          //           LineChartBarData(
                          //             spots: const [
                          //               FlSpot(0, 1),
                          //               FlSpot(2.6, 2),
                          //               FlSpot(4.9, 5),
                          //               FlSpot(6.8, 3.1),
                          //               FlSpot(8, 4),
                          //               FlSpot(9.5, 3),
                          //               FlSpot(11, 4),
                          //             ],
                          //             isCurved: true,
                          //             gradient: LinearGradient(
                          //               colors: [
                          //                 Colors.red,
                          //                 Colors.green,
                          //               ],
                          //             ),
                          //             barWidth: 5,
                          //             isStrokeCapRound: true,
                          //             dotData: const FlDotData(
                          //               show: false,
                          //             ),
                          //             belowBarData: BarAreaData(
                          //               show: true,
                          //               gradient: LinearGradient(
                          //                 begin: Alignment.topCenter,
                          //                 end: Alignment.bottomCenter,
                          //                 colors: [
                          //                   Colors.yellow,
                          //                   Colors.blue,
                          //                 ],
                          //               ),
                          //             ),
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          // ),
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
                      final avatar = data['avatarHash'] != null ? "$BASE_GRAVATAR_URL/${data['avatarHash']}" : "https://api.dicebear.com/8.x/initials/png?seed=${data['name']}";
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
                          )
                        ],
                      );
                    },
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
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(
                  BASE_MARGIN * 2.5,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: SECONDARY_BG_COLOR,
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
                  color: SECONDARY_BG_COLOR,
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
                    color: SECONDARY_BG_COLOR,
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
                  color: SECONDARY_BG_COLOR,
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
          highlightColor: SECONDARY_BG_COLOR,
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
              backgroundColor: Colors.grey.shade800,
              backgroundImage: NetworkImage(
                profileUrl,
              ),
            )
          ],
        ),
      ],
    );
  }
}
