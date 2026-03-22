part of 'app_bloc.dart';

enum AppLocal { en, zh }

@immutable
sealed class AppEvent {}

final class AppLoadComplatedEvent extends AppEvent {
  AppLoadComplatedEvent(this.local, this.beatSaberPath,
      this.cinemaSearchPlatform, this.cinemaVideoQuality);
  final AppLocal local;
  final String? beatSaberPath;
  final CinemaSearchPlatform cinemaSearchPlatform;
  final CinemaVideoQuality cinemaVideoQuality;
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

final class AppCinemaVideoQualityUpdateEvent extends AppEvent {
  final CinemaVideoQuality cinemaVideoQuality;
  AppCinemaVideoQualityUpdateEvent(this.cinemaVideoQuality);
}

final class AppProxyModeUpdateEvent extends AppEvent {
  AppProxyModeUpdateEvent(this.proxyMode);
  final ProxyMode proxyMode;
}

final class AppProxyServerUpdateEvent extends AppEvent {
  AppProxyServerUpdateEvent(this.proxyServer);
  final String proxyServer;
}
