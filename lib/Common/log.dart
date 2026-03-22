import 'dart:async';
import 'dart:developer' as developer;

import 'package:beat_cinema/Services/services/log_file_service.dart';
import 'package:logging/logging.dart';

final log = Logger("BeatCinema");
LogFileService? _logFileService;
StreamSubscription<LogRecord>? _rootLogSubscription;

Future<void> initAppLogging({
  Level rootLevel = Level.ALL,
  LogFileService? logFileService,
}) async {
  _rootLogSubscription?.cancel();
  _logFileService = logFileService ?? LogFileService();
  await _logFileService!.init();

  Logger.root.level = rootLevel;
  _rootLogSubscription = Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      time: record.time,
      name: record.loggerName,
      level: record.level.value,
      error: record.error,
      stackTrace: record.stackTrace,
    );
    unawaited(_logFileService?.writeRecord(record));
  });
}

extension BeatLogger on Logger {
  void d(Object? message, [Object? error, StackTrace? stackTrace]) {
    finest(message, error, stackTrace);
  }

  void i(Object? message, [Object? error, StackTrace? stackTrace]) {
    info(message, error, stackTrace);
  }

  void w(Object? message, [Object? error, StackTrace? stackTrace]) {
    warning(message, error, stackTrace);
  }

  void e(Object? message, [Object? error, StackTrace? stackTrace]) {
    shout(message, error, stackTrace);
  }
}
