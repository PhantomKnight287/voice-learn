String numberToOrdinal(int number) {
  if (number <= 0) return number.toString(); // Handle non-positive numbers

  int lastDigit = number % 10;
  int lastTwoDigits = number % 100;

  String suffix;

  if (lastTwoDigits >= 11 && lastTwoDigits <= 13) {
    suffix = 'th';
  } else {
    switch (lastDigit) {
      case 1:
        suffix = 'st';
        break;
      case 2:
        suffix = 'nd';
        break;
      case 3:
        suffix = 'rd';
        break;
      default:
        suffix = 'th';
    }
  }

  return '$number$suffix';
}

String removePunctuation(String input) {
  // Define a regular expression that matches punctuation characters
  RegExp punctuation = RegExp(r'''[!"#\$%&\'()*+,\-./:;<=>?@[\\\]^_`{|}~]''');

  // Use the replaceAll method to remove all matched characters
  return input.replaceAll(punctuation, '');
}

String calculateTimeDifference(String isoString1, String isoString2) {
  // Parse the ISO strings into DateTime objects
  DateTime dateTime1 = DateTime.parse(isoString1);
  DateTime dateTime2 = DateTime.parse(isoString2);

  // Calculate the difference between the two DateTime objects
  Duration difference = dateTime2.difference(dateTime1);

  // Extract minutes and seconds from the Duration object
  int minutes = difference.inMinutes;
  int seconds = difference.inSeconds.remainder(60);

  // Return the time difference as a formatted string
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String removeVersionAndTrailingSlash(String url) {
  return url.replaceAll(RegExp(r'/v\d+$'), '').replaceAll(RegExp(r'/$'), '');
}

int stringTimeInSec(String time) {
  List<String> parts = time.split(':');
  int minutes = int.parse(parts[0]);
  int seconds = int.parse(parts[1]);
  return minutes * 60 + seconds;
}

String secInTime(int sec) {
  int minutes = (sec / 60).floor();
  int restSecs = sec % 60;
  return '$minutes:${restSecs.toString().padLeft(2, '0')}';
}

String getResetTime(String userTimeZone) {
  // Get current time in user's time zone
  DateTime currentUserTime = DateTime.now().toUtc().add(getTimeZoneOffset(userTimeZone));

  // Get next midnight in user's time zone
  DateTime nextMidnight = DateTime(
    currentUserTime.year,
    currentUserTime.month,
    currentUserTime.day,
    0,
    0,
  ).add(Duration(days: 1));

  // Calculate the difference
  Duration difference = nextMidnight.difference(currentUserTime);

  // Format the difference
  int hours = difference.inHours;
  int minutes = difference.inMinutes.remainder(60);

  // Return the formatted result
  return "$hours:${minutes.toString().padLeft(2, '0')}";
}

Duration getTimeZoneOffset(String timeZone) {
  // This function should return the offset of the given time zone from UTC
  // You'll need to implement this based on your time zone data source
  // For example, you might use a package like `timezone` to get this information
  // Here's a placeholder implementation:
  return Duration(hours: 0); // Replace with actual implementation
}
