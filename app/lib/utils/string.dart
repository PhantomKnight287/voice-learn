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
  return '$minutes:$seconds';
}

String removeVersionAndTrailingSlash(String url) {
  return url.replaceAll(RegExp(r'/v\d+$'), '').replaceAll(RegExp(r'/$'), '');
}
