part of 'app_bloc.dart';

enum AppLocal { en, zh }

@immutable
sealed class AppEvent {}

final class AppLoadComplatedEvent extends AppEvent {
  AppLoadComplatedEvent(this.local, this.beatSaberPath,this.cinemaSearchPlatform);
  final AppLocal local;
  final String? beatSaberPath;
  final CinemaSearchPlatform cinemaSearchPlatform;
}

final class AppLocalUpdateEvent extends AppEvent {
  AppLocalUpdateEvent(this.local);
  final AppLocal local;
}

final class AppBeatSaverPathUpdateEvent extends AppEvent {
  AppBeatSaverPathUpdateEvent(this.beatSaberPath);
  final String? beatSaberPath;
}

final class AppCinemaSearchPlatformUpdateEvent extends AppEvent {
  AppCinemaSearchPlatformUpdateEvent(this.cinemaSearchPlatform);
  final CinemaSearchPlatform cinemaSearchPlatform;
}