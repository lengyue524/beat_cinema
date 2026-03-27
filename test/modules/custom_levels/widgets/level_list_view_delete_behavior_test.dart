import 'dart:io';

import 'package:beat_cinema/Modules/CustomLevels/widgets/level_list_view.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LevelMetadata buildMeta({
    required String path,
    required String songName,
  }) {
    return LevelMetadata(
      levelPath: path,
      songName: songName,
      songAuthorName: 'Author',
      lastModified: DateTime(2026, 1, 1),
      videoStatus: VideoConfigStatus.none,
    );
  }

  test('delete confirm message uses fallback content', () {
    final text = buildDeleteSongDirectoriesConfirmMessage(null, 3);
    expect(text, contains('将删除已选 3 个歌曲目录'));
    expect(text, contains('不可恢复'));
  });

  test('deleteSongDirectoriesOnDisk returns partial failure summary', () async {
    final tempRoot = await Directory.systemTemp.createTemp('bc-delete-test-');
    final existingDir = Directory('${tempRoot.path}${Platform.pathSeparator}A')
      ..createSync(recursive: true);
    final missingPath = '${tempRoot.path}${Platform.pathSeparator}B';

    final result = await deleteSongDirectoriesOnDisk([
      buildMeta(path: existingDir.path, songName: 'Song A'),
      buildMeta(path: missingPath, songName: 'Song B'),
    ]);

    expect(result.successCount, 1);
    expect(result.failedCount, 1);
    expect(result.failureSummary, contains('Song B'));
    expect(await existingDir.exists(), isFalse);

    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });
}
