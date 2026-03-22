import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Modules/CinemaSearch/bloc/cinema_search_bloc.dart';
import 'package:beat_cinema/Services/managers/download_manager.dart';
import 'package:beat_cinema/Services/services/proxy_service.dart';
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
  ProxyMode proxyMode = ProxyMode.system;
  String proxyServer = '';
  DownloadManager? downloadManager;

  AppBloc() : super(AppInitial()) {
    on<AppLoadComplatedEvent>((event, emit) {
      log.i(
        '[AppBloc] load completed local=${event.local.name} '
        'beatSaberPath=${event.beatSaberPath}',
      );
      appLocal = event.local;
      beatSaberPath = event.beatSaberPath;
      cinemaSearchPlatform = event.cinemaSearchPlatform;
      cinemaVideoQuality = event.cinemaVideoQuality;
      _rebuildDownloadManager();
      emit(AppLaunchComplated(
        appLocal,
        beatSaberPath,
        cinemaSearchPlatform,
        cinemaVideoQuality,
        proxyMode,
        proxyServer,
      ));
    });
    on<AppLocalUpdateEvent>((event, emit) {
      log.i('[AppBloc] local updated ${event.local.name}');
      appLocal = event.local;
      saveAppLocal(appLocal);
      emit(AppLaunchComplated(
        appLocal,
        beatSaberPath,
        cinemaSearchPlatform,
        cinemaVideoQuality,
        proxyMode,
        proxyServer,
      ));
    });
    on<AppBeatSaverPathUpdateEvent>((event, emit) {
      log.i('[AppBloc] Beat Saber path updated path=${event.beatSaberPath}');
      beatSaberPath = event.beatSaberPath;
      saveAppBeatSaberPath(beatSaberPath);
      _rebuildDownloadManager();
      emit(AppLaunchComplated(
        appLocal,
        beatSaberPath,
        cinemaSearchPlatform,
        cinemaVideoQuality,
        proxyMode,
        proxyServer,
      ));
    });
    on<AppCinemaSearchPlatformUpdateEvent>((event, emit) {
      log.i(
          '[AppBloc] search platform updated ${event.cinemaSearchPlatform.name}');
      cinemaSearchPlatform = event.cinemaSearchPlatform;
      saveCinemaSearchPlatform(cinemaSearchPlatform);
      emit(AppLaunchComplated(
        appLocal,
        beatSaberPath,
        cinemaSearchPlatform,
        cinemaVideoQuality,
        proxyMode,
        proxyServer,
      ));
    });
    on<AppCinemaVideoQualityUpdateEvent>((event, emit) {
      log.i('[AppBloc] video quality updated ${event.cinemaVideoQuality.name}');
      cinemaVideoQuality = event.cinemaVideoQuality;
      saveCinemaVideoQuality(cinemaVideoQuality);
      emit(AppLaunchComplated(
        appLocal,
        beatSaberPath,
        cinemaSearchPlatform,
        cinemaVideoQuality,
        proxyMode,
        proxyServer,
      ));
    });
    on<AppProxyModeUpdateEvent>((event, emit) {
      log.i('[AppBloc] proxy mode updated ${event.proxyMode.name}');
      proxyMode = event.proxyMode;
      saveProxyMode(proxyMode);
      _rebuildDownloadManager();
      emit(AppLaunchComplated(
        appLocal,
        beatSaberPath,
        cinemaSearchPlatform,
        cinemaVideoQuality,
        proxyMode,
        proxyServer,
      ));
    });
    on<AppProxyServerUpdateEvent>((event, emit) {
      log.i('[AppBloc] proxy server updated');
      proxyServer = event.proxyServer.trim();
      saveProxyServer(proxyServer);
      _rebuildDownloadManager();
      emit(AppLaunchComplated(
        appLocal,
        beatSaberPath,
        cinemaSearchPlatform,
        cinemaVideoQuality,
        proxyMode,
        proxyServer,
      ));
    });
  }

  static Future<void> loadAppConfig(AppBloc bloc) async {
    log.i('[AppBloc] loading app config from shared preferences');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? local = prefs.getString(Constants.sharedPreferencesAppLocal);
    final String? beatSaberPath =
        prefs.getString(Constants.sharedPreferencesBeatSaberPath);
    final String? cinemaSearchPlatformStr =
        prefs.getString(Constants.sharedPreferencesCinemaSearchPlatform);
    final String? cinemaVideoQualityStr =
        prefs.getString(Constants.sharedPreferencesCinemaVideoQuality);
    final String? proxyModeStr =
        prefs.getString(Constants.sharedPreferencesProxyMode);
    final String? proxyServer =
        prefs.getString(Constants.sharedPreferencesProxyServer);

    AppLocal appLocal;
    CinemaSearchPlatform cinemaSearchPlatform;
    CinemaVideoQuality cinemaVideoQuality;
    ProxyMode proxyMode;

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

    try {
      proxyMode = proxyModeStr != null
          ? ProxyMode.values.byName(proxyModeStr)
          : ProxyMode.system;
    } catch (_) {
      proxyMode = ProxyMode.system;
    }

    bloc.proxyMode = proxyMode;
    bloc.proxyServer = (proxyServer ?? '').trim();
    log.i(
      '[AppBloc] config loaded local=${appLocal.name} '
      'path=$beatSaberPath proxyMode=${proxyMode.name}',
    );

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

  void saveProxyMode(ProxyMode mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.sharedPreferencesProxyMode, mode.name);
  }

  void saveProxyServer(String server) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.sharedPreferencesProxyServer, server);
  }

  void _rebuildDownloadManager() {
    log.i('[AppBloc] rebuild download manager path=$beatSaberPath');
    downloadManager?.dispose();
    if (beatSaberPath == null || beatSaberPath!.trim().isEmpty) {
      log.w('[AppBloc] download manager disabled because path is empty');
      downloadManager = null;
      return;
    }
    downloadManager = DownloadManager(
      YtDlpService(
        beatSaberPath: beatSaberPath!,
        proxyMode: proxyMode,
        customProxy: proxyServer,
      ),
    );
  }
}
