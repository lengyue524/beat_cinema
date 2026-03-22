part of 'custom_levels_bloc.dart';

@immutable
sealed class CustomLevelsState {}

final class CustomLevelsInitial extends CustomLevelsState {}

final class CustomLevelsLoading extends CustomLevelsState {
  CustomLevelsLoading({
    this.parsed = 0,
    this.total = 0,
    this.stage = CustomLevelsLoadingStage.scanning,
    this.hasCache = false,
    this.cachedLevels = const [],
  });

  final int parsed;
  final int total;
  final CustomLevelsLoadingStage stage;
  final bool hasCache;
  final List<LevelMetadata> cachedLevels;
}

final class CustomLevelsLoaded extends CustomLevelsState {
  CustomLevelsLoaded({
    required this.allLevels,
    required this.filteredLevels,
    this.searchQuery = '',
    this.filter = const FilterCriteria(),
    this.sortField = SortField.songName,
    this.sortDirection = SortDirection.ascending,
  });

  final List<LevelMetadata> allLevels;
  final List<LevelMetadata> filteredLevels;
  final String searchQuery;
  final FilterCriteria filter;
  final SortField sortField;
  final SortDirection sortDirection;

  int get totalCount => allLevels.length;
  int get configuredCount => allLevels
      .where((l) => l.videoStatus == VideoConfigStatus.configured)
      .length;
  int get downloadingCount => allLevels
      .where((l) => l.videoStatus == VideoConfigStatus.downloading)
      .length;
}

final class CustomLevelsError extends CustomLevelsState {
  CustomLevelsError(this.message);
  final String message;
}

enum SortField { songName, songAuthor, bpm, lastModified }

enum SortDirection { ascending, descending }

class FilterCriteria {
  final Set<String> difficulties;
  final Set<VideoConfigStatus> videoStatuses;

  const FilterCriteria({
    this.difficulties = const {},
    this.videoStatuses = const {},
  });

  bool get isEmpty => difficulties.isEmpty && videoStatuses.isEmpty;

  FilterCriteria copyWith({
    Set<String>? difficulties,
    Set<VideoConfigStatus>? videoStatuses,
  }) {
    return FilterCriteria(
      difficulties: difficulties ?? this.difficulties,
      videoStatuses: videoStatuses ?? this.videoStatuses,
    );
  }
}

enum CustomLevelsLoadingStage { scanning, parsing }
