part of 'app_bloc.dart';

@immutable
sealed class AppState {}

final class AppInitial extends AppState {}

final class AppLaunchComplated extends AppState {
  AppLaunchComplated(
    this.local,
    this.beatSaberPath,
    this.cinemaSearchPlatform,
    this.cinemaVideoQuality,
    this.proxyMode,
    this.proxyServer,
  );
  final AppLocal local;
  final String? beatSaberPath;
  final CinemaSearchPlatform cinemaSearchPlatform;
  final CinemaVideoQuality cinemaVideoQuality;
  final ProxyMode proxyMode;
  final String proxyServer;
}
