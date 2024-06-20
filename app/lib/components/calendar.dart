import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({required this.startDate, required this.endDate});
}

class CalendarWidget extends StatelessWidget {
  final List<DateRange> dateRanges;

  CalendarWidget({required this.dateRanges});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar Widget'),
      ),
      body: IgnorePointer(
        ignoring: true, // This will disable any interaction with the calendar
        child: TableCalendar(
          firstDay: DateTime.utc(2010, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: DateTime.now(),
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) {
            return isWithinRanges(day, dateRanges);
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, date, _) {
              if (isWithinRanges(date, dateRanges)) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}

bool isWithinRanges(DateTime date, List<DateRange> ranges) {
  for (DateRange range in ranges) {
    if (date.isAfter(range.startDate.subtract(Duration(days: 1))) && date.isBefore(range.endDate.add(Duration(days: 1)))) {
      return true;
    }
  }
  return false;
}
