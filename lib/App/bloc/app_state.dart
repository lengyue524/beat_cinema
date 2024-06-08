part of 'app_bloc.dart';

@immutable
sealed class AppState {}

final class AppInitial extends AppState {}

final class AppLaunchComplated extends AppState {
  AppLaunchComplated(this.local, this.beatSaberPath, this.cinemaSearchPlatform);
  final AppLocal local;
  final String? beatSaberPath;
  final CinemaSearchPlatform cinemaSearchPlatform;
}
