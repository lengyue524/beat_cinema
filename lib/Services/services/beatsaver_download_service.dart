import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:beat_cinema/Common/constants.dart';
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
    final normalizedHash = hash.trim().toUpperCase();
    if (normalizedHash.isEmpty) {
      return DownloadResult(
        taskId: taskId,
        status: DownloadStatus.failed,
        errorMessage: 'Missing song hash',
      );
    }

    final mapApi =
        Uri.parse('https://api.beatsaver.com/maps/hash/$normalizedHash');

    try {
      onProgress?.call(0.05);
      final mapResponse = await _client.get(mapApi);
      if (mapResponse.statusCode != 200) {
        return DownloadResult(
          taskId: taskId,
          status: DownloadStatus.failed,
          errorMessage:
              'BeatSaver lookup failed (${mapResponse.statusCode}) for hash $normalizedHash',
        );
      }

      final mapJson = json.decode(mapResponse.body) as Map<String, dynamic>;
      final versions = (mapJson['versions'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          const [];
      if (versions.isEmpty) {
        return DownloadResult(
          taskId: taskId,
          status: DownloadStatus.failed,
          errorMessage: 'No downloadable version found on BeatSaver',
        );
      }

      final latest = versions.first;
      final downloadUrl = latest['downloadURL'] as String?;
      if (downloadUrl == null || downloadUrl.isEmpty) {
        return DownloadResult(
          taskId: taskId,
          status: DownloadStatus.failed,
          errorMessage: 'Missing download URL from BeatSaver response',
        );
      }

      final remoteHash =
          (latest['hash'] as String?)?.trim().toUpperCase() ?? normalizedHash;
      final mapName =
          (mapJson['name'] as String?)?.trim().isNotEmpty == true
              ? mapJson['name'] as String
              : (titleHint ?? normalizedHash);

      final customLevelsRoot = p.join(
        beatSaberPath,
        Constants.dataDir,
        Constants.customLevelsDir,
      );
      final outputDir = p.join(customLevelsRoot, 'CustomLevel$remoteHash');
      final outputDirectory = Directory(outputDir);
      if (await outputDirectory.exists()) {
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

      for (var i = 0; i < archive.files.length; i++) {
        final file = archive.files[i];
        final outPath = p.join(outputDirectory.path, file.name);
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
      return DownloadResult(
        taskId: taskId,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }
}
