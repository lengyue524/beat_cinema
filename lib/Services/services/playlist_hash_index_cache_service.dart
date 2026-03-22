import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PlaylistHashIndexCache {
  final int schemaVersion;
  final DateTime generatedAt;
  final String sourceFingerprint;
  final Map<String, String> entries;

  const PlaylistHashIndexCache({
    required this.schemaVersion,
    required this.generatedAt,
    required this.sourceFingerprint,
    required this.entries,
  });

  PlaylistHashIndexCache copyWith({
    int? schemaVersion,
    DateTime? generatedAt,
    String? sourceFingerprint,
    Map<String, String>? entries,
  }) {
    return PlaylistHashIndexCache(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      generatedAt: generatedAt ?? this.generatedAt,
      sourceFingerprint: sourceFingerprint ?? this.sourceFingerprint,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schemaVersion': schemaVersion,
      'generatedAt': generatedAt.toIso8601String(),
      'sourceFingerprint': sourceFingerprint,
      'entries': entries,
    };
  }

  factory PlaylistHashIndexCache.fromMap(Map<String, dynamic> map) {
    final rawEntries = map['entries'];
    final parsedEntries = <String, String>{};
    if (rawEntries is Map) {
      rawEntries.forEach((key, value) {
        final normalizedKey = key.toString().trim().toLowerCase();
        final normalizedPath = value.toString().trim();
        if (normalizedKey.isEmpty || normalizedPath.isEmpty) {
          return;
        }
        parsedEntries[normalizedKey] = normalizedPath;
      });
    }

    return PlaylistHashIndexCache(
      schemaVersion: map['schemaVersion'] as int? ?? 1,
      generatedAt: DateTime.tryParse(map['generatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sourceFingerprint: map['sourceFingerprint'] as String? ?? '',
      entries: parsedEntries,
    );
  }
}

class PlaylistHashIndexCacheService {
  static const int currentSchemaVersion = 1;
  static const String _cacheFileName = 'playlist_hash_index_cache.json';

  final Future<Directory> Function() _cacheDirectoryProvider;

  PlaylistHashIndexCacheService({
    Future<Directory> Function()? cacheDirectoryProvider,
  }) : _cacheDirectoryProvider =
            cacheDirectoryProvider ?? getApplicationCacheDirectory;

  Future<File> _cacheFile() async {
    final cacheDir = await _cacheDirectoryProvider();
    await cacheDir.create(recursive: true);
    return File(p.join(cacheDir.path, _cacheFileName));
  }

  Future<PlaylistHashIndexCache?> load() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final decoded = json.decode(content);
      if (decoded is! Map<String, dynamic>) return null;
      return PlaylistHashIndexCache.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(PlaylistHashIndexCache cache) async {
    final file = await _cacheFile();
    final tmp = File('${file.path}.tmp');
    final payload = json.encode(cache.toMap());
    await tmp.writeAsString(payload, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tmp.rename(file.path);
  }

  Future<void> clear() async {
    final file = await _cacheFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  String? validate(
    PlaylistHashIndexCache cache, {
    required String expectedFingerprint,
  }) {
    if (cache.schemaVersion != currentSchemaVersion) {
      return 'schema-mismatch';
    }
    if (cache.sourceFingerprint.trim() != expectedFingerprint.trim()) {
      return 'fingerprint-mismatch';
    }
    if (cache.entries.isEmpty) {
      return 'empty-cache';
    }
    return null;
  }
}
