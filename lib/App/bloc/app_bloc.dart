import 'package:beat_cinema/Common/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(AppInitial()) {
    on<AppLoadComplatedEvent>((event, emit) {
      emit(AppLaunchComplated(event.local));
    });
  }

  static void loadAppLocal(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? local = prefs.getString(Constants.sharedPreferencesAppLocal);
    AppLocal appLocal;
    if (local != null) {
      appLocal = AppLocal.values.byName(local);
    } else {
      appLocal = AppLocal.en;
    }
    if (context.mounted) {
      context.read<AppBloc>().add(AppLoadComplatedEvent(appLocal));
    }
  }

  static void saveAppLocal(AppLocal local) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.sharedPreferencesAppLocal, local.name);
  }
}
