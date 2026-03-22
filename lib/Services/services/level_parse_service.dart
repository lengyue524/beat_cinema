import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:beat_cinema/Common/constants.dart';
import 'package:crypto/crypto.dart';
import 'package:beat_cinema/models/cinema_config/cinema_config.dart';
import 'package:beat_cinema/models/custom_level/custom_level.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:path/path.dart' as p;

class LevelParseService {
  Future<List<LevelMetadata>> parseAll(
    String beatSaberPath, {
    bool includeMapHash = true,
  }) async {
    final customLevelsPath =
        p.join(beatSaberPath, Constants.dataDir, Constants.customLevelsDir);
    final dir = Directory(customLevelsPath);
    if (!await dir.exists()) return [];

    final dirs = await dir
        .list()
        .where((e) => e is Directory)
        .map((e) => e.path)
        .toList();

    if (dirs.isEmpty) return [];

    final workerCount = _resolveWorkerCount(
      totalDirs: dirs.length,
      includeMapHash: includeMapHash,
    );
    if (workerCount <= 1) {
      return Isolate.run(() => _parseDirectories(
            dirs,
            includeMapHash: includeMapHash,
          ));
    }

    final chunks = _chunkDirectories(dirs, workerCount);
    final parsedChunks = await Future.wait(
      chunks.map(
        (chunk) => Isolate.run(
          () => _parseDirectories(
            chunk,
            includeMapHash: includeMapHash,
          ),
        ),
      ),
    );
    return parsedChunks.expand((chunk) => chunk).toList(growable: false);
  }

  Future<List<LevelMetadata>> parseDirectories(
    List<String> dirs, {
    bool includeMapHash = true,
  }) async {
    if (dirs.isEmpty) return const [];
    return Isolate.run(() => _parseDirectories(
          dirs,
          includeMapHash: includeMapHash,
        ));
  }

  Future<LevelMetadata?> parseSingleLevel(
    String levelPath, {
    bool includeMapHash = true,
  }) async {
    final dir = Directory(levelPath);
    if (!await dir.exists()) return null;
    return Isolate.run(() => _parseSingleLevel(
          levelPath,
          includeMapHash: includeMapHash,
        ));
  }

  static List<LevelMetadata> _parseDirectories(
    List<String> dirs, {
    required bool includeMapHash,
  }) {
    final results = <LevelMetadata>[];
    for (final dirPath in dirs) {
      results.add(_parseSingleLevel(
        dirPath,
        includeMapHash: includeMapHash,
      ));
    }
    return results;
  }

  static int _resolveWorkerCount({
    required int totalDirs,
    required bool includeMapHash,
  }) {
    if (totalDirs < 200) return 1;
    final cpu = Platform.numberOfProcessors;
    final upperBound = includeMapHash ? 4 : 6;
    final suggested = math.max(2, cpu - 1);
    return math.min(upperBound, suggested);
  }

  static List<List<String>> _chunkDirectories(
      List<String> dirs, int workerCount) {
    final chunkSize = (dirs.length / workerCount).ceil();
    final chunks = <List<String>>[];
    for (var i = 0; i < dirs.length; i += chunkSize) {
      final end = math.min(i + chunkSize, dirs.length);
      chunks.add(dirs.sublist(i, end));
    }
    return chunks;
  }

  static LevelMetadata _parseSingleLevel(
    String dirPath, {
    required bool includeMapHash,
  }) {
    final infoFile = _resolveInfoFile(dirPath);
    final levelRoot = infoFile?.parent.path ?? dirPath;
    final stat = Directory(levelRoot).statSync();

    if (infoFile == null || !infoFile.existsSync()) {
      return _fallbackFromDirName(dirPath, stat.modified);
    }

    try {
      final jsonStr = infoFile.readAsStringSync();
      final level =
          CustomLevel.fromMap(json.decode(jsonStr) as Map<String, dynamic>);

      final difficulties = <String>[];
      if (level.difficultyBeatmapSets != null) {
        for (final set in level.difficultyBeatmapSets!) {
          if (set.difficultyBeatmaps != null) {
            for (final bm in set.difficultyBeatmaps!) {
              final d = bm.difficulty ?? '';
              if (d.isNotEmpty && !difficulties.contains(d)) {
                difficulties.add(d);
              }
            }
          }
        }
      }

      CinemaConfig? cinemaConfig;
      final cinemaFile =
          File(p.join(levelRoot, Constants.cinemaConfigFileName));
      if (cinemaFile.existsSync()) {
        try {
          cinemaConfig = CinemaConfig.fromMap(json
              .decode(cinemaFile.readAsStringSync()) as Map<String, dynamic>);
        } catch (_) {}
      }

      return LevelMetadata(
        songName: level.songName ?? '',
        songSubName: level.songSubName ?? '',
        songAuthorName: level.songAuthorName ?? '',
        levelAuthorName: level.levelAuthorName ?? '',
        bpm: level.beatsPerMinute ?? 0,
        difficulties: difficulties,
        coverImageFilename: level.coverImageFilename,
        parseStatus: ParseStatus.success,
        lastModified: stat.modified,
        cinemaConfig: cinemaConfig,
        rawLevel: level,
        levelPath: levelRoot,
        mapHash: includeMapHash ? _computeLevelHash(levelRoot) : '',
        videoStatus: _resolveVideoStatus(levelRoot, cinemaConfig),
      );
    } catch (_) {
      return _fallbackFromDirName(dirPath, stat.modified);
    }
  }

  static LevelMetadata _fallbackFromDirName(String dirPath, DateTime modified) {
    final dirName = p.basename(dirPath);
    final parts = dirName.split(' ');
    final name = parts.length > 1 ? parts.sublist(1).join(' ') : dirName;

    return LevelMetadata(
      levelPath: dirPath,
      songName: name,
      parseStatus: ParseStatus.failed,
      lastModified: modified,
    );
  }

  static String _computeLevelHash(String dirPath) {
    final fastHash = _tryExtractHashFromDirectoryName(dirPath);
    if (fastHash != null) {
      return fastHash;
    }
    try {
      final bytes = BytesBuilder(copy: false);
      final levelDir = Directory(dirPath);
      final datFilesByName = <String, File>{};
      for (final file in levelDir.listSync().whereType<File>()) {
        final name = p.basename(file.path);
        datFilesByName[name.toLowerCase()] = file;
      }

      final infoPath = p.join(dirPath, Constants.customLevelInfoName);
      final infoFile = File(infoPath);
      if (infoFile.existsSync()) {
        final infoBytes = infoFile.readAsBytesSync();
        bytes.add(infoBytes);
        final beatmapFiles = _resolveBeatmapOrderFromInfo(infoBytes);
        if (beatmapFiles.isNotEmpty) {
          var resolvedAny = false;
          for (final beatmap in beatmapFiles) {
            final normalized = beatmap.trim().toLowerCase();
            final file = datFilesByName[normalized];
            if (file == null || !file.existsSync()) continue;
            resolvedAny = true;
            bytes.add(file.readAsBytesSync());
          }
          if (!resolvedAny) {
            _appendSortedDatFiles(dirPath, bytes);
          }
        } else {
          _appendSortedDatFiles(dirPath, bytes);
        }
      } else {
        _appendSortedDatFiles(dirPath, bytes);
      }

      if (bytes.length == 0) return '';
      final digest = sha1.convert(bytes.takeBytes());
      return digest.toString().toUpperCase();
    } catch (_) {
      return '';
    }
  }

  static String? _tryExtractHashFromDirectoryName(String dirPath) {
    final dirName = p.basename(dirPath).trim();
    if (dirName.isEmpty) return null;
    final match = RegExp(
      r'^customlevel([a-f0-9]{40})(?:$|[\s(].*)',
      caseSensitive: false,
    ).firstMatch(dirName);
    final hash = match?.group(1);
    if (hash == null || hash.isEmpty) return null;
    return hash.toUpperCase();
  }

  static List<String> _resolveBeatmapOrderFromInfo(List<int> infoBytes) {
    try {
      final jsonText = utf8.decode(infoBytes, allowMalformed: true);
      final root = json.decode(jsonText);
      final ordered = <String>[];
      final seen = <String>{};

      void collect(dynamic node) {
        if (node is Map<String, dynamic>) {
          for (final entry in node.entries) {
            final key = entry.key.toLowerCase();
            final value = entry.value;
            final isBeatmapFileKey = key == '_beatmapfilename' ||
                key == 'beatmapfilename' ||
                key == '_beatmapdatafilename' ||
                key == 'beatmapdatafilename';
            if (isBeatmapFileKey && value is String) {
              final file = value.trim();
              if (file.isNotEmpty) {
                final normalized = file.toLowerCase();
                if (seen.add(normalized)) {
                  ordered.add(file);
                }
              }
            }
            collect(value);
          }
          return;
        }
        if (node is List) {
          for (final item in node) {
            collect(item);
          }
        }
      }

      collect(root);
      return ordered;
    } catch (_) {
      return const [];
    }
  }

  static void _appendSortedDatFiles(String dirPath, BytesBuilder bytes) {
    final dir = Directory(dirPath);
    final datFiles = dir.listSync().whereType<File>().where((file) {
      final name = p.basename(file.path).toLowerCase();
      return name.endsWith('.dat') && name != 'info.dat';
    }).toList()
      ..sort((a, b) => p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase()));

    for (final file in datFiles) {
      bytes.add(file.readAsBytesSync());
    }
  }

  static File? _resolveInfoFile(String dirPath) {
    final rootInfo = File(p.join(dirPath, Constants.customLevelInfoName));
    if (rootInfo.existsSync()) {
      return rootInfo;
    }

    try {
      final dir = Directory(dirPath);
      final children = dir.listSync().whereType<Directory>().toList();
      for (final child in children) {
        final nested = File(p.join(child.path, Constants.customLevelInfoName));
        if (nested.existsSync()) {
          return nested;
        }
      }
    } catch (_) {
      // Fallback to null and allow caller to handle parse failure gracefully.
    }

    return null;
  }

  static VideoConfigStatus _resolveVideoStatus(
      String levelRoot, CinemaConfig? cinemaConfig) {
    if (cinemaConfig == null) {
      return VideoConfigStatus.none;
    }
    final configuredFile = (cinemaConfig.videoFile ?? '').trim();
    if (configuredFile.isNotEmpty) {
      final resolvedPath = p.isAbsolute(configuredFile)
          ? configuredFile
          : p.join(levelRoot, configuredFile);
      if (File(resolvedPath).existsSync()) {
        return VideoConfigStatus.configured;
      }
    } else if (_hasAnyVideoFile(levelRoot)) {
      return VideoConfigStatus.configured;
    }

    final hasVideoUrl = (cinemaConfig.videoUrl ?? '').trim().isNotEmpty;
    final hasVideoId = (cinemaConfig.videoId ?? '').trim().isNotEmpty;
    if (hasVideoUrl || hasVideoId) {
      return VideoConfigStatus.configuredMissingFile;
    }
    return VideoConfigStatus.error;
  }

  static bool _hasAnyVideoFile(String levelRoot) {
    try {
      final dir = Directory(levelRoot);
      if (!dir.existsSync()) return false;
      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        final ext = p.extension(entity.path).toLowerCase();
        if (ext == '.mp4' || ext == '.mkv' || ext == '.webm') {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
