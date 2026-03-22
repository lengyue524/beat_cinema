import 'dart:io';

import 'package:beat_cinema/Modules/Playlists/bloc/playlist_bloc.dart';
import 'package:beat_cinema/Services/services/beatsaver_download_service.dart';
import 'package:beat_cinema/Services/services/level_parse_service.dart';
import 'package:beat_cinema/Services/services/playlist_hash_index_cache_service.dart';
import 'package:beat_cinema/Services/services/playlist_parse_service.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaylistBloc hash index cache', () {
    test('uses cached hash index to avoid hash backfill parse', () async {
      final fakeParseService = _FakePlaylistParseService();
      final fakeLevelParse = _FakeLevelParseService();
      final cacheService = _FakeHashIndexCacheService(
        cache: PlaylistHashIndexCache(
          schemaVersion: PlaylistHashIndexCacheService.currentSchemaVersion,
          generatedAt: DateTime(2026, 3, 22),
          sourceFingerprint: 'stub',
          entries: const {'0afb800a': r'D:\BeatSaber\CustomLevels\MappedSong'},
        ),
      );

      final bloc = PlaylistBloc(
        parseService: fakeParseService,
        levelParseService: fakeLevelParse,
        beatSaverDownloadService: _FakeBeatSaverDownloadService(),
        downloadManager: null,
        hashIndexCacheService: cacheService,
      );

      final levels = [
        LevelMetadata(
          levelPath: r'D:\BeatSaber\CustomLevels\MappedSong',
          songName: 'Song A',
          mapHash: '',
          lastModified: DateTime(2026, 3, 22),
        ),
      ];
      bloc.add(LoadPlaylistsEvent(r'D:\BeatSaber', levels));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fakeLevelParse.hashParseCallCount, 0);
      await bloc.close();
    });

    test('rebuild event parses hash and emits rebuild notice', () async {
      final beatSaberDir =
          await Directory.systemTemp.createTemp('playlist_rebuild_test');
      final mappedSongDir = Directory(
        '${beatSaberDir.path}${Platform.pathSeparator}Beat Saber_Data${Platform.pathSeparator}CustomLevels${Platform.pathSeparator}MappedSong',
      );
      await mappedSongDir.create(recursive: true);

      final fakeParseService = _FakePlaylistParseService();
      final fakeLevelParse = _FakeLevelParseService();
      final cacheService = _FakeHashIndexCacheService(
        cache: PlaylistHashIndexCache(
          schemaVersion: PlaylistHashIndexCacheService.currentSchemaVersion,
          generatedAt: DateTime(2026, 3, 22),
          sourceFingerprint: 'stub',
          entries: const {},
        ),
      );

      final bloc = PlaylistBloc(
        parseService: fakeParseService,
        levelParseService: fakeLevelParse,
        beatSaverDownloadService: _FakeBeatSaverDownloadService(),
        downloadManager: null,
        hashIndexCacheService: cacheService,
      );

      final levels = [
        LevelMetadata(
          levelPath: mappedSongDir.path,
          songName: 'Song A',
          mapHash: '',
          lastModified: DateTime(2026, 3, 22),
        ),
      ];
      bloc.add(LoadPlaylistsEvent(beatSaberDir.path, levels));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      bloc.add(RebuildPlaylistHashIndexEvent());
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(fakeLevelParse.hashParseCallCount, greaterThan(0));
      expect(cacheService.lastSavedCache, isNotNull);
      expect(bloc.state, isA<PlaylistLoaded>());
      final loaded = bloc.state as PlaylistLoaded;
      expect(loaded.rebuildNotice?.success, isTrue);
      expect(loaded.selectedIndex, isNull);
      await bloc.close();
      if (await beatSaberDir.exists()) {
        await beatSaberDir.delete(recursive: true);
      }
    });
  });
}

class _FakePlaylistParseService extends PlaylistParseService {
  @override
  Future<List<PlaylistInfo>> parseAll(String beatSaberPath) async {
    return const [
      PlaylistInfo(
        filePath: r'D:\BeatSaber\Playlists\demo.bplist',
        title: 'Demo',
        songs: [
          PlaylistSong(
            hash: '0afb800a',
            songName: 'Song A',
          ),
        ],
      ),
    ];
  }
}

class _FakeLevelParseService extends LevelParseService {
  int hashParseCallCount = 0;

  @override
  Future<List<LevelMetadata>> parseDirectories(
    List<String> directoryPaths, {
    bool includeMapHash = true,
  }) async {
    if (includeMapHash) {
      hashParseCallCount++;
    }
    return [
      LevelMetadata(
        levelPath: r'D:\BeatSaber\CustomLevels\MappedSong',
        songName: 'Song A',
        mapHash: includeMapHash ? '0AFB800A' : '',
        lastModified: DateTime(2026, 3, 22),
      ),
    ];
  }
}

class _FakeHashIndexCacheService extends PlaylistHashIndexCacheService {
  _FakeHashIndexCacheService({required this.cache})
      : super(cacheDirectoryProvider: () async => throw UnimplementedError());

  final PlaylistHashIndexCache cache;
  PlaylistHashIndexCache? lastSavedCache;

  @override
  Future<PlaylistHashIndexCache?> load() async => cache;

  @override
  Future<void> save(PlaylistHashIndexCache cache) async {
    lastSavedCache = cache;
  }

  @override
  String? validate(
    PlaylistHashIndexCache cache, {
    required String expectedFingerprint,
  }) {
    return null;
  }
}

class _FakeBeatSaverDownloadService extends BeatSaverDownloadService {}
