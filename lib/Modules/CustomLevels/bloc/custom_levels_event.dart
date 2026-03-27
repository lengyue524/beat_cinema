part of 'custom_levels_bloc.dart';

@immutable
sealed class CustomLevelsEvent {}

class ReloadCustomLevelsEvent extends CustomLevelsEvent {
  ReloadCustomLevelsEvent(this.beatSaberPath);
  final String beatSaberPath;
}

class RefreshSingleLevelEvent extends CustomLevelsEvent {
  RefreshSingleLevelEvent(this.levelPath);
  final String levelPath;
}

class RemoveLevelsEvent extends CustomLevelsEvent {
  RemoveLevelsEvent(this.levelPaths);
  final List<String> levelPaths;
}

class LoadCachedCustomLevelsEvent extends CustomLevelsEvent {}

class SearchQueryChanged extends CustomLevelsEvent {
  SearchQueryChanged(this.query);
  final String query;
}

class FilterChanged extends CustomLevelsEvent {
  FilterChanged(this.criteria);
  final FilterCriteria criteria;
}

class SortChanged extends CustomLevelsEvent {
  SortChanged(this.field, this.direction);
  final SortField field;
  final SortDirection direction;
}
