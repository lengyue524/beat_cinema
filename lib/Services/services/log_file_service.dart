import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LogFileService {
  LogFileService({
    Future<Directory> Function()? appDirectoryProvider,
    DateTime Function()? nowProvider,
    this.maxTotalBytes = 10 * 1024 * 1024,
  })  : _appDirectoryProvider =
            appDirectoryProvider ?? getApplicationSupportDirectory,
        _nowProvider = nowProvider ?? DateTime.now;

  final Future<Directory> Function() _appDirectoryProvider;
  final DateTime Function() _nowProvider;
  final int maxTotalBytes;

  Directory? _logsDir;
  Future<void> _writeChain = Future<void>.value();

  Future<Directory> logsDirectory() async {
    if (_logsDir != null) return _logsDir!;
    final appDir = await _appDirectoryProvider();
    final dir = Directory(p.join(appDir.path, 'logs'));
    await dir.create(recursive: true);
    _logsDir = dir;
    return dir;
  }

  Future<void> init() async {
    await logsDirectory();
    await archivePreviousDayLogs();
    await enforceSizeLimit();
  }

  Future<void> writeRecord(LogRecord record) {
    _writeChain = _writeChain.then((_) async {
      try {
        final dir = await logsDirectory();
        final logFile = File(p.join(dir.path, _dailyLogFileName(record.time)));
        final buffer = StringBuffer()
          ..write(record.time.toIso8601String())
          ..write(' [')
          ..write(record.level.name)
          ..write('] ')
          ..write(record.loggerName)
          ..write(': ')
          ..write(record.message);
        if (record.error != null) {
          buffer
            ..write(' | error=')
            ..write(record.error);
        }
        if (record.stackTrace != null) {
          buffer
            ..write(' | stack=')
            ..write(record.stackTrace);
        }
        buffer.write('\n');
        await logFile.writeAsString(
          buffer.toString(),
          mode: FileMode.append,
          flush: true,
          encoding: utf8,
        );
        await enforceSizeLimit();
      } catch (_) {
        // Logging must not break app flow.
      }
    });
    return _writeChain;
  }

  Future<void> archivePreviousDayLogs() async {
    try {
      final dir = await logsDirectory();
      final now = _nowProvider();
      final today = DateTime(now.year, now.month, now.day);
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final fileName = p.basename(entity.path);
        final match =
            RegExp(r'^app-(\d{4}-\d{2}-\d{2})\.log$').firstMatch(fileName);
        if (match == null) continue;
        final date = DateTime.tryParse(match.group(1)!);
        if (date == null || !date.isBefore(today)) continue;
        final zipPath = p.join(dir.path, 'app-${match.group(1)!}.zip');
        final zipFile = File(zipPath);
        if (!await zipFile.exists()) {
          final bytes = await entity.readAsBytes();
          final archive = Archive()
            ..addFile(ArchiveFile(fileName, bytes.length, bytes));
          final encoded = ZipEncoder().encode(archive);
          await zipFile.writeAsBytes(encoded, flush: true);
        }
        if (await entity.exists()) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Archiving must not break app flow.
    }
  }

  Future<void> enforceSizeLimit() async {
    try {
      final dir = await logsDirectory();
      final files = <File>[];
      await for (final entity in dir.list()) {
        if (entity is File) files.add(entity);
      }
      if (files.isEmpty) return;
      var total = 0;
      final stats = <File, int>{};
      for (final file in files) {
        final size = await file.length();
        stats[file] = size;
        total += size;
      }
      if (total <= maxTotalBytes) return;

      final todayFileName = _dailyLogFileName(_nowProvider());
      files.sort((a, b) {
        final am = a.statSync().modified;
        final bm = b.statSync().modified;
        return am.compareTo(bm);
      });

      for (final file in files) {
        if (total <= maxTotalBytes) break;
        final name = p.basename(file.path);
        if (name == todayFileName) continue;
        final size = stats[file] ?? 0;
        if (await file.exists()) {
          await file.delete();
          total -= size;
        }
      }

      if (total > maxTotalBytes) {
        final todayFile = File(p.join(dir.path, todayFileName));
        if (await todayFile.exists()) {
          await _trimFileTail(todayFile, maxTotalBytes);
        }
      }
    } catch (_) {
      // Size control must not break app flow.
    }
  }

  Future<void> _trimFileTail(File file, int keepBytes) async {
    final currentSize = await file.length();
    if (currentSize <= keepBytes) return;
    final bytes = await file.readAsBytes();
    final trimmed = bytes.sublist(currentSize - keepBytes);
    await file.writeAsBytes(trimmed, flush: true);
  }

  String _dailyLogFileName(DateTime time) {
    final y = time.year.toString().padLeft(4, '0');
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    return 'app-$y-$m-$d.log';
  }
}
