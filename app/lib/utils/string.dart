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
