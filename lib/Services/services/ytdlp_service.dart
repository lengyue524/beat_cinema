import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Core/errors/app_error.dart';
import 'package:beat_cinema/Services/repositories/video_repository.dart';
import 'package:beat_cinema/Services/services/proxy_service.dart';
import 'package:beat_cinema/Services/services/ytdlp_error_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class YtDlpService implements VideoRepository {
  static const _safeUtf8Decoder = Utf8Decoder(allowMalformed: true);

  final String beatSaberPath;
  final ProxyMode proxyMode;
  final String customProxy;
  final Map<String, Process> _activeProcesses = {};

  static const _searchTimeout = Duration(seconds: 30);
  static const _downloadTimeout = Duration(minutes: 10);

  YtDlpService({
    required this.beatSaberPath,
    this.proxyMode = ProxyMode.system,
    this.customProxy = '',
  });

  String get _dlpPath =>
      p.join(beatSaberPath, Constants.libsDir, Constants.ytDlpName);

  @override
  Future<List<VideoSearchResult>> search(
      String query, VideoPlatform platform) async {
    final prefix =
        platform == VideoPlatform.bilibili ? 'bilisearch5:' : 'ytsearch5:';

    final args = [
      '--dump-json',
      '--flat-playlist',
      '--no-download',
    ];
    await _appendProxyArgs(args);
    args.add('$prefix$query');

    try {
      final result = await Process.run(_dlpPath, args).timeout(_searchTimeout);

      if (result.exitCode != 0) {
        log.w(
          '[YtDlpService] search failed '
          'query="$query" platform=${platform.name} exitCode=${result.exitCode} '
          'stderr=${result.stderr}',
        );
        throw YtDlpErrorMapper.map(result.stderr as String, result.exitCode);
      }

      final lines = (result.stdout as String)
          .split('\n')
          .where((l) => l.trim().isNotEmpty);

      return lines.map((line) {
        final map = json.decode(line) as Map<String, dynamic>;
        return VideoSearchResult.fromMap(map, platform: platform);
      }).toList();
    } on TimeoutException catch (e, st) {
      log.w(
        '[YtDlpService] search timeout query="$query" platform=${platform.name}',
        e,
        st,
      );
      throw const AppError(
        type: AppErrorType.network,
        userMessageKey: 'error_ytdlp_search_timeout',
        retryable: true,
      );
    } on AppError {
      rethrow;
    } catch (e, st) {
      log.e('[YtDlpService] search exception query="$query" error=$e', e, st);
      throw AppError.fromException(e, context: 'yt-dlp search');
    }
  }

  @override
  Future<VideoInfo> getVideoInfo(String url) async {
    final args = ['--dump-json', '--no-download'];
    await _appendProxyArgs(args);
    args.add(url);

    try {
      final result = await Process.run(_dlpPath, args).timeout(_searchTimeout);

      if (result.exitCode != 0) {
        log.w(
          '[YtDlpService] getVideoInfo failed url=$url '
          'exitCode=${result.exitCode} stderr=${result.stderr}',
        );
        throw YtDlpErrorMapper.map(result.stderr as String, result.exitCode);
      }

      final map = json.decode(result.stdout as String) as Map<String, dynamic>;
      return VideoInfo.fromMap(map);
    } on TimeoutException catch (e, st) {
      log.w('[YtDlpService] getVideoInfo timeout url=$url', e, st);
      throw const AppError(
        type: AppErrorType.network,
        userMessageKey: 'error_ytdlp_search_timeout',
        retryable: true,
      );
    } on AppError {
      rethrow;
    } catch (e, st) {
      log.e('[YtDlpService] getVideoInfo exception url=$url error=$e', e, st);
      throw AppError.fromException(e, context: 'yt-dlp getVideoInfo');
    }
  }

  Future<String> getPlayableStreamUrl(String url) async {
    var result = await _extractPlayableStreamUrl(
      url: url,
      extractorArgs: 'youtube:player_client=android,web',
      formatSelector: 'best[ext=mp4]/best',
    );

    if (result == null || result.trim().isEmpty) {
      result = await _extractPlayableStreamUrl(
        url: url,
        extractorArgs: 'youtube:player_client=tv,web;formats=missing_pot',
        formatSelector: 'best',
      );
    }

    if (result == null || result.trim().isEmpty) {
      throw const AppError(
        type: AppErrorType.network,
        userMessageKey: 'error_ytdlp_video_unavailable',
        retryable: false,
      );
    }
    return result.trim();
  }

  Future<String?> _extractPlayableStreamUrl({
    required String url,
    required String extractorArgs,
    required String formatSelector,
  }) async {
    final args = await buildPlayableUrlArgs(
      url: url,
      extractorArgs: extractorArgs,
      formatSelector: formatSelector,
      proxyMode: proxyMode,
      customProxy: customProxy,
    );
    try {
      final result = await Process.run(_dlpPath, args).timeout(_searchTimeout);
      if (result.exitCode != 0) {
        throw YtDlpErrorMapper.map(result.stderr as String, result.exitCode);
      }
      final lines = (result.stdout as String)
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false);
      return lines.isEmpty ? null : lines.first;
    } on TimeoutException {
      return null;
    } on AppError {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static Future<List<String>> buildPlayableUrlArgs({
    required String url,
    required String extractorArgs,
    required String formatSelector,
    required ProxyMode proxyMode,
    required String customProxy,
  }) async {
    final args = <String>[
      '-g',
      '--no-playlist',
      '--no-warnings',
      '--extractor-args',
      extractorArgs,
      '-f',
      formatSelector,
    ];
    final proxyUrl = await ProxyService.resolveProxyUrl(
      mode: proxyMode,
      customProxy: customProxy,
    );
    if (proxyUrl != null && proxyUrl.isNotEmpty) {
      args.addAll(['--proxy', proxyUrl]);
    }
    args.add(url);
    return args;
  }

  @override
  Future<DownloadResult> download(
    String url,
    String outputDir, {
    String? taskId,
    String? quality,
    void Function(DownloadProgress)? onProgress,
  }) async {
    final resolvedTaskId =
        taskId ?? DateTime.now().millisecondsSinceEpoch.toString();
    log.i(
      '[YtDlpService] download start taskId=$resolvedTaskId '
      'url=$url outputDir=$outputDir',
    );
    final preferredFormatSelector = quality ??
        'bestvideo[height<=1080][vcodec*=avc1]+bestaudio[acodec*=mp4]/'
            'bestvideo[height<=1080]+bestaudio/'
            'best[height<=1080]/best';

    var result = await _runDownloadWithFormat(
      taskId: resolvedTaskId,
      url: url,
      outputDir: outputDir,
      formatSelector: preferredFormatSelector,
      extractorArgs: 'youtube:player_client=android,web',
      onProgress: onProgress,
    );

    if (result.status == DownloadStatus.failed &&
        _shouldRetryWithFallbackFormat(result.errorMessage)) {
      log.w(
        '[YtDlpService] retry with fallback format '
        'taskId=$resolvedTaskId url=$url',
      );
      result = await _runDownloadWithFormat(
        taskId: resolvedTaskId,
        url: url,
        outputDir: outputDir,
        formatSelector: 'bestvideo+bestaudio/best',
        extractorArgs: 'youtube:player_client=android,web',
        onProgress: onProgress,
      );
    }

    if (result.status == DownloadStatus.failed &&
        _shouldRetryWithCompatibilityMode(result.errorMessage)) {
      log.w(
        '[YtDlpService] retry with compatibility mode '
        'taskId=$resolvedTaskId url=$url',
      );
      result = await _runDownloadWithFormat(
        taskId: resolvedTaskId,
        url: url,
        outputDir: outputDir,
        formatSelector: 'best',
        extractorArgs: 'youtube:player_client=tv,web;formats=missing_pot',
        onProgress: onProgress,
      );
    }
    return result;
  }

  Future<DownloadResult> _runDownloadWithFormat({
    required String taskId,
    required String url,
    required String outputDir,
    required String formatSelector,
    required String extractorArgs,
    void Function(DownloadProgress)? onProgress,
  }) async {
    final args = [
      '-f',
      formatSelector,
      '-o',
      p.join(outputDir, '%(title)s.%(ext)s'),
      '--no-cache-dir',
      '--no-playlist',
      '--no-part',
      '--no-continue',
      '--force-overwrites',
      '--recode-video',
      'mp4',
      '--no-mtime',
      '--socket-timeout',
      '10',
      '--newline',
      '--extractor-args',
      extractorArgs,
    ];
    await _appendProxyArgs(args);
    args.add(url);

    final configContent = await _loadConfig();
    if (configContent != null && configContent.isNotEmpty) {
      args.add(configContent);
    }

    try {
      final process = await Process.start(_dlpPath, args);
      _activeProcesses[taskId] = process;

      final completer = Completer<DownloadResult>();
      final stderrBuffer = StringBuffer();

      process.stdout.transform(_safeUtf8Decoder).listen((data) {
        final progress = _parseProgress(data, taskId);
        if (progress != null) onProgress?.call(progress);
      }, onError: (error, stackTrace) {
        log.w(
          '[YtDlpService] stdout decode warning '
          'taskId=$taskId url=$url error=$error',
          error,
          stackTrace,
        );
      });

      process.stderr.transform(_safeUtf8Decoder).listen((data) {
        stderrBuffer.write(data);
      }, onError: (error, stackTrace) {
        log.w(
          '[YtDlpService] stderr decode warning '
          'taskId=$taskId url=$url error=$error',
          error,
          stackTrace,
        );
      });

      process.exitCode.then((code) {
        _activeProcesses.remove(taskId);
        if (code == 0) {
          completer.complete(DownloadResult(
            taskId: taskId,
            status: DownloadStatus.completed,
            outputPath: outputDir,
          ));
        } else {
          log.w(
            '[YtDlpService] download failed '
            'taskId=$taskId url=$url exitCode=$code format="$formatSelector" '
            'stderr=${stderrBuffer.toString()}',
          );
          completer.complete(DownloadResult(
            taskId: taskId,
            status: DownloadStatus.failed,
            errorMessage: stderrBuffer.toString(),
          ));
        }
      });

      return completer.future.timeout(_downloadTimeout, onTimeout: () {
        process.kill();
        _activeProcesses.remove(taskId);
        log.w(
          '[YtDlpService] download timeout '
          'taskId=$taskId url=$url timeout=${_downloadTimeout.inMinutes}m',
        );
        return DownloadResult(
          taskId: taskId,
          status: DownloadStatus.failed,
          errorMessage: 'Download timed out',
        );
      });
    } catch (e, st) {
      _activeProcesses.remove(taskId);
      log.e(
        '[YtDlpService] download exception '
        'taskId=$taskId url=$url format="$formatSelector" error=$e',
        e,
        st,
      );
      return DownloadResult(
        taskId: taskId,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<void> cancelDownload(String taskId) async {
    _activeProcesses[taskId]?.kill();
    _activeProcesses.remove(taskId);
  }

  Future<void> cancelAll() async {
    for (final p in _activeProcesses.values) {
      p.kill();
    }
    _activeProcesses.clear();
  }

  static final _progressRegex = RegExp(r'\[download\]\s+(\d+\.?\d*)%');

  DownloadProgress? _parseProgress(String data, String taskId) {
    final match = _progressRegex.firstMatch(data);
    if (match == null) return null;
    return DownloadProgress(
      taskId: taskId,
      percent: double.tryParse(match.group(1)!) ?? 0,
    );
  }

  Future<String?> _loadConfig() async {
    final configPath =
        p.join(beatSaberPath, Constants.userDataDir, Constants.youtubeDLConfig);
    final file = File(configPath);
    if (await file.exists()) return file.readAsString();
    return null;
  }

  Future<void> _appendProxyArgs(List<String> args) async {
    final proxyUrl = await ProxyService.resolveProxyUrl(
      mode: proxyMode,
      customProxy: customProxy,
    );
    if (proxyUrl == null || proxyUrl.isEmpty) return;
    log.i('[YtDlpService] apply proxy $proxyUrl');
    args.addAll(['--proxy', proxyUrl]);
  }

  bool _shouldRetryWithFallbackFormat(String? errorMessage) {
    final text = (errorMessage ?? '').toLowerCase();
    if (text.isEmpty) return false;
    return text.contains('requested format is not available') ||
        text.contains('signature extraction failed') ||
        text.contains('some formats may be missing') ||
        text.contains('missing a url');
  }

  bool _shouldRetryWithCompatibilityMode(String? errorMessage) {
    final text = (errorMessage ?? '').toLowerCase();
    if (text.isEmpty) return false;
    return text.contains('po token') ||
        text.contains('formats=missing_pot') ||
        text.contains('http error 416') ||
        text.contains('requested range not satisfiable');
  }
}
