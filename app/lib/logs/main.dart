import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FileLoggerOutput extends LogOutput {
  FileLoggerOutput();

  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      if (kDebugMode) {
        print(line);
      }
    }

    _writeLog(event.origin.level, event.origin.message as String);
  }

  @override
  Future<void> init() async {
    final directory = (await getApplicationCacheDirectory()).path;
    final info = await PackageInfo.fromPlatform();
    final File file = File('$directory/logs/log_${info.buildNumber}_${info.version}.txt');

    if (!(await file.exists())) {
      await file.create(recursive: true);
    }
    return super.init();
  }

  Future<void> _writeLog(Level level, String message) async {
    final DateTime currentDate = DateTime.now();
    final String dateString = "${currentDate.day}-${currentDate.month}-${currentDate.year}";
    final directory = (await getApplicationCacheDirectory()).path;
    final info = await PackageInfo.fromPlatform();
    final File file = File('$directory/logs/log_${info.buildNumber}_${info.version}.txt');

    if (!(await file.exists())) {
      await file.create(recursive: true);
    }

    file.writeAsStringSync(
      "[${level.toString().replaceFirst("Level.", '').toUpperCase()}] [$dateString | ${currentDate.hour}:${currentDate.minute}:${currentDate.second}]  $message\n",
      mode: FileMode.append,
    );
  }
}
