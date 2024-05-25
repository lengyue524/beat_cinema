part of 'config_bloc.dart';

@immutable
sealed class ConfigEvent {}

final class BeatSaberFolderSetted extends ConfigEvent{
  BeatSaberFolderSetted(this.beatSaberPath);
  final String? beatSaberPath;
}

final class LocaleChanged extends ConfigEvent {
  LocaleChanged(this.local);
  final Locale local;
}