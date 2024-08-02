import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/streak.dart';
import 'package:app/utils/error.dart';
import 'package:app/utils/string.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'package:toastification/toastification.dart';

class StreaksScreen extends StatefulWidget {
  const StreaksScreen({super.key});

  @override
  State<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends State<StreaksScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _refillShieldsLoading = false;
  bool _buyOneShieldLoading = false;
  bool isTaskDate(List<DateTime> taskDates, DateTime day) {
    return taskDates.any((date) => isSameDay(date, day));
  }

  Future<List<Streak>> _fetchStreaks({
    DateTime? date,
  }) async {
    date ??= _focusedDay;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final req = await http.get(Uri.parse("$API_URL/streaks/${date.year}/${date.month}"), headers: {"authorization": "Bearer $token"});
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) throw ApiResponseHelper.getErrorMessage(body);
    return (body as List).map((e) => Streak.fromJSON(e)).toList();
  }

  Future<int> _fetchStreakShields() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final url = Uri.parse("$API_URL/streaks/shields");
    logger.t("Fetching ${url.toString()}");
    final req = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to fetch shields: $message");
      throw message;
    }
    logger.t("Fetched Shields");
    return body['shields'] as int;
  }

  Future<void> _buyOneStreakShield() async {
    final userBloc = context.read<UserBloc>();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final url = Uri.parse("$API_URL/streaks/shields/one");
    logger.t("Fetching ${url.toString()}");
    final req = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 201) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to buy 1 shield: $message");
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(message),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
    }
    logger.t("Bought 1 Shield");
    userBloc.add(
      UserLoggedInEvent.setEmeraldsAndLives(
        userBloc.state,
        body['emeralds'],
        userBloc.state.lives,
      ),
    );
    setState(() {});
  }

  Future<void> _refillStreakShields() async {
    final userBloc = context.read<UserBloc>();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final url = Uri.parse("$API_URL/streaks/shields/refill");
    logger.t("Fetching ${url.toString()}");
    final req = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 201) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to refill shields: $message");
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(message),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
    }
    logger.t("Refilled Shields");
    userBloc.add(
      UserLoggedInEvent.setEmeraldsAndLives(
        userBloc.state,
        body['emeralds'],
        userBloc.state.lives,
      ),
    );
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userBloc = context.read<UserBloc>();
    final state = userBloc.state;
    return Scaffold(
      appBar: AppBar(
        bottom: BOTTOM(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        forceMaterialTransparency: false,
        title: const Text(
          "Streaks",
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(BASE_MARGIN * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (state.streaks > 0)
                    Column(
                      children: [
                        Text(
                          state.streaks.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.titleLarge!.fontSize! * 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "day${state.streaks > 1 ? "s" : ""} streak!",
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 2,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      ],
                    ),
                  if (state.streaks < 0)
                    Flexible(
                      flex: 1,
                      child: Wrap(
                        alignment: WrapAlignment.spaceAround,
                        children: [
                          Text(
                            "Complete a lesson to start a streak",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.visible,
                            maxLines: 3,
                            softWrap: true,
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                  Hero(
                    tag: "bolt",
                    child: HeroIcon(
                      HeroIcons.bolt,
                      color: PRIMARY_COLOR,
                      size: 80,
                      style: state.isStreakActive ? HeroIconStyle.solid : HeroIconStyle.outline,
                    ),
                  ),
                ],
              ),
              const Divider(),
              SizedBox(
                height: BASE_MARGIN * (state.isStreakActive ? 2 : 3),
              ),
              if (state.isStreakActive == false)
                Column(
                  children: [
                    Center(
                      child: Text(
                        "${getResetTime(
                          DateTime.now().timeZoneName,
                        )} hrs until streak resets",
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: BASE_MARGIN * 2,
                    ),
                    const Divider(),
                  ],
                ),
              Text(
                "Streaks Calendar",
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: BASE_MARGIN * 3,
              ),
              QueryBuilder(
                "streak_${_focusedDay.year}_${_focusedDay.month}",
                _fetchStreaks,
                refreshConfig: _focusedDay.year == DateTime.now().year && _focusedDay.month == DateTime.now().month
                    ? RefreshConfig.withDefaults(
                        context,
                        staleDuration: const Duration(
                          seconds: 0,
                        ),
                      )
                    : null,
                builder: (context, query) {
                  if (query.isLoading) {
                    return const Center(
                      child: CupertinoActivityIndicator(
                        animating: true,
                      ),
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
                  if (data == null) return const SizedBox();
                  return Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(
                          10,
                        )),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onFormatChanged: (format) {
                        if (_calendarFormat != format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          if (isTaskDate(data.map((e) => e.createdAt).toList(), day)) {
                            final date = data.firstWhereOrNull(
                              (d) => d.createdAt.toLocal().day == day.day && d.createdAt.toLocal().month == day.month && d.createdAt.toLocal().year == day.year,
                            );
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: date != null
                                    ? date.type == "active"
                                        ? PRIMARY_COLOR
                                        : Colors.lime
                                    : PRIMARY_COLOR,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                day.day.toString(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                        todayBuilder: (context, day, focusedDay) {
                          final last = data.isNotEmpty ? data.last : null;
                          final today = DateTime.now();
                          final todayExists = last == null ? false : last.createdAt.day == today.day && last.createdAt.month == today.month && last.createdAt.year == today.year;
                          final date = data.firstWhereOrNull(
                            (d) => d.createdAt.toLocal().day == day.day && d.createdAt.toLocal().month == day.month && d.createdAt.toLocal().year == day.year,
                          );
                          return Container(
                            margin: const EdgeInsets.all(6.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: todayExists
                                  ? date != null
                                      ? date.type == "active"
                                          ? PRIMARY_COLOR
                                          : Colors.lime
                                      : PRIMARY_COLOR
                                  : PRIMARY_COLOR.withAlpha(
                                      100,
                                    ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              day.day.toString(),
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: todayExists ? FontWeight.w600 : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(
                height: BASE_MARGIN * 2,
              ),
              Text(
                "Streak",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                  fontFamily: "CalSans",
                ),
              ),
              const SizedBox(
                height: BASE_MARGIN * 3,
              ),
              QueryBuilder(
                'shields',
                _fetchStreakShields,
                builder: (context, query) {
                  if (query.hasError) {
                    return Center(
                      child: Text(query.error.toString()),
                    );
                  }
                  final data = query.data;
                  return GestureDetector(
                    onTap: () {
                      if (data == null) return;
                      showModalBottomSheet(
                        context: context,
                        enableDrag: true,
                        showDragHandle: true,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, _setState) {
                              return Padding(
                                padding: const EdgeInsets.all(BASE_MARGIN * 2),
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: BASE_MARGIN * 2,
                                    ),
                                    const SizedBox(
                                      height: BASE_MARGIN * 4,
                                    ),
                                    Text(
                                      data >= 5 ? "You have full shields" : "You have ${data} ${data == 1 ? "shield" : "shields"}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: BASE_MARGIN * 4,
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (data >= 5) return;
                                        _setState(() {
                                          _refillShieldsLoading = true;
                                        });
                                        await _refillStreakShields();
                                        await query.refresh();
                                        _setState(() {
                                          _refillShieldsLoading = false;
                                        });
                                        if (context.mounted) Navigator.pop(context);
                                      },
                                      style: ButtonStyle(
                                        backgroundColor: data < 5
                                            ? WidgetStateProperty.all(
                                                getSecondaryColor(context),
                                              )
                                            : WidgetStateProperty.all(
                                                Colors.grey.shade500,
                                              ),
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
                                      child: _refillShieldsLoading
                                          ? Container(
                                              width: 24,
                                              height: 24,
                                              padding: const EdgeInsets.all(2.0),
                                              child: const CupertinoActivityIndicator(
                                                animating: true,
                                                radius: 20,
                                              ),
                                            )
                                          : Row(
                                              children: [
                                                HeroIcon(
                                                  HeroIcons.shieldExclamation,
                                                  size: 30,
                                                  color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                ),
                                                const SizedBox(
                                                  width: BASE_MARGIN * 2,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    "Refill shields",
                                                    style: TextStyle(
                                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                      fontWeight: FontWeight.w600,
                                                      color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                data > 5
                                                    ? ColorFiltered(
                                                        colorFilter: const ColorFilter.mode(
                                                          Colors.grey,
                                                          BlendMode.saturation,
                                                        ),
                                                        child: SvgPicture.asset(
                                                          "assets/images/emerald.svg",
                                                          width: 25,
                                                          height: 25,
                                                        ),
                                                      )
                                                    : SvgPicture.asset(
                                                        "assets/images/emerald.svg",
                                                        width: 25,
                                                        height: 25,
                                                      ),
                                                const SizedBox(
                                                  width: BASE_MARGIN * 2,
                                                ),
                                                Text(
                                                  data >= 5 ? "50" : ((5 - data!) * 10).toString(),
                                                  style: TextStyle(
                                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                    fontWeight: FontWeight.w600,
                                                    color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                    const SizedBox(
                                      height: BASE_MARGIN * 4,
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (data >= 5) return;
                                        _setState(() {
                                          _buyOneShieldLoading = true;
                                        });
                                        await _buyOneStreakShield();
                                        await query.refresh();
                                        _setState(() {
                                          _buyOneShieldLoading = false;
                                        });
                                        if (context.mounted) Navigator.pop(context);
                                      },
                                      style: ButtonStyle(
                                        backgroundColor: data < 5
                                            ? WidgetStateProperty.all(
                                                getSecondaryColor(context),
                                              )
                                            : WidgetStateProperty.all(
                                                Colors.grey.shade500,
                                              ),
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
                                      child: _buyOneShieldLoading
                                          ? Container(
                                              width: 24,
                                              height: 24,
                                              padding: const EdgeInsets.all(2.0),
                                              child: const CupertinoActivityIndicator(
                                                animating: true,
                                                radius: 20,
                                              ),
                                            )
                                          : Row(
                                              children: [
                                                HeroIcon(
                                                  HeroIcons.shieldExclamation,
                                                  size: 30,
                                                  color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                ),
                                                const SizedBox(
                                                  width: BASE_MARGIN * 2,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    "Refill 1 shield",
                                                    style: TextStyle(
                                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                      fontWeight: FontWeight.w600,
                                                      color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                data > 5
                                                    ? ColorFiltered(
                                                        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                                        child: SvgPicture.asset(
                                                          "assets/images/emerald.svg",
                                                          width: 25,
                                                          height: 25,
                                                        ),
                                                      )
                                                    : SvgPicture.asset(
                                                        "assets/images/emerald.svg",
                                                        width: 25,
                                                        height: 25,
                                                      ),
                                                const SizedBox(
                                                  width: BASE_MARGIN * 2,
                                                ),
                                                Text(
                                                  "10",
                                                  style: TextStyle(
                                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                    fontWeight: FontWeight.w600,
                                                    color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: getSecondaryColor(context),
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                      ),
                      padding: const EdgeInsets.all(
                        BASE_MARGIN * 4,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HeroIcon(
                            HeroIcons.shieldExclamation,
                            size: 30,
                          ),
                          const SizedBox(
                            width: BASE_MARGIN * 4,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Streak Shields protect your streak by covering a missed day, so you can keep your progress intact. Use them wisely to stay on track!",
                                ),
                                const SizedBox(
                                  height: BASE_MARGIN * 2,
                                ),
                                if (query.isLoading)
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
                                if (data != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: data == 0 ? Colors.red.shade100 : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "$data/5 equipped",
                                      style: TextStyle(
                                        color: data == 0 ? Colors.red[800] : Colors.green[800],
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                refreshConfig: RefreshConfig.withDefaults(
                  context,
                  staleDuration: Duration(
                    seconds: 0,
                  ),
                  refreshOnQueryFnChange: true,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
