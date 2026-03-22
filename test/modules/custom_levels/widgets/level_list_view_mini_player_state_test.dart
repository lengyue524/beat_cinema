import 'package:beat_cinema/Modules/CustomLevels/widgets/level_list_view.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

LevelMetadata _meta({
  required String levelPath,
  required String songName,
  String? coverImageFilename,
}) {
  return LevelMetadata(
    levelPath: levelPath,
    songName: songName,
    coverImageFilename: coverImageFilename,
    lastModified: DateTime.now(),
  );
}

void main() {
  test('returns null when not playing', () {
    final data = resolveMiniPlayerDisplayData(
      previewPlaying: false,
      playingLevelPath: 'A',
      items: const [],
    );

    expect(data, isNull);
  });

  test('uses current list metadata when playing item exists', () {
    final items = <LevelListItem>[
      LevelListItem.level(
        _meta(
          levelPath: 'A',
          songName: 'Song A',
          coverImageFilename: 'cover.png',
        ),
      ),
    ];

    final data = resolveMiniPlayerDisplayData(
      previewPlaying: true,
      playingLevelPath: 'A',
      items: items,
      fallbackSongName: 'Fallback',
      fallbackCoverFilePath: 'fallback.png',
    );

    expect(data, isNotNull);
    expect(data!.songName, 'Song A');
    expect(data.coverFilePath, contains('cover.png'));
  });

  test('falls back to cached metadata when item filtered out', () {
    final items = <LevelListItem>[
      LevelListItem.level(
        _meta(levelPath: 'B', songName: 'Song B'),
      ),
    ];

    final data = resolveMiniPlayerDisplayData(
      previewPlaying: true,
      playingLevelPath: 'A',
      items: items,
      fallbackSongName: 'Cached Song',
      fallbackCoverFilePath: 'C:/covers/cached.png',
    );

    expect(data, isNotNull);
    expect(data!.songName, 'Cached Song');
    expect(data.coverFilePath, 'C:/covers/cached.png');
  });
}
