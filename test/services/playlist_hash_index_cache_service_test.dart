import 'dart:io';

import 'package:beat_cinema/Services/services/playlist_hash_index_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaylistHashIndexCacheService', () {
    late Directory tempDir;
    late PlaylistHashIndexCacheService service;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('playlist_hash_cache_test');
      service = PlaylistHashIndexCacheService(
        cacheDirectoryProvider: () async => tempDir,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saves and loads cache payload', () async {
      final cache = PlaylistHashIndexCache(
        schemaVersion: PlaylistHashIndexCacheService.currentSchemaVersion,
        generatedAt: DateTime(2026, 3, 22),
        sourceFingerprint: 'fp-1',
        entries: const {
          '0afb800a': 'D:/BeatSaber/CustomLevels/LevelA',
          '9ff70655': 'D:/BeatSaber/CustomLevels/LevelB',
        },
      );

      await service.save(cache);
      final loaded = await service.load();

      expect(loaded, isNotNull);
      expect(loaded!.sourceFingerprint, 'fp-1');
      expect(loaded.entries.length, 2);
      expect(loaded.entries['0afb800a'], contains('LevelA'));
    });

    test('returns null for corrupted cache file', () async {
      final badFile = File(
          '${tempDir.path}${Platform.pathSeparator}playlist_hash_index_cache.json');
      await badFile.writeAsString('{invalid-json', flush: true);

      final loaded = await service.load();
      expect(loaded, isNull);
    });

    test('validates schema and fingerprint', () async {
      final cache = PlaylistHashIndexCache(
        schemaVersion: PlaylistHashIndexCacheService.currentSchemaVersion,
        generatedAt: DateTime(2026, 3, 22),
        sourceFingerprint: 'fp-expected',
        entries: const {'abc123': 'D:/BeatSaber/CustomLevels/LevelA'},
      );

      expect(
        service.validate(cache, expectedFingerprint: 'fp-expected'),
        isNull,
      );
      expect(
        service.validate(cache, expectedFingerprint: 'fp-other'),
        isNotNull,
      );
      expect(
        service.validate(
          cache.copyWith(schemaVersion: 999),
          expectedFingerprint: 'fp-expected',
        ),
        isNotNull,
      );
    });
  });
}
