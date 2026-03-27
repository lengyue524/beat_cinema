import 'dart:convert';
import 'dart:io';

import 'package:beat_cinema/Modules/Playlists/bloc/playlist_bloc.dart';
import 'package:beat_cinema/Services/services/atomic_file_service.dart';
import 'package:beat_cinema/Services/services/beatsaver_download_service.dart';
import 'package:beat_cinema/Services/services/playlist_hash_index_cache_service.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('PlaylistBloc playlist mutation', () {
    test('delete songs updates playlist file', () async {
      final root = await Directory.systemTemp.createTemp('playlist_mutation_');
      try {
        final sourcePath = await _writePlaylistFile(
          root.path,
          'source.bplist',
          songs: [
            {'key': 'song_a', 'hash': 'song_a', 'songName': 'Song A'},
            {'key': 'song_b', 'hash': 'song_b', 'songName': 'Song B'},
          ],
        );
        await _writePlaylistFile(
          root.path,
          'target.bplist',
          songs: [
            {'key': 'song_c', 'hash': 'song_c', 'songName': 'Song C'},
          ],
        );
        final levels = [
          LevelMetadata(
            levelPath: p.join(root.path, 'Beat Saber_Data', 'CustomLevels', 'A'),
            songName: 'Song A',
            mapHash: 'song_a',
            lastModified: DateTime(2026, 3, 1),
          ),
          LevelMetadata(
            levelPath: p.join(root.path, 'Beat Saber_Data', 'CustomLevels', 'B'),
            songName: 'Song B',
            mapHash: 'song_b',
            lastModified: DateTime(2026, 3, 1),
          ),
        ];

        final bloc = PlaylistBloc(
          beatSaverDownloadService: _FakeBeatSaverDownloadService(),
          hashIndexCacheService: _FakeHashIndexCacheService(),
        );
        bloc.add(LoadPlaylistsEvent(root.path, levels));
        await Future<void>.delayed(const Duration(milliseconds: 80));
        bloc.add(SelectPlaylistEvent(0));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        bloc.add(DeletePlaylistSongsEvent(
          levelPaths: [levels.first.levelPath],
          deleteSongDirectories: false,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final content = json.decode(await File(sourcePath).readAsString())
            as Map<String, dynamic>;
        final songs = (content['songs'] as List).cast<Map<String, dynamic>>();
        expect(songs.length, 1);
        expect((songs.first['hash'] as String).toLowerCase(), 'song_b');

        expect(bloc.state, isA<PlaylistLoaded>());
        final loaded = bloc.state as PlaylistLoaded;
        expect(loaded.actionNotice?.successCount, 1);
        expect(loaded.actionNotice?.failedCount, 0);
        await bloc.close();
      } finally {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
    });

    test('move songs keeps source/target consistent', () async {
      final root = await Directory.systemTemp.createTemp('playlist_move_');
      try {
        final sourcePath = await _writePlaylistFile(
          root.path,
          'source.bplist',
          songs: [
            {'key': 'song_b', 'hash': 'song_b', 'songName': 'Song B'},
          ],
        );
        final targetPath = await _writePlaylistFile(
          root.path,
          'target.bplist',
          songs: [
            {'key': 'song_c', 'hash': 'song_c', 'songName': 'Song C'},
          ],
        );
        final levelB = LevelMetadata(
          levelPath: p.join(root.path, 'Beat Saber_Data', 'CustomLevels', 'B'),
          songName: 'Song B',
          mapHash: 'song_b',
          lastModified: DateTime(2026, 3, 1),
        );

        final bloc = PlaylistBloc(
          beatSaverDownloadService: _FakeBeatSaverDownloadService(),
          hashIndexCacheService: _FakeHashIndexCacheService(),
        );
        bloc.add(LoadPlaylistsEvent(root.path, [levelB]));
        await Future<void>.delayed(const Duration(milliseconds: 80));
        bloc.add(SelectPlaylistEvent(0));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        bloc.add(MutatePlaylistSongsEvent(
          levelPaths: [levelB.levelPath],
          targetPlaylistPath: targetPath,
          mode: PlaylistMutationMode.move,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 120));

        final sourceMap = json.decode(await File(sourcePath).readAsString())
            as Map<String, dynamic>;
        final targetMap = json.decode(await File(targetPath).readAsString())
            as Map<String, dynamic>;
        expect((sourceMap['songs'] as List).length, 0);
        expect((targetMap['songs'] as List).length, 2);

        final loaded = bloc.state as PlaylistLoaded;
        expect(loaded.selectedPlaylist, isNotNull);
        final sourcePlaylist = loaded.selectedPlaylist!;
        final targetPlaylist = loaded.playlists
            .firstWhere((playlist) => playlist.info.filePath == targetPath);
        expect(sourcePlaylist.songs.length, 0);
        expect(targetPlaylist.songs.length, 2);
        await bloc.close();
      } finally {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
    });

    test('delete with missing directory returns partial failure', () async {
      final root = await Directory.systemTemp.createTemp('playlist_delete_dir_');
      try {
        await _writePlaylistFile(
          root.path,
          'source.bplist',
          songs: [
            {'key': 'song_x', 'hash': 'song_x', 'songName': 'Song X'},
          ],
        );
        final missingLevelPath =
            p.join(root.path, 'Beat Saber_Data', 'CustomLevels', 'Missing');
        final levels = [
          LevelMetadata(
            levelPath: missingLevelPath,
            songName: 'Song X',
            mapHash: 'song_x',
            lastModified: DateTime(2026, 3, 1),
          ),
        ];

        final bloc = PlaylistBloc(
          beatSaverDownloadService: _FakeBeatSaverDownloadService(),
          hashIndexCacheService: _FakeHashIndexCacheService(),
        );
        bloc.add(LoadPlaylistsEvent(root.path, levels));
        await Future<void>.delayed(const Duration(milliseconds: 80));
        bloc.add(SelectPlaylistEvent(0));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        bloc.add(DeletePlaylistSongsEvent(
          levelPaths: [missingLevelPath],
          deleteSongDirectories: true,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 120));

        final loaded = bloc.state as PlaylistLoaded;
        expect(loaded.actionNotice?.successCount, 0);
        expect(loaded.actionNotice?.failedCount, 1);
        expect(loaded.actionNotice?.failureSummary, contains('不存在'));
        await bloc.close();
      } finally {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
    });

    test('delete unmatched songs by identity removes playlist entry', () async {
      final root = await Directory.systemTemp.createTemp('playlist_delete_missing_');
      try {
        final sourcePath = await _writePlaylistFile(
          root.path,
          'source.bplist',
          songs: [
            {'key': 'missing_key', 'hash': 'missing_hash', 'songName': 'Missing Song'},
          ],
        );
        final bloc = PlaylistBloc(
          beatSaverDownloadService: _FakeBeatSaverDownloadService(),
          hashIndexCacheService: _FakeHashIndexCacheService(),
        );
        bloc.add(LoadPlaylistsEvent(root.path, const []));
        await Future<void>.delayed(const Duration(milliseconds: 80));
        bloc.add(SelectPlaylistEvent(0));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        bloc.add(DeletePlaylistSongsEvent(
          songIdentities: const ['missing_key|missing_hash'],
          deleteSongDirectories: false,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 120));

        final sourceMap = json.decode(await File(sourcePath).readAsString())
            as Map<String, dynamic>;
        expect((sourceMap['songs'] as List).length, 0);

        final loaded = bloc.state as PlaylistLoaded;
        expect(loaded.actionNotice?.successCount, 1);
        expect(loaded.actionNotice?.failedCount, 0);
        await bloc.close();
      } finally {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
    });

    test('move rollback keeps source/target unchanged when source write fails',
        () async {
      final root = await Directory.systemTemp.createTemp('playlist_move_rollback_');
      try {
        final sourcePath = await _writePlaylistFile(
          root.path,
          'source.bplist',
          songs: [
            {'key': 'song_b', 'hash': 'song_b', 'songName': 'Song B'},
          ],
        );
        final targetPath = await _writePlaylistFile(
          root.path,
          'target.bplist',
          songs: [
            {'key': 'song_c', 'hash': 'song_c', 'songName': 'Song C'},
          ],
        );
        final levelB = LevelMetadata(
          levelPath: p.join(root.path, 'Beat Saber_Data', 'CustomLevels', 'B'),
          songName: 'Song B',
          mapHash: 'song_b',
          lastModified: DateTime(2026, 3, 1),
        );
        final bloc = PlaylistBloc(
          beatSaverDownloadService: _FakeBeatSaverDownloadService(),
          hashIndexCacheService: _FakeHashIndexCacheService(),
          atomicFileService: _FailOnPathAtomicFileService(
            failPath: sourcePath,
            failOnce: true,
          ),
        );
        bloc.add(LoadPlaylistsEvent(root.path, [levelB]));
        await Future<void>.delayed(const Duration(milliseconds: 80));
        bloc.add(SelectPlaylistEvent(0));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        bloc.add(MutatePlaylistSongsEvent(
          levelPaths: [levelB.levelPath],
          targetPlaylistPath: targetPath,
          mode: PlaylistMutationMode.move,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 200));

        final sourceMap = json.decode(await File(sourcePath).readAsString())
            as Map<String, dynamic>;
        final targetMap = json.decode(await File(targetPath).readAsString())
            as Map<String, dynamic>;
        expect((sourceMap['songs'] as List).length, 1);
        expect((targetMap['songs'] as List).length, 1);

        final loaded = bloc.state as PlaylistLoaded;
        expect(loaded.actionNotice?.failedCount, 1);
        expect(loaded.actionNotice?.successCount, 0);
        await bloc.close();
      } finally {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
    });

    test('update playlist cover writes and clears image field', () async {
      final root = await Directory.systemTemp.createTemp('playlist_cover_update_');
      try {
        final sourcePath = await _writePlaylistFile(
          root.path,
          'source.bplist',
          songs: [
            {'key': 'song_a', 'hash': 'song_a', 'songName': 'Song A'},
          ],
        );
        final bloc = PlaylistBloc(
          beatSaverDownloadService: _FakeBeatSaverDownloadService(),
          hashIndexCacheService: _FakeHashIndexCacheService(),
        );
        bloc.add(LoadPlaylistsEvent(root.path, const []));
        await Future<void>.delayed(const Duration(milliseconds: 80));

        const encoded = 'data:image/png;base64,abc123==';
        bloc.add(UpdatePlaylistCoverEvent(
          playlistPath: sourcePath,
          imageBase64: encoded,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 80));

        final withCover = json.decode(await File(sourcePath).readAsString())
            as Map<String, dynamic>;
        expect(withCover['image'], encoded);

        bloc.add(UpdatePlaylistCoverEvent(
          playlistPath: sourcePath,
          imageBase64: null,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 80));

        final cleared = json.decode(await File(sourcePath).readAsString())
            as Map<String, dynamic>;
        expect(cleared.containsKey('image'), isFalse);

        final loaded = bloc.state as PlaylistLoaded;
        expect(loaded.actionNotice?.type, 'cover');
        expect(loaded.actionNotice?.failedCount, 0);
        await bloc.close();
      } finally {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
    });
  });
}

Future<String> _writePlaylistFile(
  String rootPath,
  String fileName, {
  required List<Map<String, dynamic>> songs,
}) async {
  final playlistDir = Directory(p.join(rootPath, 'Playlists'));
  await playlistDir.create(recursive: true);
  final file = File(p.join(playlistDir.path, fileName));
  final payload = {
    'playlistTitle': fileName,
    'songs': songs,
  };
  await file.writeAsString(json.encode(payload));
  return file.path;
}

class _FakeHashIndexCacheService extends PlaylistHashIndexCacheService {
  _FakeHashIndexCacheService()
      : super(cacheDirectoryProvider: () async => throw UnimplementedError());

  @override
  Future<PlaylistHashIndexCache?> load() async => null;

  @override
  Future<void> save(PlaylistHashIndexCache cache) async {}

  @override
  String? validate(
    PlaylistHashIndexCache cache, {
    required String expectedFingerprint,
  }) {
    return null;
  }
}

class _FakeBeatSaverDownloadService extends BeatSaverDownloadService {}

class _FailOnPathAtomicFileService extends AtomicFileService {
  _FailOnPathAtomicFileService({
    required this.failPath,
    this.failOnce = true,
  });

  final String failPath;
  final bool failOnce;
  bool _hasFailed = false;

  @override
  Future<void> writeString(String filePath, String content) async {
    if (filePath == failPath && (!failOnce || !_hasFailed)) {
      _hasFailed = true;
      throw Exception('simulated write failure for $filePath');
    }
    await super.writeString(filePath, content);
  }
}
