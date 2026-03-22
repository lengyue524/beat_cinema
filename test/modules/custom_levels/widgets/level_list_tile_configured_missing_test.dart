import 'package:beat_cinema/Modules/CustomLevels/widgets/level_list_tile.dart';
import 'package:beat_cinema/models/custom_level/custom_level.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LevelMetadata buildMetadata(VideoConfigStatus status) {
    return LevelMetadata(
      levelPath: r'D:\BeatSaber\CustomLevels\A',
      songName: 'Song A',
      songAuthorName: 'Author A',
      lastModified: DateTime(2026, 1, 1),
      videoStatus: status,
    );
  }

  testWidgets(
      'configured missing file shows download icon and triggers callback',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LevelListTile(
            metadata: buildMetadata(VideoConfigStatus.configuredMissingFile),
            onDownloadConfiguredVideo: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.cloud_download), findsOneWidget);
    await tester.tap(find.byIcon(Icons.cloud_download));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('configured missing file downloading shows progress indicator',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LevelListTile(
            metadata: buildMetadata(VideoConfigStatus.configuredMissingFile),
            configuredVideoDownloading: true,
            onDownloadConfiguredVideo: () {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.cloud_download), findsNothing);
  });

  testWidgets('shows song duration in mm:ss when preview duration exists',
      (tester) async {
    final metadata = LevelMetadata(
      levelPath: r'D:\BeatSaber\CustomLevels\B',
      songName: 'Song B',
      songAuthorName: 'Author B',
      lastModified: DateTime(2026, 1, 1),
      rawLevel: CustomLevel(previewDuration: 125),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LevelListTile(
            metadata: metadata,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.text('02:05'), findsOneWidget);
  });
}
