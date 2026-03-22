import 'dart:convert';
import 'dart:io';

import 'package:beat_cinema/Common/constants.dart';
import 'package:path/path.dart' as p;

class PlaylistInfo {
  final String filePath;
  final String title;
  final String? imageBase64;
  final List<PlaylistSong> songs;

  const PlaylistInfo({
    required this.filePath,
    required this.title,
    this.imageBase64,
    this.songs = const [],
  });
}

class PlaylistSong {
  final String key;
  final String hash;
  final String? songName;
  final List<String> difficulties;
  final bool missingKey;

  const PlaylistSong({
    this.key = '',
    required this.hash,
    this.songName,
    this.difficulties = const [],
    this.missingKey = false,
  });
}

class PlaylistParseService {
  Future<List<PlaylistInfo>> parseAll(String beatSaberPath) async {
    final playlistDir =
        Directory(p.join(beatSaberPath, Constants.playlistPath));
    if (!await playlistDir.exists()) return [];

    final results = <PlaylistInfo>[];
    await for (final entity in playlistDir.list()) {
      if (entity is File && entity.path.endsWith('.bplist')) {
        final info = await _parseSingle(entity);
        if (info != null) results.add(info);
      }
    }
    return results;
  }

  Future<PlaylistInfo?> _parseSingle(File file) async {
    try {
      final content = await file.readAsString();
      final map = json.decode(content) as Map<String, dynamic>;
      final title = map['playlistTitle'] as String? ??
          p.basenameWithoutExtension(file.path);
      final image = map['image'] as String?;

      final songsList = map['songs'] as List<dynamic>? ?? [];
      final songs = songsList.map((s) {
        final sm = s as Map<String, dynamic>;
        final rawKey = (sm['key'] as String?)?.trim();
        final rawHash = (sm['hash'] as String?)?.trim();
        final diffs = <String>[];
        final diffList = sm['difficulties'] as List<dynamic>?;
        if (diffList != null) {
          for (final d in diffList) {
            final dm = d as Map<String, dynamic>;
            final name = dm['name'] as String?;
            if (name != null) diffs.add(name);
          }
        }
        final normalizedKey = (rawKey ?? '').toLowerCase();
        final normalizedHash =
            (rawHash?.isNotEmpty == true ? rawHash! : (rawKey ?? ''))
                .toLowerCase();

        return PlaylistSong(
          key: normalizedKey,
          hash: normalizedHash,
          songName: sm['songName'] as String?,
          difficulties: diffs,
          missingKey: (rawKey == null || rawKey.isEmpty) &&
              (rawHash != null && rawHash.isNotEmpty),
        );
      }).toList();

      return PlaylistInfo(
        filePath: file.path,
        title: title,
        imageBase64: image,
        songs: songs,
      );
    } catch (_) {
      return null;
    }
  }
}
