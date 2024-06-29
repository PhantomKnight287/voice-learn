import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/streak.dart';
import 'package:app/utils/error.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;

class StreaksScreen extends StatefulWidget {
  const StreaksScreen({super.key});

  @override
  State<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends State<StreaksScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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
        bottom: BOTTOM,
        elevation: 0,
        scrolledUnderElevation: 0,
        forceMaterialTransparency: true,
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
              const SizedBox(
                height: BASE_MARGIN * 6,
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
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: PRIMARY_COLOR,
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
                          return Container(
                            margin: const EdgeInsets.all(6.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: todayExists
                                  ? PRIMARY_COLOR
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
            ],
          ),
        ),
      ),
    );
  }
}
