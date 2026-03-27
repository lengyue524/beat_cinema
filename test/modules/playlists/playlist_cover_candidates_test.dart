import 'package:beat_cinema/Modules/Playlists/bloc/playlist_bloc.dart';
import 'package:beat_cinema/Modules/Playlists/playlist_cover_candidates.dart';
import 'package:beat_cinema/Services/services/playlist_parse_service.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildPlaylistCoverCandidates filters unavailable and deduplicates', () {
    final levelA = LevelMetadata(
      levelPath: r'D:\Songs\A',
      songName: 'Fallback A',
      coverImageFilename: 'cover.png',
      lastModified: DateTime(2026, 1, 1),
    );
    final levelB = LevelMetadata(
      levelPath: r'D:\Songs\B',
      songName: 'Fallback B',
      coverImageFilename: 'cover-b.png',
      lastModified: DateTime(2026, 1, 1),
    );
    final songs = [
      PlaylistSongWithStatus(
        song: const PlaylistSong(hash: 'h1', key: 'k1', songName: 'Song A'),
        matchedLevel: levelA,
      ),
      PlaylistSongWithStatus(
        song: const PlaylistSong(hash: 'h2', key: 'k2', songName: 'Song A Duplicate'),
        matchedLevel: levelA,
      ),
      PlaylistSongWithStatus(
        song: const PlaylistSong(hash: 'h3', key: 'k3', songName: 'Song B'),
        matchedLevel: levelB,
      ),
      const PlaylistSongWithStatus(
        song: PlaylistSong(hash: 'h4', key: 'k4', songName: 'No Match'),
      ),
    ];

    final candidates = buildPlaylistCoverCandidates(
      songs,
      pathSeparator: r'\',
      fileExists: (filePath) => filePath == r'D:\Songs\A\cover.png',
    );

    expect(candidates.length, 1);
    expect(candidates.first.songName, 'Song A');
    expect(candidates.first.filePath, r'D:\Songs\A\cover.png');
  });
}
