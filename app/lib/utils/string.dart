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
  // Define a regular expression that matches all punctuation characters
  RegExp punctuation = RegExp(r'[^\w\s]');

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
