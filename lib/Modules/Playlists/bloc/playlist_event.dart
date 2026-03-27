part of 'playlist_bloc.dart';

@immutable
sealed class PlaylistEvent {}

class LoadPlaylistsEvent extends PlaylistEvent {
  final String beatSaberPath;
  final List<LevelMetadata> levels;
  LoadPlaylistsEvent(this.beatSaberPath, this.levels);
}

class SelectPlaylistEvent extends PlaylistEvent {
  final int index;
  SelectPlaylistEvent(this.index);
}

class DeselectPlaylistEvent extends PlaylistEvent {}

class ToggleFilterUnconfiguredEvent extends PlaylistEvent {}

class ExportPlaylistEvent extends PlaylistEvent {
  final String targetPath;
  ExportPlaylistEvent(this.targetPath);
}

class DownloadMissingSongEvent extends PlaylistEvent {
  final PlaylistSongWithStatus song;
  DownloadMissingSongEvent(this.song);
}

class DownloadTasksUpdatedEvent extends PlaylistEvent {}

class DownloadAllMissingSongsEvent extends PlaylistEvent {
  final bool includeExistingUpdates;
  final bool forceUpdateExisting;

  DownloadAllMissingSongsEvent({
    required this.includeExistingUpdates,
    this.forceUpdateExisting = false,
  });
}

class RetryFailedExportEvent extends PlaylistEvent {}

class DismissExportResultEvent extends PlaylistEvent {}

class RebuildPlaylistHashIndexEvent extends PlaylistEvent {}

class DismissPlaylistRebuildNoticeEvent extends PlaylistEvent {}

class RefreshMatchedLevelEvent extends PlaylistEvent {
  RefreshMatchedLevelEvent(this.levelPath);
  final String levelPath;
}

enum PlaylistMutationMode { add, move }

class DeletePlaylistSongsEvent extends PlaylistEvent {
  DeletePlaylistSongsEvent({
    this.levelPaths = const [],
    this.songIdentities = const [],
    required this.deleteSongDirectories,
  });

  final List<String> levelPaths;
  final List<String> songIdentities;
  final bool deleteSongDirectories;
}

class MutatePlaylistSongsEvent extends PlaylistEvent {
  MutatePlaylistSongsEvent({
    required this.levelPaths,
    required this.targetPlaylistPath,
    required this.mode,
  });

  final List<String> levelPaths;
  final String targetPlaylistPath;
  final PlaylistMutationMode mode;
}

class AddLevelsToPlaylistEvent extends PlaylistEvent {
  AddLevelsToPlaylistEvent({
    required this.levels,
    required this.targetPlaylistPath,
  });

  final List<LevelMetadata> levels;
  final String targetPlaylistPath;
}

class CreatePlaylistEvent extends PlaylistEvent {
  CreatePlaylistEvent({
    required this.title,
  });

  final String title;
}

class UpdatePlaylistCoverEvent extends PlaylistEvent {
  UpdatePlaylistCoverEvent({
    required this.playlistPath,
    required this.imageBase64,
  });

  final String playlistPath;
  final String? imageBase64;
}

class DismissPlaylistActionNoticeEvent extends PlaylistEvent {}
