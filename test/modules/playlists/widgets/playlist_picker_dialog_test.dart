import 'package:beat_cinema/Modules/Playlists/bloc/playlist_bloc.dart';
import 'package:beat_cinema/Modules/Playlists/widgets/playlist_picker_dialog.dart';
import 'package:beat_cinema/Services/services/playlist_parse_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filters playlists with case-insensitive query', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaylistPickerDialog(
            playlists: _playlists,
            mode: PlaylistMutationMode.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('playlist-picker-search-input')),
      'road',
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsOneWidget);
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    final richText = tile.title as RichText;
    expect(richText.text.toPlainText(), contains('Road Trip'));
  });

  testWidgets('shows empty state when no result', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaylistPickerDialog(
            playlists: _playlists,
            mode: PlaylistMutationMode.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('playlist-picker-search-input')),
      'not-exists',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('playlist-picker-empty')), findsOneWidget);
  });

  testWidgets('move mode disables current playlist target', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaylistPickerDialog(
            playlists: _playlists,
            mode: PlaylistMutationMode.move,
            currentPlaylistPath: r'D:\BeatSaber\Playlists\road.bplist',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final currentTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Road Trip'),
    );
    expect(currentTile.enabled, isFalse);
    expect(find.textContaining('当前歌单不可作为移动目标'), findsOneWidget);
  });

  testWidgets('returns selected playlist path when tapped', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await PlaylistPickerDialog.show(
                    context,
                    playlists: _playlists,
                    mode: PlaylistMutationMode.add,
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Focus Set'));
    await tester.pumpAndSettle();

    expect(result, r'D:\BeatSaber\Playlists\focus.bplist');
  });

  testWidgets('supports keyboard down and enter to confirm', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await PlaylistPickerDialog.show(
                    context,
                    playlists: _playlists,
                    mode: PlaylistMutationMode.add,
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(result, r'D:\BeatSaber\Playlists\focus.bplist');
  });
}

const _playlists = <PlaylistWithStatus>[
  PlaylistWithStatus(
    info: PlaylistInfo(
      filePath: r'D:\BeatSaber\Playlists\road.bplist',
      title: 'Road Trip',
      songs: <PlaylistSong>[],
    ),
    songs: <PlaylistSongWithStatus>[],
    matchedCount: 0,
    configuredCount: 0,
  ),
  PlaylistWithStatus(
    info: PlaylistInfo(
      filePath: r'D:\BeatSaber\Playlists\focus.bplist',
      title: 'Focus Set',
      songs: <PlaylistSong>[],
    ),
    songs: <PlaylistSongWithStatus>[],
    matchedCount: 0,
    configuredCount: 0,
  ),
];
