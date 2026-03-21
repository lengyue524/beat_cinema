import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Modules/CinemaSearch/bloc/cinema_search_bloc.dart';
import 'package:beat_cinema/Services/managers/download_manager.dart';
import 'package:beat_cinema/Services/services/ytdlp_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppLocal appLocal = AppLocal.en;
  String? beatSaberPath;
  CinemaSearchPlatform cinemaSearchPlatform = CinemaSearchPlatform.youtube;
  CinemaVideoQuality cinemaVideoQuality = CinemaVideoQuality.q720p;
  DownloadManager? downloadManager;

  AppBloc() : super(AppInitial()) {
    on<AppLoadComplatedEvent>((event, emit) {
      appLocal = event.local;
      beatSaberPath = event.beatSaberPath;
      cinemaSearchPlatform = event.cinemaSearchPlatform;
      cinemaVideoQuality = event.cinemaVideoQuality;
      _rebuildDownloadManager();
      emit(AppLaunchComplated(
          appLocal, beatSaberPath, cinemaSearchPlatform, cinemaVideoQuality));
    });
    on<AppLocalUpdateEvent>((event, emit) {
      appLocal = event.local;
      saveAppLocal(appLocal);
      emit(AppLaunchComplated(
          appLocal, beatSaberPath, cinemaSearchPlatform, cinemaVideoQuality));
    });
    on<AppBeatSaverPathUpdateEvent>((event, emit) {
      beatSaberPath = event.beatSaberPath;
      saveAppBeatSaberPath(beatSaberPath);
      _rebuildDownloadManager();
      emit(AppLaunchComplated(
          appLocal, beatSaberPath, cinemaSearchPlatform, cinemaVideoQuality));
    });
    on<AppCinemaSearchPlatformUpdateEvent>((event, emit) {
      cinemaSearchPlatform = event.cinemaSearchPlatform;
      saveCinemaSearchPlatform(cinemaSearchPlatform);
      emit(AppLaunchComplated(
          appLocal, beatSaberPath, cinemaSearchPlatform, cinemaVideoQuality));
    });
    on<AppCinemaVideoQualityUpdateEvent>((event, emit) {
      cinemaVideoQuality = event.cinemaVideoQuality;
      saveCinemaVideoQuality(cinemaVideoQuality);
      emit(AppLaunchComplated(
          appLocal, beatSaberPath, cinemaSearchPlatform, cinemaVideoQuality));
    });
  }

  static Future<void> loadAppConfig(AppBloc bloc) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? local = prefs.getString(Constants.sharedPreferencesAppLocal);
    final String? beatSaberPath =
        prefs.getString(Constants.sharedPreferencesBeatSaberPath);
    final String? cinemaSearchPlatformStr =
        prefs.getString(Constants.sharedPreferencesCinemaSearchPlatform);
    final String? cinemaVideoQualityStr =
        prefs.getString(Constants.sharedPreferencesCinemaVideoQuality);

    AppLocal appLocal;
    CinemaSearchPlatform cinemaSearchPlatform;
    CinemaVideoQuality cinemaVideoQuality;

    try {
      appLocal = local != null ? AppLocal.values.byName(local) : AppLocal.en;
    } catch (_) {
      appLocal = AppLocal.en;
    }

    try {
      cinemaSearchPlatform = cinemaSearchPlatformStr != null
          ? CinemaSearchPlatform.values.byName(cinemaSearchPlatformStr)
          : CinemaSearchPlatform.youtube;
    } catch (_) {
      cinemaSearchPlatform = CinemaSearchPlatform.youtube;
    }

    try {
      cinemaVideoQuality = cinemaVideoQualityStr != null
          ? CinemaVideoQuality.values.byName(cinemaVideoQualityStr)
          : CinemaVideoQuality.q720p;
    } catch (_) {
      cinemaVideoQuality = CinemaVideoQuality.q720p;
    }

    bloc.add(AppLoadComplatedEvent(
        appLocal, beatSaberPath, cinemaSearchPlatform, cinemaVideoQuality));
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
      await prefs.setString(
          Constants.sharedPreferencesBeatSaberPath, beatSaberPath);
    }
  }

  void saveCinemaSearchPlatform(
      CinemaSearchPlatform cinemaSearchPlatform) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.sharedPreferencesCinemaSearchPlatform,
        cinemaSearchPlatform.name);
  }

  void saveCinemaVideoQuality(CinemaVideoQuality cinemaVideoQuality) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        Constants.sharedPreferencesCinemaVideoQuality, cinemaVideoQuality.name);
  }

  void _rebuildDownloadManager() {
    downloadManager?.dispose();
    if (beatSaberPath == null || beatSaberPath!.trim().isEmpty) {
      downloadManager = null;
      return;
    }
    downloadManager = DownloadManager(
      YtDlpService(beatSaberPath: beatSaberPath!),
    );
  }
}
