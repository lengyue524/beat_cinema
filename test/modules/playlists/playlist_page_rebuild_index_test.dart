import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/bloc/custom_levels_bloc.dart';
import 'package:beat_cinema/Modules/Playlists/bloc/playlist_bloc.dart';
import 'package:beat_cinema/Modules/Playlists/playlist_page.dart';
import 'package:beat_cinema/Services/services/playlist_parse_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  testWidgets('playlist page rebuild flow confirms and dispatches event',
      (tester) async {
    final appBloc = AppBloc();
    final customLevelsBloc = CustomLevelsBloc();
    final playlistBloc = _TrackingPlaylistBloc(
      parseService: _FakePlaylistParseService(),
    );
    playlistBloc.seedLoaded();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppBloc>.value(value: appBloc),
          BlocProvider<CustomLevelsBloc>.value(value: customLevelsBloc),
          BlocProvider<PlaylistBloc>.value(value: playlistBloc),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PlaylistPage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.restart_alt), findsOneWidget);

    await tester.tap(find.byIcon(Icons.restart_alt));
    await tester.pump();

    expect(find.text('Rebuild hash index'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      playlistBloc.recordedEvents
          .any((e) => e is RebuildPlaylistHashIndexEvent),
      isTrue,
    );
  });

  testWidgets('rebuild failure snackbar supports retry action', (tester) async {
    final appBloc = AppBloc();
    final customLevelsBloc = CustomLevelsBloc();
    final playlistBloc = _TrackingPlaylistBloc(
      parseService: _FakePlaylistParseService(),
    );
    playlistBloc.seedLoaded();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppBloc>.value(value: appBloc),
          BlocProvider<CustomLevelsBloc>.value(value: customLevelsBloc),
          BlocProvider<PlaylistBloc>.value(value: playlistBloc),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PlaylistPage()),
        ),
      ),
    );
    await tester.pump();

    playlistBloc.emitFailureNoticeForTest();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Index rebuild failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    final retryAction =
        tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    retryAction.onPressed();
    await tester.pump(const Duration(milliseconds: 100));

    final rebuildCount = playlistBloc.recordedEvents
        .whereType<RebuildPlaylistHashIndexEvent>()
        .length;
    expect(rebuildCount, greaterThan(0));
  });

  testWidgets('playlist action notice shows mutation summary snackbar',
      (tester) async {
    final appBloc = AppBloc();
    final customLevelsBloc = CustomLevelsBloc();
    final playlistBloc = _TrackingPlaylistBloc(
      parseService: _FakePlaylistParseService(),
    );
    playlistBloc.seedLoaded();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppBloc>.value(value: appBloc),
          BlocProvider<CustomLevelsBloc>.value(value: customLevelsBloc),
          BlocProvider<PlaylistBloc>.value(value: playlistBloc),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PlaylistPage()),
        ),
      ),
    );
    await tester.pump();

    playlistBloc.emitActionNoticeForTest();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('成功 2 / 失败 1'), findsOneWidget);
  });

  testWidgets('playlist delete dialog toggles directory switch and dispatches',
      (tester) async {
    final appBloc = AppBloc();
    final customLevelsBloc = CustomLevelsBloc();
    final playlistBloc = _TrackingPlaylistBloc(
      parseService: _FakePlaylistParseService(),
    );
    playlistBloc.seedMissingDetailLoaded();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppBloc>.value(value: appBloc),
          BlocProvider<CustomLevelsBloc>.value(value: customLevelsBloc),
          BlocProvider<PlaylistBloc>.value(value: playlistBloc),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PlaylistPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('playlist-missing-delete-0')));
    await tester.pumpAndSettle();

    expect(find.byType(SwitchListTile), findsOneWidget);
    final switchTile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(switchTile.onChanged, isNull);
    await tester.tap(find.text('删除'));
    await tester.pump(const Duration(milliseconds: 120));

    final deleteEvent = playlistBloc.recordedEvents
        .whereType<DeletePlaylistSongsEvent>()
        .last;
    expect(deleteEvent.deleteSongDirectories, isFalse);
    expect(deleteEvent.levelPaths, isEmpty);
    expect(deleteEvent.songIdentities, isNotEmpty);
  });

  testWidgets('create playlist dialog dispatches CreatePlaylistEvent',
      (tester) async {
    final appBloc = AppBloc();
    final customLevelsBloc = CustomLevelsBloc();
    final playlistBloc = _TrackingPlaylistBloc(
      parseService: _FakePlaylistParseService(),
    );
    playlistBloc.seedLoaded();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppBloc>.value(value: appBloc),
          BlocProvider<CustomLevelsBloc>.value(value: customLevelsBloc),
          BlocProvider<PlaylistBloc>.value(value: playlistBloc),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PlaylistPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.playlist_add));
    await tester.pumpAndSettle();
    expect(find.text('新建歌单'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Road Trip');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    final createEvent = playlistBloc.recordedEvents.whereType<CreatePlaylistEvent>().last;
    expect(createEvent.title, 'Road Trip');
  });

}

class _TrackingPlaylistBloc extends PlaylistBloc {
  _TrackingPlaylistBloc({required PlaylistParseService parseService})
      : super(parseService: parseService);

  final List<PlaylistEvent> recordedEvents = <PlaylistEvent>[];
  int _noticeSerial = 0;

  void seedLoaded() {
    emit(
      PlaylistLoaded(
        playlists: const <PlaylistWithStatus>[
          PlaylistWithStatus(
            info: PlaylistInfo(
              filePath: r'D:\BeatSaber\Playlists\demo.bplist',
              title: 'Demo Playlist',
              songs: <PlaylistSong>[
                PlaylistSong(hash: 'abc123', songName: 'Song A'),
              ],
            ),
            songs: <PlaylistSongWithStatus>[],
            matchedCount: 0,
            configuredCount: 0,
          ),
        ],
      ),
    );
  }

  void emitFailureNoticeForTest() {
    _noticeSerial++;
    emit(
      PlaylistLoaded(
        playlists: const <PlaylistWithStatus>[
          PlaylistWithStatus(
            info: PlaylistInfo(
              filePath: r'D:\BeatSaber\Playlists\demo.bplist',
              title: 'Demo Playlist',
              songs: <PlaylistSong>[
                PlaylistSong(hash: 'abc123', songName: 'Song A'),
              ],
            ),
            songs: <PlaylistSongWithStatus>[],
            matchedCount: 0,
            configuredCount: 0,
          ),
        ],
        rebuildNotice: PlaylistRebuildNotice(
          success: false,
          message: 'playlist_rebuild_error_unknown',
          serial: _noticeSerial,
          detail: 'boom',
        ),
      ),
    );
  }

  void emitActionNoticeForTest() {
    _noticeSerial++;
    emit(
      PlaylistLoaded(
        playlists: const <PlaylistWithStatus>[
          PlaylistWithStatus(
            info: PlaylistInfo(
              filePath: r'D:\BeatSaber\Playlists\demo.bplist',
              title: 'Demo Playlist',
              songs: <PlaylistSong>[
                PlaylistSong(hash: 'abc123', songName: 'Song A'),
              ],
            ),
            songs: <PlaylistSongWithStatus>[],
            matchedCount: 0,
            configuredCount: 0,
          ),
        ],
        actionNotice: const PlaylistActionNotice(
          serial: 1,
          successCount: 2,
          failedCount: 1,
          failureSummary: 'x',
        ),
      ),
    );
  }

  void seedMissingDetailLoaded() {
    const playlistPath = r'D:\BeatSaber\Playlists\demo.bplist';
    emit(
      PlaylistLoaded(
        playlists: [
          PlaylistWithStatus(
            info: const PlaylistInfo(
              filePath: playlistPath,
              title: 'Demo Playlist',
              songs: <PlaylistSong>[
                PlaylistSong(hash: 'missing_hash', key: 'missing_key', songName: 'Song Missing'),
              ],
            ),
            songs: [
              PlaylistSongWithStatus(
                song: const PlaylistSong(
                  hash: 'missing_hash',
                  key: 'missing_key',
                  songName: 'Song Missing',
                ),
              ),
            ],
            matchedCount: 0,
            configuredCount: 0,
          ),
        ],
        selectedIndex: 0,
      ),
    );
  }

  @override
  void add(PlaylistEvent event) {
    recordedEvents.add(event);
    super.add(event);
  }
}

class _FakePlaylistParseService extends PlaylistParseService {
  @override
  Future<List<PlaylistInfo>> parseAll(String beatSaberPath) async {
    return const <PlaylistInfo>[
      PlaylistInfo(
        filePath: r'D:\BeatSaber\Playlists\demo.bplist',
        title: 'Demo Playlist',
        songs: <PlaylistSong>[
          PlaylistSong(hash: 'abc123', songName: 'Song A'),
        ],
      ),
    ];
  }
}
