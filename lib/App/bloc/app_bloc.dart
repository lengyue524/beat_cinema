import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Modules/CinemaSearch/bloc/cinema_search_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(AppInitial()) {
    AppLocal appLocal = AppLocal.en;
    String? beatSaberPath;
    CinemaSearchPlatform cinemaSearchPlatform = CinemaSearchPlatform.youtube;
    on<AppLoadComplatedEvent>((event, emit) {
      appLocal = event.local;
      beatSaberPath = event.beatSaberPath;
      cinemaSearchPlatform = event.cinemaSearchPlatform;
      emit(AppLaunchComplated(appLocal, beatSaberPath, cinemaSearchPlatform));
    });
    on<AppLocalUpdateEvent>((event, emit) {
      appLocal = event.local;
      saveAppLocal(appLocal);
      emit(AppLaunchComplated(appLocal, beatSaberPath, cinemaSearchPlatform));
    });
    on<AppBeatSaverPathUpdateEvent>((event, emit) {
      beatSaberPath = event.beatSaberPath;
      saveAppBeatSaberPath(beatSaberPath);
      emit(AppLaunchComplated(appLocal, beatSaberPath, cinemaSearchPlatform));
    });
    on<AppCinemaSearchPlatformUpdateEvent>((event, emit) {
      cinemaSearchPlatform = event.cinemaSearchPlatform;
      saveCinemaSearchPlatform(cinemaSearchPlatform);
      emit(AppLaunchComplated(appLocal, beatSaberPath, cinemaSearchPlatform));
    });
  }

  static void loadAppConfig(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? local = prefs.getString(Constants.sharedPreferencesAppLocal);
    final String? beatSaberPath = prefs.getString(Constants.sharedPreferencesBeatSaberPath);
    final String? cinemaSearchPlatformStr = prefs.getString(Constants.sharedPreferencesCinemaSearchPlatform);
    AppLocal appLocal;
    CinemaSearchPlatform cinemaSearchPlatform;
    if (local != null) {
      appLocal = AppLocal.values.byName(local);
    } else {
      appLocal = AppLocal.en;
    }
    if (cinemaSearchPlatformStr == null) {
      cinemaSearchPlatform = CinemaSearchPlatform.youtube;
    } else {
      cinemaSearchPlatform = CinemaSearchPlatform.values.byName(cinemaSearchPlatformStr);
    }
    if (context.mounted) {
      context.read<AppBloc>().add(AppLoadComplatedEvent(appLocal, beatSaberPath, cinemaSearchPlatform));
    }
  }

  void saveAppLocal(AppLocal local) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.sharedPreferencesAppLocal, local.name);
  }

  void saveAppBeatSaberPath(String? beatSaberPath) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (beatSaberPath == null) {
      await prefs.remove(Constants.sharedPreferencesBeatSaberPath);
    } else {
      await prefs.setString(Constants.sharedPreferencesBeatSaberPath, beatSaberPath);
    }
  }

  void saveCinemaSearchPlatform(CinemaSearchPlatform cinemaSearchPlatform) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.sharedPreferencesCinemaSearchPlatform, cinemaSearchPlatform.name);
  }
}
