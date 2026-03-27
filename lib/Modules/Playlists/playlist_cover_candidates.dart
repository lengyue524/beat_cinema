import 'dart:io';

import 'package:beat_cinema/Modules/Playlists/bloc/playlist_bloc.dart';

class PlaylistCoverCandidate {
  const PlaylistCoverCandidate({
    required this.songName,
    required this.filePath,
  });

  final String songName;
  final String filePath;
}

List<PlaylistCoverCandidate> buildPlaylistCoverCandidates(
  List<PlaylistSongWithStatus> songs, {
  required bool Function(String filePath) fileExists,
  String? pathSeparator,
}) {
  final separator = pathSeparator ?? Platform.pathSeparator;
  final candidates = <PlaylistCoverCandidate>[];
  final seen = <String>{};
  for (final song in songs) {
    final level = song.matchedLevel;
    if (level == null) continue;
    final coverName = (level.coverImageFilename ?? '').trim();
    if (coverName.isEmpty) continue;
    final path = '${level.levelPath}$separator$coverName';
    if (!fileExists(path)) continue;
    final normalized = path.trim().toLowerCase();
    if (normalized.isEmpty || !seen.add(normalized)) continue;
    final title = (song.song.songName ?? '').trim().isNotEmpty
        ? song.song.songName!.trim()
        : level.songName;
    candidates.add(PlaylistCoverCandidate(songName: title, filePath: path));
  }
  return candidates;
}
