import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Services/repositories/video_repository.dart';
import 'package:beat_cinema/Services/services/bbdown_service.dart';
import 'package:beat_cinema/Services/services/proxy_service.dart';
import 'package:beat_cinema/Services/services/ytdlp_service.dart';
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
  int _activeRequestId = 0;
  static const Duration _searchResultCacheTtl = Duration(minutes: 3);
  final Map<String, _CachedSearchResults> _searchResultCache =
      <String, _CachedSearchResults>{};

  CinemaSearchBloc() : super(CinemaSearchInitial()) {
    on<CinameSearchTextEvent>((event, emit) async {
      final requestId = ++_activeRequestId;
      emit(CinemaSearchLoading());
      killIsolate();
      await searchCinema(
        event.searchText,
        event.count,
        event.appBloc,
        emit,
        requestId: requestId,
      );
    });
  }

  Future<void> searchCinema(String text, int count, AppBloc appBloc,
      Emitter<CinemaSearchState> emit,
      {required int requestId}) async {
    if (appBloc.beatSaberPath == null) {
      return;
    }
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      if (_isRequestActive(requestId)) {
        emit(CinemaSearchLoaded(videoInfos: const []));
      }
      return;
    }
    final proxyUrl = await ProxyService.resolveProxyUrl(
      mode: appBloc.proxyMode,
      customProxy: appBloc.proxyServer,
    );
    if (!_isRequestActive(requestId)) return;
    final cacheKey = buildSearchCacheKey(
      platform: appBloc.cinemaSearchPlatform,
      count: count,
      text: normalizedText,
      proxyUrl: proxyUrl,
    );
    log.i(
      '[CinemaSearchBloc] search start query="$normalizedText" '
      'platform=${appBloc.cinemaSearchPlatform.name} '
      'proxyMode=${appBloc.proxyMode.name} '
      'proxyApplied=${proxyUrl != null && proxyUrl.isNotEmpty}',
    );
    final useBbDown = appBloc.cinemaSearchPlatform == CinemaSearchPlatform.bilibili &&
        await BbDownService.isInstalled(appBloc.beatSaberPath!);
    if (!_isRequestActive(requestId)) return;
    if (useBbDown) {
      log.i('[CinemaSearchBloc] search engine=bbdown platform=bilibili');
      try {
        final service = BbDownService(
          beatSaberPath: appBloc.beatSaberPath!,
          proxyMode: appBloc.proxyMode,
          customProxy: appBloc.proxyServer,
        );
        final results = await service.search(normalizedText, count: count);
        if (!_isRequestActive(requestId)) return;
        if (results.isNotEmpty) {
          _saveSearchCache(cacheKey, results);
          emit(CinemaSearchLoaded(videoInfos: List.unmodifiable(results)));
          return;
        }
        log.w(
          '[CinemaSearchBloc] bbdown empty result, retry once '
          'query="$normalizedText"',
        );
        final retryResults = await service.search(normalizedText, count: count);
        if (!_isRequestActive(requestId)) return;
        if (retryResults.isNotEmpty) {
          _saveSearchCache(cacheKey, retryResults);
          emit(CinemaSearchLoaded(videoInfos: List.unmodifiable(retryResults)));
          return;
        }
        log.w(
          '[CinemaSearchBloc] bbdown retry empty, fallback to ytdlp '
          'query="$normalizedText"',
        );
      } catch (e, st) {
        log.w(
            '[CinemaSearchBloc] bilibili search failed query="$normalizedText"',
            e,
            st);
        if (!_isRequestActive(requestId)) return;
        log.w(
          '[CinemaSearchBloc] bbdown failed, fallback to ytdlp '
          'query="$normalizedText"',
        );
      }
    }
    if (appBloc.cinemaSearchPlatform == CinemaSearchPlatform.bilibili) {
      final reason = useBbDown ? 'bbdown_empty_or_failed' : 'bbdown_not_installed';
      log.w('[CinemaSearchBloc] search engine=ytdlp platform=bilibili reason=$reason');
    } else {
      log.i('[CinemaSearchBloc] search engine=ytdlp platform=youtube');
    }
    final videoInfos = await _searchWithYtDlpIsolate(
      text: normalizedText,
      count: count,
      beatSaberPath: appBloc.beatSaberPath!,
      platform: appBloc.cinemaSearchPlatform,
      proxyUrl: proxyUrl,
      emit: emit,
      requestId: requestId,
    );
    if (!_isRequestActive(requestId)) return;
    if (videoInfos.isNotEmpty) {
      _saveSearchCache(cacheKey, videoInfos);
      return;
    }
    if (videoInfos.isEmpty) {
      log.w(
        '[CinemaSearchBloc] empty result on first attempt, retry once '
        'query="$normalizedText" platform=${appBloc.cinemaSearchPlatform.name}',
      );
      final retry = await _searchWithYtDlpIsolate(
        text: normalizedText,
        count: count,
        beatSaberPath: appBloc.beatSaberPath!,
        platform: appBloc.cinemaSearchPlatform,
        proxyUrl: proxyUrl,
        emit: emit,
        requestId: requestId,
      );
      if (!_isRequestActive(requestId)) return;
      if (retry.isNotEmpty) {
        _saveSearchCache(cacheKey, retry);
        emit(CinemaSearchLoaded(videoInfos: List.unmodifiable(retry)));
      } else {
        final fallback = await _searchViaYtDlpServiceFallback(
          text: normalizedText,
          count: count,
          appBloc: appBloc,
        );
        if (!_isRequestActive(requestId)) return;
        if (fallback.isNotEmpty) {
          log.w(
            '[CinemaSearchBloc] isolate empty, fallback service succeeded '
            'query="$normalizedText" count=${fallback.length}',
          );
          _saveSearchCache(cacheKey, fallback);
          emit(CinemaSearchLoaded(videoInfos: fallback));
          return;
        }
        final cached = _loadFreshSearchCache(cacheKey);
        if (cached != null) {
          log.w(
            '[CinemaSearchBloc] retry empty, fallback to cached '
            'query="$normalizedText" count=${cached.length}',
          );
          emit(CinemaSearchLoaded(videoInfos: cached));
        } else {
          emit(CinemaSearchLoaded(videoInfos: const []));
        }
      }
    }
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

  Future<List<DlpVideoInfo>> _searchViaYtDlpServiceFallback({
    required String text,
    required int count,
    required AppBloc appBloc,
  }) async {
    final beatSaberPath = appBloc.beatSaberPath;
    if (beatSaberPath == null || beatSaberPath.trim().isEmpty) {
      return const [];
    }
    try {
      final service = YtDlpService(
        beatSaberPath: beatSaberPath,
        proxyMode: appBloc.proxyMode,
        customProxy: appBloc.proxyServer,
      );
      final platform = appBloc.cinemaSearchPlatform == CinemaSearchPlatform.bilibili
          ? VideoPlatform.bilibili
          : VideoPlatform.youtube;
      final results = await service.search(text, platform);
      if (results.isEmpty) return const [];
      return results
          .take(count)
          .map(
            (item) => DlpVideoInfo(
              id: item.id,
              title: item.title,
              duration: item.durationSeconds.toDouble(),
              durationString: _formatSeconds(item.durationSeconds),
              thumbnail: item.thumbnailUrl,
              uploader: item.author,
              originalUrl: item.url,
              webpageUrl: item.url,
            ),
          )
          .toList(growable: false);
    } catch (e, st) {
      log.w(
        '[CinemaSearchBloc] fallback service search failed query="$text"',
        e,
        st,
      );
      return const [];
    }
  }

  static String _formatSeconds(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void killIsolate() {
    currentIsolate?.kill();
    currentIsolate = null;
  }

  Future<List<DlpVideoInfo>> _searchWithYtDlpIsolate({
    required String text,
    required int count,
    required String beatSaberPath,
    required CinemaSearchPlatform platform,
    required String? proxyUrl,
    required Emitter<CinemaSearchState> emit,
    required int requestId,
  }) async {
    final receivePort = ReceivePort();
    final videoInfos = <DlpVideoInfo>[];
    final completer = Completer<void>();
    late final Isolate spawnedIsolate;
    StreamSubscription? subscription;
    var disposed = false;

    void disposeLocalResources() {
      if (disposed) return;
      disposed = true;
      subscription?.cancel();
      receivePort.close();
      if (identical(currentIsolate, spawnedIsolate)) {
        currentIsolate = null;
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    subscription = receivePort.listen(
      (value) {
        if (value == Constants.sendPortDoneString) {
          spawnedIsolate.kill(priority: Isolate.immediate);
          disposeLocalResources();
          return;
        }
        if (value is! String) return;
        final line = value.trim();
        if (line.isEmpty) return;
        try {
          final videoInfo = DlpVideoInfo.fromJson(line);
          videoInfos.add(videoInfo);
          if (_isRequestActive(requestId)) {
            emit(CinemaSearchLoaded(videoInfos: List.unmodifiable(videoInfos)));
          }
        } catch (_) {
          // Ignore non-json line, keep stream alive.
        }
      },
      onDone: () {
        disposeLocalResources();
      },
      onError: (_) {
        disposeLocalResources();
      },
    );

    spawnedIsolate = await Isolate.spawn(
      _searchCinemaWithYTDlp,
      CinameSearchParams(
        text: text,
        count: count,
        beatSaberPath: beatSaberPath,
        cinemaSearchPlatform: platform,
        proxyUrl: proxyUrl,
        sendport: receivePort.sendPort,
      ),
      debugName: text,
    );
    currentIsolate = spawnedIsolate;
    await completer.future;
    return videoInfos;
  }

  bool _isRequestActive(int requestId) => requestId == _activeRequestId;

  void _saveSearchCache(String key, List<DlpVideoInfo> results) {
    if (results.isEmpty) return;
    _searchResultCache[key] = _CachedSearchResults(
      timestamp: DateTime.now(),
      results: List<DlpVideoInfo>.unmodifiable(results),
    );
    _pruneStaleSearchCache();
  }

  List<DlpVideoInfo>? _loadFreshSearchCache(String key) {
    final cached = _searchResultCache[key];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.timestamp) > _searchResultCacheTtl) {
      _searchResultCache.remove(key);
      return null;
    }
    return cached.results;
  }

  void _pruneStaleSearchCache() {
    if (_searchResultCache.isEmpty) return;
    final now = DateTime.now();
    final staleKeys = <String>[];
    for (final entry in _searchResultCache.entries) {
      if (now.difference(entry.value.timestamp) > _searchResultCacheTtl) {
        staleKeys.add(entry.key);
      }
    }
    for (final key in staleKeys) {
      _searchResultCache.remove(key);
    }
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
    final process = await Process.start(dlpPath, args);
    final done = Completer<void>();

    process.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(
      (line) {
        params.sendport.send(line);
      },
      onDone: () async {
        await process.exitCode;
        params.sendport.send(Constants.sendPortDoneString);
        if (!done.isCompleted) done.complete();
      },
      onError: (_) {
        params.sendport.send(Constants.sendPortDoneString);
        if (!done.isCompleted) done.complete();
      },
    );

    process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen((line) {
      log.w('[CinemaSearchBloc] yt-dlp search stderr: $line');
    });

    await done.future;
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

  @visibleForTesting
  static String buildSearchCacheKey({
    required CinemaSearchPlatform platform,
    required int count,
    required String text,
    String? proxyUrl,
  }) {
    final query = text.trim().toLowerCase();
    final proxy = (proxyUrl ?? '').trim().toLowerCase();
    return '${platform.name}|$count|$query|$proxy';
  }

  @override
  Future<void> close() {
    killIsolate();
    return super.close();
  }
}

class _CachedSearchResults {
  const _CachedSearchResults({
    required this.timestamp,
    required this.results,
  });

  final DateTime timestamp;
  final List<DlpVideoInfo> results;
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
