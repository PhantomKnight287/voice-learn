import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/constants/main.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<String> _logEntries = [];
  late File _logFile;
  @override
  void initState() {
    super.initState();
    _loadLogEntries();
  }

  Future<void> _loadLogEntries() async {
    final directory = (await getApplicationCacheDirectory()).path;
    final info = await PackageInfo.fromPlatform();
    _logFile = File('$directory/logs/log_${info.buildNumber}_${info.version}.txt');

    if (await _logFile.exists()) {
      final logLines = await _logFile.readAsLines();
      setState(() {
        _logEntries = logLines;
      });
    }
  }

  Future<void> _clearLogEntries() async {
    if (await _logFile.exists()) {
      await _logFile.writeAsString(''); // Clear the file
      setState(() {
        _logEntries = [];
      });
    }
  }

  Future<void> _downloadLogFile() async {
    final directory = await getApplicationCacheDirectory();
    final logFilePath = '${directory.path}/logs/log_${DateTime.now().toIso8601String()}.txt';
    final newLogFile = File(logFilePath);

    if (await _logFile.exists()) {
      await newLogFile.writeAsString(await _logFile.readAsString());
      Share.shareXFiles([XFile(newLogFile.path)], text: 'Here are the logs.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: BOTTOM(context),
        title: const Text("Logs"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _clearLogEntries,
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.blue),
            onPressed: _downloadLogFile,
          ),
        ],
      ),
      body: _logEntries.isEmpty
          ? const Center(
              child: Text("No Logs"),
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: _logEntries.length,
                itemBuilder: (context, index) {
                  final entry = _logEntries[index];
                  return Text(
                    entry,
                    style: TextStyle(
                      color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
