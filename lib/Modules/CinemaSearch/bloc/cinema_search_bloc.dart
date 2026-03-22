import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Services/services/proxy_service.dart';
import 'package:beat_cinema/models/dlp_video_info/dlp_video_info.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'cinema_search_event.dart';
part 'cinema_search_state.dart';

enum CinemaSearchPlatform { bilibili, youtube }

enum CinemaVideoQuality { q1080p, q720p, q480p }

extension CinemaVideoQualityExt on CinemaVideoQuality {
  int toValue() {
    switch (this) {
      case CinemaVideoQuality.q1080p:
        return 1080;
      case CinemaVideoQuality.q720p:
        return 720;
      case CinemaVideoQuality.q480p:
        return 480;
    }
  }

  String toName() {
    switch (this) {
      case CinemaVideoQuality.q1080p:
        return "1080p";
      case CinemaVideoQuality.q720p:
        return "720p";
      case CinemaVideoQuality.q480p:
        return "480p";
    }
  }
}

class CinemaSearchBloc extends Bloc<CinemaSearchEvent, CinemaSearchState> {
  Isolate? currentIsolate;
  CinemaSearchBloc() : super(CinemaSearchInitial()) {
    on<CinameSearchTextEvent>((event, emit) async {
      emit(CinemaSearchLoading());
      killIsolate();
      await searchCinema(event.searchText, event.count, event.appBloc, emit);
    });
  }

  Future<void> searchCinema(String text, int count, AppBloc appBloc,
      Emitter<CinemaSearchState> emit) async {
    if (appBloc.beatSaberPath == null) {
      return;
    }
    final proxyUrl = await ProxyService.resolveProxyUrl(
      mode: appBloc.proxyMode,
      customProxy: appBloc.proxyServer,
    );
    log.i(
      '[CinemaSearchBloc] search start query="$text" '
      'platform=${appBloc.cinemaSearchPlatform.name} '
      'proxyMode=${appBloc.proxyMode.name} '
      'proxyApplied=${proxyUrl != null && proxyUrl.isNotEmpty}',
    );
    ReceivePort receivePort = ReceivePort();
    List<DlpVideoInfo> videoInfos = List.empty(growable: true);
    String jsonStr = "";
    Completer comp = Completer();
    receivePort.listen((value) {
      String newValueStr = String.fromCharCodes(value);
      if (newValueStr == Constants.sendPortDoneString) {
        // log.info("搜索完成");
        killIsolate();
        comp.complete();
        return;
      }
      jsonStr += newValueStr;
      final splitJson = jsonStr.split("\n");
      for (var json in splitJson) {
        try {
          final videoInfo = DlpVideoInfo.fromJson(json);
          videoInfos.add(videoInfo);
          // log.info("已搜索：${videoInfos.length}, ${videoInfo.title}");
          emit(CinemaSearchLoaded(videoInfos: videoInfos));
          jsonStr.replaceFirst("$json\n", "");
          jsonStr = jsonStr.substring(json.length);
        } catch (e) {
          // log.info(json);
          // log.info(e.toString());
        }
      }
    }, onDone: () {
      receivePort.close();
      killIsolate();
      comp.complete();
    }, onError: (e) {
      receivePort.close();
      killIsolate();
      comp.complete();
    });
    currentIsolate = await Isolate.spawn(
        _searchCinemaWithYTDlp,
        CinameSearchParams(
            text: text,
            count: count,
            beatSaberPath: appBloc.beatSaberPath!,
            cinemaSearchPlatform: appBloc.cinemaSearchPlatform,
            proxyUrl: proxyUrl,
            sendport: receivePort.sendPort),
        debugName: text);
    await comp.future;
    // await compute(
    //     _searchCinemaWithYTDlp,
    //     CinameSearchParams(
    //         text: text,
    //         count: count,
    //         beatSaberPath: appBloc.beatSaberPath!,
    //         cinemaSearchPlatform: appBloc.cinemaSearchPlatform,
    //         sendport: receivePort.sendPort),
    //         debugLabel: text);
    // await comp.future;
    // pr.stdout.pipe(outStream);
    // stdout.addStream(pr.stdout);
    // String searchError = pr.stderr as String;
    // log.info(searchResultStr);
    // log.shout(searchError);
  }

  void killIsolate() {
    currentIsolate?.kill();
    currentIsolate = null;
  }

  static void _searchCinemaWithYTDlp(CinameSearchParams params) async {
    String dlpPath =
        "${params.beatSaberPath}${Platform.pathSeparator}${Constants.libsDir}${Platform.pathSeparator}${Constants.ytDlpName}";
    final args = buildSearchArgs(
      platform: params.cinemaSearchPlatform,
      count: params.count,
      text: params.text,
      proxyUrl: params.proxyUrl,
    );
    Completer comp = Completer();
    Process pr = await Process.start(dlpPath, args);
    pr.stdout.listen((value) {
      params.sendport.send(value);
    }, onDone: () {
      params.sendport.send(Constants.sendPortDoneString.codeUnits);
      comp.complete();
    });
    await comp.future;
  }

  @visibleForTesting
  static List<String> buildSearchArgs({
    required CinemaSearchPlatform platform,
    required int count,
    required String text,
    String? proxyUrl,
  }) {
    String searchStr = "";
    switch (platform) {
      case CinemaSearchPlatform.youtube:
        searchStr = "ytsearch$count:$text";
        break;
      case CinemaSearchPlatform.bilibili:
        searchStr = "bilisearch$count:$text";
        break;
    }
    final args = <String>[];
    final resolvedProxy = (proxyUrl ?? '').trim();
    if (resolvedProxy.isNotEmpty) {
      args.addAll(['--proxy', resolvedProxy]);
    }
    args.addAll([searchStr, '-j']);
    return args;
  }

  @override
  Future<void> close() {
    killIsolate();
    return super.close();
  }
}

class CinameSearchParams {
  final String text;
  final int count;
  final String beatSaberPath;
  final CinemaSearchPlatform cinemaSearchPlatform;
  final String? proxyUrl;
  final SendPort sendport;

  CinameSearchParams(
      {required this.text,
      required this.count,
      required this.beatSaberPath,
      required this.cinemaSearchPlatform,
      this.proxyUrl,
      required this.sendport});
}
