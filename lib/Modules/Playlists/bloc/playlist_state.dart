part of 'playlist_bloc.dart';

@immutable
sealed class PlaylistState {}

final class PlaylistInitial extends PlaylistState {}

final class PlaylistLoading extends PlaylistState {}

final class PlaylistLoaded extends PlaylistState {
  final List<PlaylistWithStatus> playlists;
  final int? selectedIndex;
  final bool filterUnconfigured;
  final bool exporting;
  final double exportProgress;
  final ExportResult? exportResult;

  PlaylistLoaded({
    required this.playlists,
    this.selectedIndex,
    this.filterUnconfigured = false,
    this.exporting = false,
    this.exportProgress = 0,
    this.exportResult,
  });

  PlaylistWithStatus? get selectedPlaylist =>
      selectedIndex != null ? playlists[selectedIndex!] : null;
}

class ExportFailureItem {
  final String songName;
  final String hash;
  final String reason;
  final DateTime timestamp;
  final String? levelPath;

  const ExportFailureItem({
    required this.songName,
    required this.hash,
    required this.reason,
    required this.timestamp,
    this.levelPath,
  });

  Map<String, dynamic> toMap() => {
        'songName': songName,
        'hash': hash,
        'reason': reason,
        'timestamp': timestamp.toIso8601String(),
        'levelPath': levelPath,
      };
}

class ExportResult {
  final int successCount;
  final int failedCount;
  final String targetPath;
  final String? failureReportPath;
  final List<ExportFailureItem> failures;

  const ExportResult({
    required this.successCount,
    required this.failedCount,
    required this.targetPath,
    this.failureReportPath,
    this.failures = const [],
  });
}

final class PlaylistError extends PlaylistState {
  final String message;
  PlaylistError(this.message);
}

class PlaylistWithStatus {
  final PlaylistInfo info;
  final List<PlaylistSongWithStatus> songs;
  final int matchedCount;
  final int configuredCount;

  const PlaylistWithStatus({
    required this.info,
    required this.songs,
    required this.matchedCount,
    required this.configuredCount,
  });
}

class PlaylistSongWithStatus {
  final PlaylistSong song;
  final LevelMetadata? matchedLevel;
  final bool downloading;
  final String? downloadError;

  const PlaylistSongWithStatus({
    required this.song,
    this.matchedLevel,
    this.downloading = false,
    this.downloadError,
  });

  bool get isMissingDownload => matchedLevel == null && !downloading;
  bool get isMissingConfig =>
      matchedLevel != null && matchedLevel!.cinemaConfig == null;
}
