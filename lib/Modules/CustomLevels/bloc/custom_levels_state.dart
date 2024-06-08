part of 'custom_levels_bloc.dart';

@immutable
sealed class CustomLevelsState {}

final class CustomLevelsInitial extends CustomLevelsState {}

final class CustomLevelsLoaded extends CustomLevelsState {
  CustomLevelsLoaded(this.levels);
  final List<LevelInfo> levels;
}
