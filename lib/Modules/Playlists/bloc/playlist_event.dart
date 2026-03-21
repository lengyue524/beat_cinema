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
