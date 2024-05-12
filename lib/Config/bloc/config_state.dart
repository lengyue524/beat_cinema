part of 'config_bloc.dart';

sealed class ConfigState {}

final class ConfigInitial extends ConfigState {
  ConfigInitial(this.beatSaberPath);
  String? beatSaberPath;
}
