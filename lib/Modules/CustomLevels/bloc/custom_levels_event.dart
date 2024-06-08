part of 'custom_levels_bloc.dart';

@immutable
sealed class CustomLevelsEvent {}

class ReloadCustomLevelsEvent extends CustomLevelsEvent {
  ReloadCustomLevelsEvent(this.beatSaberPath);
  final String beatSaberPath;
}

class LoadCachedCustomLevelsEvent extends CustomLevelsEvent {}

class FilterCustomLevelsEvent extends CustomLevelsEvent {
  FilterCustomLevelsEvent(this.seatchText);
  final String seatchText;
}
