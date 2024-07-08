class LogEntry {
  final String timestamp;
  final String level;
  final String message;

  LogEntry({required this.timestamp, required this.level, required this.message});

  factory LogEntry.fromLine(String line) {
    final parts = line.split(': ');
    final timestamp = parts[0];
    final levelAndMessage = parts[1].split(' - ');
    final level = levelAndMessage[0];
    final message = levelAndMessage[1];

    return LogEntry(
      timestamp: timestamp,
      level: level,
      message: message,
    );
  }
}
