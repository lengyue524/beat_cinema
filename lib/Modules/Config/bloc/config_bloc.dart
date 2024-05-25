import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

part 'config_event.dart';
part 'config_state.dart';

class ConfigBloc extends Bloc<ConfigEvent, ConfigInitial> {
  ConfigBloc() : super(ConfigInitial("")) {
    on<BeatSaberFolderSetted>((event, emit) async {
      emit(ConfigInitial(event.beatSaberPath));
    });
  }
}
