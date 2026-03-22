import 'dart:io';

import 'package:beat_cinema/Services/services/log_file_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  group('LogFileService', () {
    late Directory rootDir;

    setUp(() async {
      rootDir = await Directory.systemTemp.createTemp('beat_cinema_log_test');
    });

    tearDown(() async {
      if (await rootDir.exists()) {
        await rootDir.delete(recursive: true);
      }
    });

    test('creates logs directory and writes daily log', () async {
      final now = DateTime(2026, 3, 22, 10, 30);
      final service = LogFileService(
        appDirectoryProvider: () async => rootDir,
        nowProvider: () => now,
      );

      await service.init();
      await service.writeRecord(
        LogRecord(Level.INFO, 'hello', 'BeatCinema'),
      );

      final logsDir = Directory('${rootDir.path}${Platform.pathSeparator}logs');
      final logFile = File(
        '${logsDir.path}${Platform.pathSeparator}app-2026-03-22.log',
      );
      expect(await logsDir.exists(), isTrue);
      expect(await logFile.exists(), isTrue);
      final content = await logFile.readAsString();
      expect(content, contains('[INFO]'));
      expect(content, contains('hello'));
    });

    test('archives previous day log to zip and removes log file', () async {
      final now = DateTime(2026, 3, 22, 8, 0);
      final logsDir = Directory('${rootDir.path}${Platform.pathSeparator}logs');
      await logsDir.create(recursive: true);
      final yesterdayLog = File(
        '${logsDir.path}${Platform.pathSeparator}app-2026-03-21.log',
      );
      await yesterdayLog.writeAsString('old log', flush: true);

      final service = LogFileService(
        appDirectoryProvider: () async => rootDir,
        nowProvider: () => now,
      );
      await service.init();

      final zipFile = File(
        '${logsDir.path}${Platform.pathSeparator}app-2026-03-21.zip',
      );
      expect(await zipFile.exists(), isTrue);
      expect(await yesterdayLog.exists(), isFalse);
    });

    test('enforces total size limit by removing oldest files', () async {
      final logsDir = Directory('${rootDir.path}${Platform.pathSeparator}logs');
      await logsDir.create(recursive: true);
      final oldZip = File('${logsDir.path}${Platform.pathSeparator}a-old.zip');
      final midZip = File('${logsDir.path}${Platform.pathSeparator}b-mid.zip');
      final todayLog =
          File('${logsDir.path}${Platform.pathSeparator}app-2026-03-22.log');

      await oldZip.writeAsBytes(List<int>.filled(70, 1), flush: true);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await midZip.writeAsBytes(List<int>.filled(70, 2), flush: true);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await todayLog.writeAsBytes(List<int>.filled(20, 3), flush: true);

      final service = LogFileService(
        appDirectoryProvider: () async => rootDir,
        nowProvider: () => DateTime(2026, 3, 22, 12, 0),
        maxTotalBytes: 100,
      );
      await service.enforceSizeLimit();

      expect(await oldZip.exists(), isFalse);
      expect(await todayLog.exists(), isTrue);
      final total = await _totalSize(logsDir);
      expect(total <= 100, isTrue);
    });

    test('trim current day log when no other file can be deleted', () async {
      final logsDir = Directory('${rootDir.path}${Platform.pathSeparator}logs');
      await logsDir.create(recursive: true);
      final todayLog =
          File('${logsDir.path}${Platform.pathSeparator}app-2026-03-22.log');
      await todayLog.writeAsBytes(List<int>.filled(200, 1), flush: true);

      final service = LogFileService(
        appDirectoryProvider: () async => rootDir,
        nowProvider: () => DateTime(2026, 3, 22, 12, 0),
        maxTotalBytes: 100,
      );
      await service.enforceSizeLimit();

      expect(await todayLog.length(), lessThanOrEqualTo(100));
    });
  });
}

Future<int> _totalSize(Directory dir) async {
  var total = 0;
  await for (final entity in dir.list()) {
    if (entity is File) {
      total += await entity.length();
    }
  }
  return total;
}
