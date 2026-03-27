import 'package:beat_cinema/Modules/Playlists/playlist_cover_candidates.dart';
import 'package:beat_cinema/Modules/Playlists/widgets/playlist_cover_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('returns selected file path when tapped', (tester) async {
    PlaylistCoverPickerResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await PlaylistCoverPickerDialog.show(
                    context,
                    candidates: _candidates,
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
    await tester.tap(find.byKey(const ValueKey('playlist-cover-item-1')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.clearRequested, isFalse);
    expect(result!.filePath, r'D:\covers\b.png');
  });

  testWidgets('returns clear action when tapped clear button', (tester) async {
    PlaylistCoverPickerResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await PlaylistCoverPickerDialog.show(
                    context,
                    candidates: _candidates,
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
    await tester.tap(find.text('清除封面'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.clearRequested, isTrue);
    expect(result!.filePath, isNull);
  });
}

const _candidates = <PlaylistCoverCandidate>[
  PlaylistCoverCandidate(
    songName: 'Song A',
    filePath: r'D:\covers\a.png',
  ),
  PlaylistCoverCandidate(
    songName: 'Song B',
    filePath: r'D:\covers\b.png',
  ),
];
