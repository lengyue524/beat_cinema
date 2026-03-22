import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Services/repositories/video_repository.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class BeatSaverDownloadService {
  BeatSaverDownloadService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<DownloadResult> downloadSongByHash({
    required String taskId,
    required String beatSaberPath,
    required String hash,
    String? titleHint,
    void Function(double progress)? onProgress,
  }) async {
    final lookupToken = hash.trim().toLowerCase();
    log.i(
      '[BeatSaverDownload] start taskId=$taskId hash=$lookupToken '
      'titleHint=${titleHint ?? '-'}',
    );
    if (lookupToken.isEmpty) {
      return DownloadResult(
        taskId: taskId,
        status: DownloadStatus.failed,
        errorMessage: 'Missing song key/hash',
      );
    }

    final mapApi = _resolveMapLookupUri(lookupToken);

    try {
      onProgress?.call(0.05);
      final mapResponse = await _getWithRetry(mapApi);
      if (mapResponse.statusCode != 200) {
        log.w(
          '[BeatSaverDownload] lookup failed taskId=$taskId '
          'status=${mapResponse.statusCode} token=$lookupToken',
        );
        return DownloadResult(
          taskId: taskId,
          status: DownloadStatus.failed,
          errorMessage:
              'BeatSaver lookup failed (${mapResponse.statusCode}) for key/hash $lookupToken',
        );
      }

      final mapJson = json.decode(mapResponse.body) as Map<String, dynamic>;
      final versions = (mapJson['versions'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          const [];
      if (versions.isEmpty) {
        log.w(
            '[BeatSaverDownload] no version taskId=$taskId token=$lookupToken');
        return DownloadResult(
          taskId: taskId,
          status: DownloadStatus.failed,
          errorMessage: 'No downloadable version found on BeatSaver',
        );
      }

      final preferred = _pickPreferredVersion(
        versions: versions,
        lookupToken: lookupToken,
      );
      final downloadUrl = preferred['downloadURL'] as String?;
      if (downloadUrl == null || downloadUrl.isEmpty) {
        return DownloadResult(
          taskId: taskId,
          status: DownloadStatus.failed,
          errorMessage: 'Missing download URL from BeatSaver response',
        );
      }

      final remoteHash = (preferred['hash'] as String?)?.trim().toUpperCase() ??
          lookupToken.toUpperCase();
      if (remoteHash.toLowerCase() != lookupToken.toLowerCase()) {
        log.w(
          '[BeatSaverDownload] requested hash differs from selected version '
          'requested=$lookupToken selected=$remoteHash',
        );
      } else {
        log.i(
          '[BeatSaverDownload] selected requested hash version '
          'hash=$remoteHash',
        );
      }
      final mapKey = (mapJson['id'] as String?)?.trim().toLowerCase();
      final mapName = (mapJson['name'] as String?)?.trim().isNotEmpty == true
          ? mapJson['name'] as String
          : (titleHint ?? lookupToken);
      final safeMapName = _sanitizeFolderName(mapName);
      final folderPrefix = (mapKey != null && mapKey.isNotEmpty)
          ? mapKey
          : remoteHash
              .substring(0, remoteHash.length >= 4 ? 4 : remoteHash.length)
              .toLowerCase();
      final folderName = '$folderPrefix ($safeMapName)';

      final customLevelsRoot = p.join(
        beatSaberPath,
        Constants.dataDir,
        Constants.customLevelsDir,
      );
      final outputDir = p.join(customLevelsRoot, folderName);
      final outputDirectory = Directory(outputDir);
      if (await outputDirectory.exists()) {
        log.i(
            '[BeatSaverDownload] already exists taskId=$taskId path=$outputDir');
        return DownloadResult(
          taskId: taskId,
          status: DownloadStatus.completed,
          outputPath: outputDir,
        );
      }

      final tempFile = File(
        p.join(
          Directory.systemTemp.path,
          'beatsaver_${remoteHash}_${DateTime.now().millisecondsSinceEpoch}.zip',
        ),
      );

      onProgress?.call(0.1);
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await _client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return DownloadResult(
          taskId: taskId,
          status: DownloadStatus.failed,
          errorMessage:
              'BeatSaver download failed (${response.statusCode}) for $mapName',
        );
      }

      final sink = tempFile.openWrite();
      final total = response.contentLength ?? -1;
      var received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          final ratio = received / total;
          onProgress?.call(0.1 + (ratio * 0.7));
        }
      }
      await sink.close();

      final bytes = await tempFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      await outputDirectory.create(recursive: true);
      final totalFiles = archive.files.isEmpty ? 1 : archive.files.length;
      final singleRootPrefix = _detectSingleRootPrefix(archive.files);

      for (var i = 0; i < archive.files.length; i++) {
        final file = archive.files[i];
        final relativePath = _normalizeArchivePath(file.name, singleRootPrefix);
        if (relativePath.isEmpty) {
          continue;
        }
        final outPath = p.join(outputDirectory.path, relativePath);
        if (file.isFile) {
          final outFile = File(outPath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(outPath).create(recursive: true);
        }
        onProgress?.call(0.8 + ((i + 1) / totalFiles) * 0.2);
      }

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return DownloadResult(
        taskId: taskId,
        status: DownloadStatus.completed,
        outputPath: outputDir,
      );
    } catch (e) {
      log.e(
          '[BeatSaverDownload] exception taskId=$taskId hash=$lookupToken', e);
      return DownloadResult(
        taskId: taskId,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  Map<String, dynamic> _pickPreferredVersion({
    required List<Map<String, dynamic>> versions,
    required String lookupToken,
  }) {
    final normalizedLookup = lookupToken.trim().toLowerCase();
    for (final version in versions) {
      final versionHash = (version['hash'] as String?)?.trim().toLowerCase();
      if (versionHash != null && versionHash == normalizedLookup) {
        return version;
      }
    }
    return versions.first;
  }

  String _sanitizeFolderName(String raw) {
    final sanitized =
        raw.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();
    if (sanitized.isEmpty) {
      return 'Unknown Song';
    }
    return sanitized;
  }

  Uri _resolveMapLookupUri(String token) {
    final normalized = token.toLowerCase();
    final isLikelyHash = RegExp(r'^[a-f0-9]{8,40}$').hasMatch(normalized);
    if (isLikelyHash) {
      return Uri.parse('https://api.beatsaver.com/maps/hash/$normalized');
    }
    return Uri.parse('https://api.beatsaver.com/maps/id/$normalized');
  }

  Future<http.Response> _getWithRetry(Uri uri) async {
    const maxAttempts = 4;
    http.Response? lastResponse;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final response = await _client.get(uri);
      lastResponse = response;

      if (response.statusCode != 429) {
        return response;
      }

      if (attempt < maxAttempts) {
        final retryAfterSeconds =
            int.tryParse(response.headers['retry-after'] ?? '');
        final delaySeconds =
            retryAfterSeconds ?? min(8, pow(2, attempt).toInt());
        await Future<void>.delayed(Duration(seconds: delaySeconds));
      }
    }

    return lastResponse ?? http.Response('retry failed without response', 500);
  }

  String? _detectSingleRootPrefix(List<ArchiveFile> files) {
    final roots = <String>{};
    for (final file in files) {
      final normalized = file.name.replaceAll('\\', '/').trim();
      if (normalized.isEmpty) continue;
      final first = normalized.split('/').first.trim();
      if (first.isNotEmpty) {
        if (first.toLowerCase() == '__macosx') continue;
        roots.add(first);
      }
    }
    if (roots.length != 1) return null;
    return roots.first;
  }

  String _normalizeArchivePath(String raw, String? singleRootPrefix) {
    var normalized = raw.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) return '';
    if (singleRootPrefix != null &&
        normalized
            .toLowerCase()
            .startsWith('${singleRootPrefix.toLowerCase()}/')) {
      normalized = normalized.substring(singleRootPrefix.length + 1);
    }
    normalized = normalized.replaceAll(RegExp(r'^/+'), '');
    if (normalized.isEmpty) return '';

    final safe = p.normalize(normalized);
    if (safe.startsWith('..') ||
        safe.contains('../') ||
        safe.contains('..\\')) {
      return '';
    }
    return safe;
  }
}
