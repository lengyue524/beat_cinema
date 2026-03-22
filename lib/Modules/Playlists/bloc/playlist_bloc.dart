import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Services/managers/download_manager.dart';
import 'package:beat_cinema/Services/repositories/video_repository.dart';
import 'package:beat_cinema/Services/services/beatsaver_download_service.dart';
import 'package:beat_cinema/Services/services/level_parse_service.dart';
import 'package:beat_cinema/Services/services/playlist_hash_index_cache_service.dart';
import 'package:beat_cinema/Services/services/playlist_parse_service.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:bloc/bloc.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

part 'playlist_event.dart';
part 'playlist_state.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final PlaylistParseService _parseService;
  final LevelParseService _levelParseService;
  final BeatSaverDownloadService _beatSaverDownloadService;
  final DownloadManager? _downloadManager;
  final PlaylistHashIndexCacheService _hashIndexCacheService;

  List<PlaylistWithStatus> _playlists = [];
  List<PlaylistInfo> _rawPlaylists = [];
  List<LevelMetadata> _levels = [];
  int? _selectedIndex;
  bool _filterUnconfigured = false;
  String? _currentBeatSaberPath;

  final Map<String, String> _taskIdToSongHash = {};
  final Map<String, String> _downloadedHashToLevelPath = {};
  final Set<String> _downloadingHashes = {};
  final Map<String, String> _downloadErrors = {};
  bool _hasCompletedDownloadsPendingReload = false;
  StreamSubscription<List<DownloadTask>>? _downloadSub;
  ExportResult? _latestExportResult;
  Map<String, String> _cachedHashPathIndex = const {};
  int _rebuildNoticeSerial = 0;

  PlaylistBloc({
    PlaylistParseService? parseService,
    LevelParseService? levelParseService,
    BeatSaverDownloadService? beatSaverDownloadService,
    DownloadManager? downloadManager,
    PlaylistHashIndexCacheService? hashIndexCacheService,
  })  : _parseService = parseService ?? PlaylistParseService(),
        _levelParseService = levelParseService ?? LevelParseService(),
        _beatSaverDownloadService =
            beatSaverDownloadService ?? BeatSaverDownloadService(),
        _downloadManager = downloadManager,
        _hashIndexCacheService =
            hashIndexCacheService ?? PlaylistHashIndexCacheService(),
        super(PlaylistInitial()) {
    on<LoadPlaylistsEvent>(_onLoad);
    on<SelectPlaylistEvent>(_onSelect);
    on<DeselectPlaylistEvent>(_onDeselect);
    on<ToggleFilterUnconfiguredEvent>(_onToggleFilter);
    on<ExportPlaylistEvent>(_onExport);
    on<DownloadMissingSongEvent>(_onDownloadMissingSong);
    on<DownloadTasksUpdatedEvent>(_onDownloadTasksUpdated);
    on<DownloadAllMissingSongsEvent>(_onDownloadAllMissingSongs);
    on<RetryFailedExportEvent>(_onRetryFailedExport);
    on<DismissExportResultEvent>(_onDismissExportResult);
    on<RebuildPlaylistHashIndexEvent>(_onRebuildHashIndex);
    on<DismissPlaylistRebuildNoticeEvent>(_onDismissRebuildNotice);
    on<RefreshMatchedLevelEvent>(_onRefreshMatchedLevel);

    _downloadSub = _downloadManager?.taskStream.listen((_) {
      add(DownloadTasksUpdatedEvent());
    });
  }

  Future<void> _onLoad(
      LoadPlaylistsEvent event, Emitter<PlaylistState> emit) async {
    log.i('[Playlist] load start beatSaberPath=${event.beatSaberPath}');
    emit(PlaylistLoading(stage: 'parse-playlists'));
    try {
      _currentBeatSaberPath = event.beatSaberPath;
      final raw = await _parseService.parseAll(event.beatSaberPath);
      var levelsForMatch = event.levels;
      final totalSongs = _countSongs(raw);
      final totalPlaylists = raw.length;
      var playlists = <PlaylistWithStatus>[];
      final likelyStaleCache = _isLikelyStaleLevelCache(levelsForMatch);
      var expectedFingerprint =
          _buildHashIndexFingerprint(event.beatSaberPath, levelsForMatch);
      _cachedHashPathIndex = const {};

      if (likelyStaleCache) {
        emit(PlaylistLoading(
          stage: 'refresh-levels-fast',
          processedSongs: 0,
          totalSongs: totalSongs,
          parsedPlaylists: totalPlaylists,
          totalPlaylists: totalPlaylists,
        ));
        levelsForMatch = await _parseLevelsInParallelBatches(
          event.beatSaberPath,
          includeMapHash: false,
          onProgress: (processedDirs, totalDirs) {
            emit(PlaylistLoading(
              stage: 'refresh-levels-fast',
              processedSongs: processedDirs,
              totalSongs: totalDirs,
              parsedPlaylists: totalPlaylists,
              totalPlaylists: totalPlaylists,
            ));
          },
        );
        expectedFingerprint =
            _buildHashIndexFingerprint(event.beatSaberPath, levelsForMatch);
      }

      final cachedHashIndex = await _tryLoadHashIndexCache(
          expectedFingerprint: expectedFingerprint);
      if (cachedHashIndex.isNotEmpty) {
        _cachedHashPathIndex = cachedHashIndex;
        log.i(
          '[PlaylistHashCache] use cached hash index entries=${cachedHashIndex.length}',
        );
      }

      emit(PlaylistLoading(
        stage: 'match-songs',
        processedSongs: 0,
        totalSongs: totalSongs,
        parsedPlaylists: totalPlaylists,
        totalPlaylists: totalPlaylists,
      ));
      playlists = await _buildPlaylistsForLoad(
        raw,
        levelsForMatch,
        totalSongsOverride: totalSongs,
        cachedHashPathIndex: _cachedHashPathIndex,
        onSongProgress: (processed, total) {
          emit(PlaylistLoading(
            stage: 'match-songs',
            processedSongs: processed,
            totalSongs: total,
            parsedPlaylists: totalPlaylists,
            totalPlaylists: totalPlaylists,
          ));
        },
      );

      if (_isZeroMatch(playlists)) {
        emit(PlaylistLoading(
          stage: 'refresh-levels-fast',
          processedSongs: 0,
          totalSongs: totalSongs,
          parsedPlaylists: totalPlaylists,
          totalPlaylists: totalPlaylists,
        ));
        levelsForMatch = await _parseLevelsInParallelBatches(
          event.beatSaberPath,
          includeMapHash: false,
          onProgress: (processedDirs, totalDirs) {
            emit(PlaylistLoading(
              stage: 'refresh-levels-fast',
              processedSongs: processedDirs,
              totalSongs: totalDirs,
              parsedPlaylists: totalPlaylists,
              totalPlaylists: totalPlaylists,
            ));
          },
        );
        emit(PlaylistLoading(
          stage: 'match-songs',
          processedSongs: 0,
          totalSongs: totalSongs,
          parsedPlaylists: totalPlaylists,
          totalPlaylists: totalPlaylists,
        ));
        playlists = await _buildPlaylistsForLoad(
          raw,
          levelsForMatch,
          totalSongsOverride: totalSongs,
          cachedHashPathIndex: _cachedHashPathIndex,
          onSongProgress: (processed, total) {
            emit(PlaylistLoading(
              stage: 'match-songs',
              processedSongs: processed,
              totalSongs: total,
              parsedPlaylists: totalPlaylists,
              totalPlaylists: totalPlaylists,
            ));
          },
        );
      }

      final shouldRunHashBackfill = _shouldReloadWithHashBackfill(
        rawPlaylists: raw,
        levels: levelsForMatch,
        playlists: playlists,
        hasCachedHashIndex: _cachedHashPathIndex.isNotEmpty,
      );
      if (shouldRunHashBackfill) {
        emit(PlaylistLoading(
          stage: 'refresh-levels-hash',
          processedSongs: 0,
          totalSongs: totalSongs,
          parsedPlaylists: totalPlaylists,
          totalPlaylists: totalPlaylists,
        ));
        levelsForMatch = await _parseLevelsInParallelBatches(
          event.beatSaberPath,
          includeMapHash: true,
          onProgress: (processedDirs, totalDirs) {
            emit(PlaylistLoading(
              stage: 'refresh-levels-hash',
              processedSongs: processedDirs,
              totalSongs: totalDirs,
              parsedPlaylists: totalPlaylists,
              totalPlaylists: totalPlaylists,
            ));
          },
        );
        expectedFingerprint =
            _buildHashIndexFingerprint(event.beatSaberPath, levelsForMatch);
        _cachedHashPathIndex = _buildHashPathIndex(levelsForMatch);
        await _saveHashIndexCache(
          expectedFingerprint: expectedFingerprint,
          hashPathIndex: _cachedHashPathIndex,
        );
        emit(PlaylistLoading(
          stage: 'match-songs',
          processedSongs: 0,
          totalSongs: totalSongs,
          parsedPlaylists: totalPlaylists,
          totalPlaylists: totalPlaylists,
        ));
        playlists = await _buildPlaylistsForLoad(
          raw,
          levelsForMatch,
          totalSongsOverride: totalSongs,
          cachedHashPathIndex: _cachedHashPathIndex,
          onSongProgress: (processed, total) {
            emit(PlaylistLoading(
              stage: 'match-songs',
              processedSongs: processed,
              totalSongs: total,
              parsedPlaylists: totalPlaylists,
              totalPlaylists: totalPlaylists,
            ));
          },
        );
      }
      _rawPlaylists = raw;
      _levels = levelsForMatch;
      _playlists = playlists;

      _selectedIndex = null;
      _filterUnconfigured = false;
      log.i(
        '[Playlist] load completed playlists=${_playlists.length} levels=${_levels.length}',
      );
      emit(_buildLoadedState());
    } catch (e) {
      log.e('[Playlist] load failed error=$e', e);
      emit(PlaylistError(e.toString()));
    }
  }

  Future<void> _onRebuildHashIndex(
    RebuildPlaylistHashIndexEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    final beatSaberPath = _currentBeatSaberPath;
    if (beatSaberPath == null) return;
    log.i('[Playlist] rebuild hash index start');
    try {
      final totalPlaylists = _rawPlaylists.length;
      emit(PlaylistLoading(
        stage: 'rebuild-index-scan',
        processedSongs: 0,
        totalSongs: 0,
        parsedPlaylists: totalPlaylists,
        totalPlaylists: totalPlaylists,
      ));
      final levelsWithHash = await _parseLevelsInParallelBatches(
        beatSaberPath,
        includeMapHash: true,
        onProgress: (processedDirs, totalDirs) {
          emit(PlaylistLoading(
            stage: 'rebuild-index-hash',
            processedSongs: processedDirs,
            totalSongs: totalDirs,
            parsedPlaylists: totalPlaylists,
            totalPlaylists: totalPlaylists,
          ));
        },
      );
      emit(PlaylistLoading(
        stage: 'rebuild-index-save',
        processedSongs: levelsWithHash.length,
        totalSongs: levelsWithHash.length,
        parsedPlaylists: totalPlaylists,
        totalPlaylists: totalPlaylists,
      ));

      final fingerprint =
          _buildHashIndexFingerprint(beatSaberPath, levelsWithHash);
      _cachedHashPathIndex = _buildHashPathIndex(levelsWithHash);
      await _saveHashIndexCache(
        expectedFingerprint: fingerprint,
        hashPathIndex: _cachedHashPathIndex,
      );
      _levels = levelsWithHash;
      if (_rawPlaylists.isEmpty) {
        _rawPlaylists = await _parseService.parseAll(beatSaberPath);
      }
      _playlists = await _buildPlaylistsForLoad(
        _rawPlaylists,
        _levels,
        cachedHashPathIndex: _cachedHashPathIndex,
      );
      _selectedIndex = null;
      _rebuildNoticeSerial++;
      log.i('[Playlist] rebuild hash index completed');
      emit(_buildLoadedState(
        rebuildNotice: PlaylistRebuildNotice(
          success: true,
          message: 'rebuild_success',
          serial: _rebuildNoticeSerial,
        ),
      ));
    } catch (e) {
      log.e('[PlaylistHashCache] rebuild failed: $e');
      final reasonCode = _friendlyRebuildFailureReasonCode(e);
      _rebuildNoticeSerial++;
      emit(_buildLoadedState(
        rebuildNotice: PlaylistRebuildNotice(
          success: false,
          message: reasonCode,
          serial: _rebuildNoticeSerial,
          detail: e.toString(),
        ),
      ));
    }
  }

  void _onDismissRebuildNotice(
    DismissPlaylistRebuildNoticeEvent event,
    Emitter<PlaylistState> emit,
  ) {
    emit(_buildLoadedState());
  }

  Future<void> _onRefreshMatchedLevel(
    RefreshMatchedLevelEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    final levelPath = event.levelPath.trim();
    if (levelPath.isEmpty) return;
    final parsed = await _levelParseService.parseSingleLevel(levelPath);
    if (parsed == null) {
      log.w('[Playlist] refresh matched level skipped path=$levelPath');
      return;
    }
    final normalizedTarget = levelPath.toLowerCase();
    final levelIndex = _levels.indexWhere(
      (item) => item.levelPath.trim().toLowerCase() == normalizedTarget,
    );
    if (levelIndex >= 0) {
      _levels[levelIndex] = parsed;
    } else {
      _levels = List<LevelMetadata>.from(_levels)..add(parsed);
    }

    var playlistsChanged = false;
    final nextPlaylists = <PlaylistWithStatus>[];
    for (final playlist in _playlists) {
      var songsChanged = false;
      final nextSongs = <PlaylistSongWithStatus>[];
      for (final songStatus in playlist.songs) {
        final matched = songStatus.matchedLevel;
        if (matched == null ||
            matched.levelPath.trim().toLowerCase() != normalizedTarget) {
          nextSongs.add(songStatus);
          continue;
        }
        songsChanged = true;
        nextSongs.add(
          PlaylistSongWithStatus(
            song: songStatus.song,
            matchedLevel: parsed,
            downloading: songStatus.downloading,
            downloadError: songStatus.downloadError,
          ),
        );
      }
      if (!songsChanged) {
        nextPlaylists.add(playlist);
        continue;
      }
      playlistsChanged = true;
      nextPlaylists.add(
        PlaylistWithStatus(
          info: playlist.info,
          songs: nextSongs,
          matchedCount: nextSongs.where((song) => song.matchedLevel != null).length,
          configuredCount:
              nextSongs.where((song) => song.matchedLevel?.cinemaConfig != null).length,
        ),
      );
    }
    if (!playlistsChanged) return;
    _playlists = nextPlaylists;
    emit(_buildLoadedState());
  }

  bool _isLikelyStaleLevelCache(List<LevelMetadata> levels) {
    if (levels.isEmpty) return true;
    return levels.every((level) => level.mapHash.trim().isEmpty);
  }

  bool _isZeroMatch(List<PlaylistWithStatus> playlists) {
    var totalSongs = 0;
    var matchedSongs = 0;
    for (final playlist in playlists) {
      totalSongs += playlist.songs.length;
      matchedSongs += playlist.matchedCount;
    }
    return totalSongs > 0 && matchedSongs == 0;
  }

  bool _shouldReloadWithHashBackfill({
    required List<PlaylistInfo> rawPlaylists,
    required List<LevelMetadata> levels,
    required List<PlaylistWithStatus> playlists,
    required bool hasCachedHashIndex,
  }) {
    final totalSongs = _countSongs(rawPlaylists);
    if (totalSongs == 0 || levels.isEmpty) return false;

    var songsWithHash = 0;
    for (final playlist in rawPlaylists) {
      for (final song in playlist.songs) {
        if (song.hash.trim().isNotEmpty) {
          songsWithHash++;
        }
      }
    }
    if (songsWithHash == 0) return false;

    var matchedSongs = 0;
    var unmatchedHashSongs = 0;
    for (final playlist in playlists) {
      matchedSongs += playlist.matchedCount;
      for (final song in playlist.songs) {
        if (song.matchedLevel == null && song.song.hash.trim().isNotEmpty) {
          unmatchedHashSongs++;
        }
      }
    }
    if (unmatchedHashSongs == 0) return false;

    var levelsWithHash = 0;
    for (final level in levels) {
      if (level.mapHash.trim().isNotEmpty) {
        levelsWithHash++;
      }
    }
    final hashCoverage = levelsWithHash / levels.length;
    final matchRate = matchedSongs / totalSongs;

    if (hasCachedHashIndex && matchRate >= 0.9) {
      return false;
    }
    // When level hash coverage is low and playlist matching is weak,
    // re-parse with full hash to recover entries whose folder keys differ.
    return hashCoverage < 0.1 && (matchRate < 0.9 || unmatchedHashSongs >= 20);
  }

  Future<List<LevelMetadata>> _parseLevelsInParallelBatches(
    String beatSaberPath, {
    required bool includeMapHash,
    required void Function(int processedDirs, int totalDirs) onProgress,
  }) async {
    final customLevelsPath =
        p.join(beatSaberPath, Constants.dataDir, Constants.customLevelsDir);
    final root = Directory(customLevelsPath);
    if (!await root.exists()) {
      onProgress(0, 0);
      return const [];
    }

    final dirs = await root
        .list()
        .where((entity) => entity is Directory)
        .map((entity) => entity.path)
        .toList();
    final totalDirs = dirs.length;
    onProgress(0, totalDirs);
    if (dirs.isEmpty) {
      return const [];
    }

    final workers = _resolveParseWorkers(
      totalDirs: totalDirs,
      includeMapHash: includeMapHash,
    );
    if (workers <= 1) {
      final parsed = await _levelParseService.parseDirectories(
        dirs,
        includeMapHash: includeMapHash,
      );
      onProgress(totalDirs, totalDirs);
      return parsed;
    }

    final chunkSize = _resolveChunkSize(
      totalDirs: totalDirs,
      includeMapHash: includeMapHash,
    );
    final chunks = _chunkPaths(dirs, chunkSize);
    final results = <LevelMetadata>[];
    var processedDirs = 0;
    for (var i = 0; i < chunks.length; i += workers) {
      final end = math.min(i + workers, chunks.length);
      final batchChunks = chunks.sublist(i, end);
      final parsedBatch = await Future.wait(
        batchChunks.map(
          (chunk) => _levelParseService.parseDirectories(
            chunk,
            includeMapHash: includeMapHash,
          ),
        ),
      );
      for (var j = 0; j < parsedBatch.length; j++) {
        results.addAll(parsedBatch[j]);
        processedDirs += batchChunks[j].length;
      }
      onProgress(processedDirs, totalDirs);
    }
    return results;
  }

  int _resolveParseWorkers({
    required int totalDirs,
    required bool includeMapHash,
  }) {
    if (totalDirs < 200) return 1;
    final cpu = Platform.numberOfProcessors;
    final upperBound = includeMapHash ? 6 : 8;
    final suggested = math.max(2, cpu - 1);
    return math.min(upperBound, suggested);
  }

  int _resolveChunkSize({
    required int totalDirs,
    required bool includeMapHash,
  }) {
    final base = includeMapHash ? 180 : 260;
    if (totalDirs <= base) return totalDirs;
    return base;
  }

  List<List<String>> _chunkPaths(List<String> paths, int chunkSize) {
    final chunks = <List<String>>[];
    for (var i = 0; i < paths.length; i += chunkSize) {
      final end = math.min(i + chunkSize, paths.length);
      chunks.add(paths.sublist(i, end));
    }
    return chunks;
  }

  int _countSongs(List<PlaylistInfo> playlists) {
    var total = 0;
    for (final playlist in playlists) {
      total += playlist.songs.length;
    }
    return total;
  }

  Future<Map<String, String>> _tryLoadHashIndexCache({
    required String expectedFingerprint,
  }) async {
    final startedAt = DateTime.now();
    final cache = await _hashIndexCacheService.load();
    if (cache == null) {
      log.i('[PlaylistHashCache] miss: no cache file');
      return const {};
    }
    final validation = _hashIndexCacheService.validate(
      cache,
      expectedFingerprint: expectedFingerprint,
    );
    if (validation != null) {
      log.w('[PlaylistHashCache] invalid: $validation');
      return const {};
    }
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    log.i(
        '[PlaylistHashCache] hit entries=${cache.entries.length} elapsedMs=$elapsed');
    return cache.entries;
  }

  Future<void> _saveHashIndexCache({
    required String expectedFingerprint,
    required Map<String, String> hashPathIndex,
  }) async {
    final startedAt = DateTime.now();
    final cache = PlaylistHashIndexCache(
      schemaVersion: PlaylistHashIndexCacheService.currentSchemaVersion,
      generatedAt: DateTime.now(),
      sourceFingerprint: expectedFingerprint,
      entries: Map<String, String>.unmodifiable(hashPathIndex),
    );
    await _hashIndexCacheService.save(cache);
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    log.i(
      '[PlaylistHashCache] saved entries=${hashPathIndex.length} elapsedMs=$elapsed',
    );
  }

  String _buildHashIndexFingerprint(
    String beatSaberPath,
    List<LevelMetadata> levels,
  ) {
    final normalizedPaths = levels
        .map((e) => e.levelPath.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList(growable: false)
      ..sort();
    final payload = '$beatSaberPath|${normalizedPaths.join('|')}';
    return sha1.convert(utf8.encode(payload)).toString();
  }

  String _friendlyRebuildFailureReasonCode(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('permission') ||
        raw.contains('access is denied') ||
        raw.contains('operation not permitted')) {
      return 'playlist_rebuild_error_permission';
    }
    if (raw.contains('no such file') ||
        raw.contains('not found') ||
        raw.contains('cannot find the path')) {
      return 'playlist_rebuild_error_path_not_found';
    }
    if (raw.contains('write') ||
        raw.contains('rename') ||
        raw.contains('filesystem') ||
        raw.contains('file system')) {
      return 'playlist_rebuild_error_cache_write';
    }
    return 'playlist_rebuild_error_unknown';
  }

  Future<List<PlaylistWithStatus>> _buildPlaylistsForLoad(
    List<PlaylistInfo> infos,
    List<LevelMetadata> levels, {
    int? totalSongsOverride,
    Map<String, String> cachedHashPathIndex = const {},
    void Function(int processed, int total)? onSongProgress,
  }) async {
    final totalSongs = totalSongsOverride ?? _countSongs(infos);
    if (totalSongs < 1200 || infos.length < 8) {
      return _buildPlaylists(
        infos,
        levels,
        totalSongsOverride: totalSongs,
        cachedHashPathIndex: cachedHashPathIndex,
        onSongProgress: onSongProgress,
      );
    }

    final workers = _resolveMatchWorkers(totalSongs);
    if (workers <= 1) {
      return _buildPlaylists(
        infos,
        levels,
        totalSongsOverride: totalSongs,
        cachedHashPathIndex: cachedHashPathIndex,
        onSongProgress: onSongProgress,
      );
    }

    final chunks = _buildMatchChunks(infos, workers);
    if (chunks.length <= 1) {
      return _buildPlaylists(
        infos,
        levels,
        totalSongsOverride: totalSongs,
        cachedHashPathIndex: cachedHashPathIndex,
        onSongProgress: onSongProgress,
      );
    }

    final levelByPath = <String, LevelMetadata>{
      for (final level in levels) level.levelPath.trim().toLowerCase(): level,
    };
    final keyIndex = _buildKeyPathIndex(levels);
    final hashIndex = _buildHashPathIndex(
      levels,
      cachedHashPathIndex: cachedHashPathIndex,
    );
    final songNameIndex = _buildSongNamePathIndex(levels);

    final results = List<PlaylistWithStatus?>.filled(infos.length, null);
    var processedSongs = 0;
    onSongProgress?.call(0, totalSongs);

    for (var i = 0; i < chunks.length; i += workers) {
      final end = math.min(i + workers, chunks.length);
      final batch = chunks.sublist(i, end);
      final batchResult = await Future.wait(
        batch.map(
          (chunk) => Isolate.run(
            () => _matchPlaylistChunkWorker({
              'playlists': chunk.payload,
              'keyIndex': keyIndex,
              'hashIndex': hashIndex,
              'songNameIndex': songNameIndex,
            }),
          ),
        ),
      );

      for (var b = 0; b < batchResult.length; b++) {
        final matchedPlaylists = batchResult[b];
        for (final playlistMatch in matchedPlaylists) {
          final playlistIndex = playlistMatch['index'] as int;
          final matchedPaths =
              (playlistMatch['matchedPaths'] as List).cast<String?>();
          final info = infos[playlistIndex];
          final songs = <PlaylistSongWithStatus>[];
          for (var s = 0; s < info.songs.length; s++) {
            final song = info.songs[s];
            final levelPath = s < matchedPaths.length ? matchedPaths[s] : null;
            final matched = levelPath == null
                ? null
                : levelByPath[levelPath.trim().toLowerCase()];
            final key = _songKey(song);
            songs.add(PlaylistSongWithStatus(
              song: song,
              matchedLevel: matched,
              downloading: _downloadingHashes.contains(key),
              downloadError: _downloadErrors[key],
            ));
          }
          results[playlistIndex] = PlaylistWithStatus(
            info: info,
            songs: songs,
            matchedCount: songs.where((s) => s.matchedLevel != null).length,
            configuredCount:
                songs.where((s) => s.matchedLevel?.cinemaConfig != null).length,
          );
        }
        processedSongs += batch[b].songCount;
      }

      onSongProgress?.call(
        math.min(processedSongs, totalSongs),
        totalSongs,
      );
    }

    return results.whereType<PlaylistWithStatus>().toList(growable: false);
  }

  void _onSelect(SelectPlaylistEvent event, Emitter<PlaylistState> emit) {
    _selectedIndex = event.index;
    emit(_buildLoadedState());
  }

  void _onDeselect(DeselectPlaylistEvent event, Emitter<PlaylistState> emit) {
    _selectedIndex = null;
    emit(_buildLoadedState());
  }

  void _onToggleFilter(
      ToggleFilterUnconfiguredEvent event, Emitter<PlaylistState> emit) {
    _filterUnconfigured = !_filterUnconfigured;
    emit(_buildLoadedState());
  }

  Future<void> _onExport(
      ExportPlaylistEvent event, Emitter<PlaylistState> emit) async {
    if (_selectedIndex == null) return;
    final playlist = _playlists[_selectedIndex!];
    final result = await _runExport(
      playlist: playlist,
      targetPath: event.targetPath,
      emit: emit,
      onlyFailures: null,
    );
    _latestExportResult = result;
    emit(_buildLoadedState(
      exporting: false,
      exportProgress: 1.0,
      exportResult: result,
    ));
  }

  Future<void> _onDownloadMissingSong(
      DownloadMissingSongEvent event, Emitter<PlaylistState> emit) async {
    final hash = _songKey(event.song.song);
    if (hash.isEmpty ||
        _downloadManager == null ||
        _currentBeatSaberPath == null) {
      return;
    }
    final manager = _downloadManager;
    if (manager == null) return;
    if (_downloadingHashes.contains(hash)) {
      return;
    }

    _downloadingHashes.add(hash);
    _downloadErrors.remove(hash);

    final title = event.song.song.songName?.trim().isNotEmpty == true
        ? event.song.song.songName!
        : hash;

    final taskId = manager.enqueueCustom(
      title: '[Playlist] $title',
      metadata: {
        'source': 'playlist',
        'songName': title,
        'hash': hash,
        'reason': 'missing',
      },
      runner: (task, onProgress) =>
          _beatSaverDownloadService.downloadSongByHash(
        taskId: task.taskId,
        beatSaberPath: _currentBeatSaberPath!,
        hash: hash,
        titleHint: title,
        onProgress: onProgress,
      ),
    );
    _taskIdToSongHash[taskId] = hash;
    log.i(
      '[PlaylistDownload] enqueue single taskId=$taskId hash=$hash title=$title',
    );
    emit(_buildLoadedState());
  }

  Future<void> _onDownloadAllMissingSongs(
      DownloadAllMissingSongsEvent event, Emitter<PlaylistState> emit) async {
    if (_selectedIndex == null ||
        _downloadManager == null ||
        _currentBeatSaberPath == null) {
      return;
    }
    final manager = _downloadManager;
    if (manager == null) return;

    final songs = _playlists[_selectedIndex!].songs;
    final candidates = _collectBatchCandidates(
      songs,
      includeExistingUpdates: event.includeExistingUpdates,
      forceUpdateExisting: event.forceUpdateExisting,
    );
    if (candidates.isEmpty) return;

    var index = 0;
    for (final candidate in candidates) {
      final hash = _songKey(candidate.song.song);
      if (hash.isEmpty || _downloadingHashes.contains(hash)) {
        continue;
      }

      _downloadingHashes.add(hash);
      _downloadErrors.remove(hash);
      final songName = candidate.song.song.songName?.trim().isNotEmpty == true
          ? candidate.song.song.songName!
          : hash;

      final taskId = manager.enqueueCustom(
        title: '[Playlist] $songName',
        metadata: {
          'source': 'playlist',
          'songName': songName,
          'hash': hash,
          'reason': candidate.reason,
        },
        runner: (task, onProgress) =>
            _beatSaverDownloadService.downloadSongByHash(
          taskId: task.taskId,
          beatSaberPath: _currentBeatSaberPath!,
          hash: hash,
          titleHint: songName,
          onProgress: onProgress,
        ),
      );
      _taskIdToSongHash[taskId] = hash;
      log.i(
        '[PlaylistDownload] enqueue batch taskId=$taskId '
        'hash=$hash title=$songName reason=${candidate.reason}',
      );
      index++;
      // Light batching: keep UI responsive for large enqueue bursts.
      if (index % 20 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    emit(_buildLoadedState());
  }

  Future<void> _onRetryFailedExport(
      RetryFailedExportEvent event, Emitter<PlaylistState> emit) async {
    if (_selectedIndex == null || _latestExportResult == null) return;
    final failures = _latestExportResult!.failures;
    if (failures.isEmpty) return;
    final playlist = _playlists[_selectedIndex!];
    final result = await _runExport(
      playlist: playlist,
      targetPath: _latestExportResult!.targetPath,
      emit: emit,
      onlyFailures: failures,
    );
    _latestExportResult = result;
    emit(_buildLoadedState(
      exporting: false,
      exportProgress: 1.0,
      exportResult: result,
    ));
  }

  void _onDismissExportResult(
      DismissExportResultEvent event, Emitter<PlaylistState> emit) {
    _latestExportResult = null;
    emit(_buildLoadedState());
  }

  Future<void> _onDownloadTasksUpdated(
      DownloadTasksUpdatedEvent event, Emitter<PlaylistState> emit) async {
    final manager = _downloadManager;
    if (manager == null) return;
    final taskMap = {
      for (final task in manager.tasks) task.taskId: task,
    };

    var changed = false;
    final activeDownloadingHashes = <String>{};
    final completedOutputPaths = <String>{};
    final completedOutputPathToSongHash = <String, String>{};
    final completedSongHashes = <String>{};
    final entries = _taskIdToSongHash.entries.toList();
    for (final entry in entries) {
      final task = taskMap[entry.key];
      final songHash = entry.value;
      if (task == null) {
        _downloadingHashes.remove(songHash);
        _taskIdToSongHash.remove(entry.key);
        changed = true;
        continue;
      }
      if (task.status == DownloadStatus.pending ||
          task.status == DownloadStatus.downloading) {
        activeDownloadingHashes.add(songHash);
      } else if (task.status == DownloadStatus.completed) {
        log.i(
          '[PlaylistDownload] task completed taskId=${task.taskId} '
          'songHash=$songHash outputPath=${task.outputPath}',
        );
        _downloadErrors.remove(songHash);
        if ((task.outputPath ?? '').trim().isNotEmpty) {
          final normalizedOutputPath = task.outputPath!.trim();
          completedOutputPaths.add(normalizedOutputPath);
          completedOutputPathToSongHash[normalizedOutputPath] = songHash;
          _downloadedHashToLevelPath[songHash] = normalizedOutputPath;
        }
        completedSongHashes.add(songHash);
        _taskIdToSongHash.remove(entry.key);
        _hasCompletedDownloadsPendingReload = true;
        changed = true;
      } else if (task.status == DownloadStatus.failed) {
        log.w(
          '[PlaylistDownload] task failed taskId=${task.taskId} '
          'songHash=$songHash err=${task.errorMessage}',
        );
        _downloadErrors[songHash] = task.errorMessage ?? 'Download failed';
        _taskIdToSongHash.remove(entry.key);
        changed = true;
      } else if (task.status == DownloadStatus.cancelled) {
        log.i(
          '[PlaylistDownload] task cancelled taskId=${task.taskId} '
          'songHash=$songHash',
        );
        _downloadErrors[songHash] = '下载已取消';
        _taskIdToSongHash.remove(entry.key);
        changed = true;
      }
    }

    // Always derive spinner state from real active tasks to avoid stale loading UI.
    final before = Set<String>.from(_downloadingHashes);
    _downloadingHashes
      ..clear()
      ..addAll(activeDownloadingHashes);
    if (before.length != _downloadingHashes.length ||
        !before.containsAll(_downloadingHashes)) {
      changed = true;
    }

    final shouldReloadNow = _hasCompletedDownloadsPendingReload &&
        activeDownloadingHashes.isEmpty &&
        _currentBeatSaberPath != null;

    if (shouldReloadNow) {
      log.i(
        '[PlaylistDownload] start post-download reload '
        'completed=${completedSongHashes.length} '
        'outputPaths=${completedOutputPaths.length}',
      );
      final didIncrementalRefresh = await _tryIncrementalRefresh(
        completedOutputPaths: completedOutputPaths.toList(),
        outputPathToSongHash: completedOutputPathToSongHash,
      );
      if (!didIncrementalRefresh) {
        log.w(
          '[PlaylistDownload] incremental refresh skipped/fallback to full parse',
        );
        final levels =
            await _levelParseService.parseAll(_currentBeatSaberPath!);
        if (_rawPlaylists.isEmpty) {
          _rawPlaylists = await _parseService.parseAll(_currentBeatSaberPath!);
        }
        _levels = levels;
        _playlists = _buildPlaylists(
          _rawPlaylists,
          levels,
          cachedHashPathIndex: _cachedHashPathIndex,
        );
      }
      _logPostDownloadMatchStatus(completedSongHashes);
      _hasCompletedDownloadsPendingReload = false;
      if (_selectedIndex != null && _selectedIndex! >= _playlists.length) {
        _selectedIndex = null;
      }
    }

    if (changed || shouldReloadNow) {
      emit(_buildLoadedState());
    }
  }

  Future<bool> _tryIncrementalRefresh({
    required List<String> completedOutputPaths,
    required Map<String, String> outputPathToSongHash,
  }) async {
    if (_rawPlaylists.isEmpty ||
        _levels.isEmpty ||
        completedOutputPaths.isEmpty) {
      return false;
    }
    final byPath = <String, LevelMetadata>{
      for (final level in _levels) level.levelPath.trim().toLowerCase(): level,
    };
    var updated = 0;
    for (final outputPath in completedOutputPaths) {
      var parsed = await _levelParseService.parseSingleLevel(outputPath);
      if (parsed == null) {
        log.w(
          '[PlaylistDownload] parseSingleLevel returned null outputPath=$outputPath',
        );
        continue;
      }
      final expectedHash = outputPathToSongHash[outputPath]?.trim();
      if (expectedHash != null &&
          expectedHash.isNotEmpty &&
          parsed.mapHash.trim().toLowerCase() != expectedHash.toLowerCase()) {
        log.w(
          '[PlaylistDownload] parsed hash mismatch, apply downloaded hash override '
          'outputPath=$outputPath parsedHash=${parsed.mapHash} expectedHash=$expectedHash',
        );
        parsed = parsed.copyWith(mapHash: expectedHash.toUpperCase());
      }
      byPath[parsed.levelPath.trim().toLowerCase()] = parsed;
      log.i(
        '[PlaylistDownload] parsed downloaded level '
        'path=${parsed.levelPath} mapHash=${parsed.mapHash} '
        'song=${parsed.songName}',
      );
      updated++;
    }
    if (updated == 0) {
      return false;
    }
    _levels = byPath.values.toList(growable: false);
    _playlists = _buildPlaylists(
      _rawPlaylists,
      _levels,
      cachedHashPathIndex: _cachedHashPathIndex,
    );
    return true;
  }

  void _logPostDownloadMatchStatus(Set<String> completedSongHashes) {
    if (completedSongHashes.isEmpty) return;
    var references = 0;
    var matched = 0;
    final unresolved = <String>[];
    for (final playlist in _playlists) {
      for (final song in playlist.songs) {
        final key = _songKey(song.song);
        if (!completedSongHashes.contains(key)) continue;
        references++;
        if (song.matchedLevel != null) {
          matched++;
          continue;
        }
        if (unresolved.length < 20) {
          unresolved.add(
            'playlist=${playlist.info.title} '
            'song=${song.song.songName ?? '-'} '
            'hash=${song.song.hash} key=${song.song.key}',
          );
        }
      }
    }
    log.i(
      '[PlaylistDownload] post-reload match summary '
      'completedKeys=${completedSongHashes.length} '
      'references=$references matched=$matched unmatched=${references - matched}',
    );
    for (final item in unresolved) {
      log.w('[PlaylistDownload] still unmatched $item');
    }
  }

  Map<String, LevelMetadata> _buildKeyIndex(List<LevelMetadata> levels) {
    final index = <String, LevelMetadata>{};
    for (final level in levels) {
      final dirName = p.basename(level.levelPath).toLowerCase();
      final key = _extractDirectoryKey(dirName);
      if (key.isNotEmpty) {
        index.putIfAbsent(key, () => level);
      }
    }
    return index;
  }

  Map<String, String> _buildKeyPathIndex(List<LevelMetadata> levels) {
    final index = <String, String>{};
    for (final level in levels) {
      final dirName = p.basename(level.levelPath).toLowerCase();
      final key = _extractDirectoryKey(dirName);
      if (key.isNotEmpty) {
        index.putIfAbsent(key, () => level.levelPath);
      }
    }
    return index;
  }

  Map<String, LevelMetadata> _buildHashIndex(
    List<LevelMetadata> levels, {
    Map<String, String> cachedHashPathIndex = const {},
  }) {
    final index = <String, LevelMetadata>{};
    final byPath = <String, LevelMetadata>{
      for (final level in levels) level.levelPath.trim().toLowerCase(): level,
    };
    for (final level in levels) {
      for (final candidate in _extractHashCandidates(level.mapHash)) {
        index.putIfAbsent(candidate, () => level);
      }
      final dirName = p.basename(level.levelPath).toLowerCase();
      for (final candidate in _extractHashCandidates(dirName)) {
        index.putIfAbsent(candidate, () => level);
      }
    }
    for (final entry in _downloadedHashToLevelPath.entries) {
      final expectedHash = entry.key.trim().toLowerCase();
      final levelPath = entry.value.trim().toLowerCase();
      if (expectedHash.isEmpty || levelPath.isEmpty) continue;
      final level = byPath[levelPath];
      if (level == null) continue;
      for (final candidate in _extractHashCandidates(expectedHash)) {
        index.putIfAbsent(candidate, () => level);
      }
    }
    for (final entry in cachedHashPathIndex.entries) {
      final key = entry.key.trim().toLowerCase();
      final level = byPath[entry.value.trim().toLowerCase()];
      if (key.isEmpty || level == null) continue;
      for (final candidate in _extractHashCandidates(key)) {
        index.putIfAbsent(candidate, () => level);
      }
    }
    return index;
  }

  Map<String, String> _buildHashPathIndex(
    List<LevelMetadata> levels, {
    Map<String, String> cachedHashPathIndex = const {},
  }) {
    final index = <String, String>{};
    for (final level in levels) {
      for (final candidate in _extractHashCandidates(level.mapHash)) {
        index.putIfAbsent(candidate, () => level.levelPath);
      }
      final dirName = p.basename(level.levelPath).toLowerCase();
      for (final candidate in _extractHashCandidates(dirName)) {
        index.putIfAbsent(candidate, () => level.levelPath);
      }
    }
    for (final entry in _downloadedHashToLevelPath.entries) {
      final expectedHash = entry.key.trim().toLowerCase();
      final levelPath = entry.value.trim();
      if (expectedHash.isEmpty || levelPath.isEmpty) continue;
      for (final candidate in _extractHashCandidates(expectedHash)) {
        index.putIfAbsent(candidate, () => levelPath);
      }
    }
    for (final entry in cachedHashPathIndex.entries) {
      final expectedHash = entry.key.trim().toLowerCase();
      final levelPath = entry.value.trim();
      if (expectedHash.isEmpty || levelPath.isEmpty) continue;
      for (final candidate in _extractHashCandidates(expectedHash)) {
        index.putIfAbsent(candidate, () => levelPath);
      }
    }
    return index;
  }

  Map<String, LevelMetadata> _buildSongNameIndex(List<LevelMetadata> levels) {
    final unique = <String, LevelMetadata>{};
    final duplicated = <String>{};
    for (final level in levels) {
      final key = _normalizeSongName(level.songName);
      if (key.isEmpty) continue;
      if (unique.containsKey(key)) {
        duplicated.add(key);
        unique.remove(key);
        continue;
      }
      if (!duplicated.contains(key)) {
        unique[key] = level;
      }
    }
    return unique;
  }

  Map<String, String> _buildSongNamePathIndex(List<LevelMetadata> levels) {
    final unique = <String, String>{};
    final duplicated = <String>{};
    for (final level in levels) {
      final key = _normalizeSongName(level.songName);
      if (key.isEmpty) continue;
      if (unique.containsKey(key)) {
        duplicated.add(key);
        unique.remove(key);
        continue;
      }
      if (!duplicated.contains(key)) {
        unique[key] = level.levelPath;
      }
    }
    return unique;
  }

  int _resolveMatchWorkers(int totalSongs) {
    if (totalSongs < 1500) return 1;
    final cpu = Platform.numberOfProcessors;
    final suggested = math.max(2, cpu - 1);
    return math.min(8, suggested);
  }

  List<_PlaylistMatchChunk> _buildMatchChunks(
      List<PlaylistInfo> infos, int workers) {
    final totalSongs = _countSongs(infos);
    final targetPerChunk = math.max(200, (totalSongs / workers).ceil());
    final chunks = <_PlaylistMatchChunk>[];
    var payload = <Map<String, dynamic>>[];
    var songCount = 0;

    void flush() {
      if (payload.isEmpty) return;
      chunks.add(_PlaylistMatchChunk(
        payload: payload,
        songCount: songCount,
      ));
      payload = <Map<String, dynamic>>[];
      songCount = 0;
    }

    for (var i = 0; i < infos.length; i++) {
      final info = infos[i];
      final songsPayload = info.songs
          .map((song) => <String, String?>{
                'key': song.key,
                'hash': song.hash,
                'songName': song.songName,
              })
          .toList(growable: false);
      payload.add({
        'index': i,
        'songs': songsPayload,
      });
      songCount += info.songs.length;
      if (songCount >= targetPerChunk) {
        flush();
      }
    }
    flush();
    return chunks;
  }

  String _extractDirectoryKey(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    final firstToken = normalized.split(RegExp(r'[\s(_-]')).first.trim();
    if (firstToken.isEmpty) return '';
    final key = firstToken
        .replaceFirst(RegExp(r'^customlevel'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return key;
  }

  Iterable<String> _extractHashCandidates(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    final candidates = <String>{};
    final compact = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final noPrefix = compact.replaceFirst(RegExp(r'^customlevel'), '');
    if (noPrefix.isNotEmpty) {
      candidates.add(noPrefix);
    }

    final firstToken = normalized.split(RegExp(r'[\s(_-]')).first.trim();
    if (firstToken.isNotEmpty) {
      candidates.add(firstToken.replaceAll(RegExp(r'[^a-z0-9]'), ''));
    }

    final hashMatches = RegExp(r'[a-f0-9]{6,40}')
        .allMatches(normalized)
        .map((m) => m.group(0))
        .whereType<String>();
    candidates.addAll(hashMatches);
    candidates.removeWhere((s) => s.isEmpty);
    return candidates;
  }

  String _normalizeSongName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _songKey(PlaylistSong song) {
    if (song.key.trim().isNotEmpty) return song.key.trim().toLowerCase();
    return song.hash.trim().toLowerCase();
  }

  List<_BatchCandidate> _collectBatchCandidates(
    List<PlaylistSongWithStatus> songs, {
    required bool includeExistingUpdates,
    required bool forceUpdateExisting,
  }) {
    final candidates = <_BatchCandidate>[];
    for (final song in songs) {
      if (song.downloading) continue;
      final reason = _resolveUpdateReason(
        song,
        includeExistingUpdates: includeExistingUpdates,
        forceUpdateExisting: forceUpdateExisting,
      );
      if (reason != null) {
        candidates.add(_BatchCandidate(song: song, reason: reason));
      }
    }
    return candidates;
  }

  String? _resolveUpdateReason(
    PlaylistSongWithStatus song, {
    required bool includeExistingUpdates,
    required bool forceUpdateExisting,
  }) {
    if (song.matchedLevel == null) {
      return 'missing';
    }
    if (!includeExistingUpdates) {
      return null;
    }
    if (forceUpdateExisting) {
      return 'force';
    }
    final level = song.matchedLevel!;
    if (!Directory(level.levelPath).existsSync()) {
      return 'missing';
    }
    final localDirName = p.basename(level.levelPath).toLowerCase();
    final songKey = _extractDirectoryKey(
      song.song.key.isNotEmpty ? song.song.key : song.song.hash,
    );
    final localKey = _extractDirectoryKey(localDirName);
    if (songKey.isNotEmpty && localKey.isNotEmpty && songKey != localKey) {
      return 'version_mismatch';
    }
    return null;
  }

  List<PlaylistWithStatus> _buildPlaylists(
    List<PlaylistInfo> infos,
    List<LevelMetadata> levels, {
    int? totalSongsOverride,
    Map<String, String> cachedHashPathIndex = const {},
    void Function(int processed, int total)? onSongProgress,
  }) {
    final keyIndex = _buildKeyIndex(levels);
    final hashIndex = _buildHashIndex(
      levels,
      cachedHashPathIndex: cachedHashPathIndex,
    );
    final songNameIndex = _buildSongNameIndex(levels);
    final keyMatchCache = <String, LevelMetadata?>{};
    final hashMatchCache = <String, LevelMetadata?>{};
    final songNameMatchCache = <String, LevelMetadata?>{};

    final totalSongs = totalSongsOverride ?? _countSongs(infos);
    var processedSongs = 0;
    var lastReportedSongs = -1;

    void reportProgress() {
      if (onSongProgress == null) return;
      if (processedSongs == totalSongs ||
          lastReportedSongs < 0 ||
          processedSongs - lastReportedSongs >= 400) {
        lastReportedSongs = processedSongs;
        onSongProgress(processedSongs, totalSongs);
      }
    }

    if (totalSongs == 0) {
      onSongProgress?.call(0, 0);
    }

    final playlistStatuses = <PlaylistWithStatus>[];
    for (final info in infos) {
      final songs = <PlaylistSongWithStatus>[];
      for (final song in info.songs) {
        final matched = _matchLevelWithCache(
          song: song,
          keyIndex: keyIndex,
          hashIndex: hashIndex,
          songNameIndex: songNameIndex,
          keyMatchCache: keyMatchCache,
          hashMatchCache: hashMatchCache,
          songNameMatchCache: songNameMatchCache,
        );
        final key = _songKey(song);
        songs.add(PlaylistSongWithStatus(
          song: song,
          matchedLevel: matched,
          downloading: _downloadingHashes.contains(key),
          downloadError: _downloadErrors[key],
        ));
        processedSongs++;
        reportProgress();
      }
      playlistStatuses.add(PlaylistWithStatus(
        info: info,
        songs: songs,
        matchedCount: songs.where((s) => s.matchedLevel != null).length,
        configuredCount:
            songs.where((s) => s.matchedLevel?.cinemaConfig != null).length,
      ));
    }

    return playlistStatuses;
  }

  LevelMetadata? _matchLevelWithCache({
    required PlaylistSong song,
    required Map<String, LevelMetadata> keyIndex,
    required Map<String, LevelMetadata> hashIndex,
    required Map<String, LevelMetadata> songNameIndex,
    required Map<String, LevelMetadata?> keyMatchCache,
    required Map<String, LevelMetadata?> hashMatchCache,
    required Map<String, LevelMetadata?> songNameMatchCache,
  }) {
    if (song.key.isNotEmpty) {
      final extractedKey = _extractDirectoryKey(song.key);
      if (extractedKey.isNotEmpty) {
        final cacheKey = 'k:$extractedKey';
        if (keyMatchCache.containsKey(cacheKey)) {
          final cached = keyMatchCache[cacheKey];
          if (cached != null) return cached;
        } else {
          final matched = keyIndex[extractedKey];
          keyMatchCache[cacheKey] = matched;
          if (matched != null) return matched;
        }
      }
    }

    if (song.hash.isNotEmpty) {
      final hashRaw = song.hash.trim().toLowerCase();
      final cacheKey = 'h:$hashRaw';
      if (hashMatchCache.containsKey(cacheKey)) {
        final cached = hashMatchCache[cacheKey];
        if (cached != null) return cached;
      } else {
        LevelMetadata? matched;
        for (final candidate in _extractHashCandidates(hashRaw)) {
          matched = hashIndex[candidate];
          if (matched != null) break;
        }
        hashMatchCache[cacheKey] = matched;
        if (matched != null) return matched;
      }
    }

    final songName = song.songName;
    if (songName != null && songName.trim().isNotEmpty) {
      final normalizedName = _normalizeSongName(songName);
      final cacheKey = 'n:$normalizedName';
      if (songNameMatchCache.containsKey(cacheKey)) {
        return songNameMatchCache[cacheKey];
      }
      final matched = songNameIndex[normalizedName];
      songNameMatchCache[cacheKey] = matched;
      return matched;
    }
    return null;
  }

  PlaylistLoaded _buildLoadedState({
    bool exporting = false,
    double exportProgress = 0,
    ExportResult? exportResult,
    PlaylistRebuildNotice? rebuildNotice,
  }) {
    return PlaylistLoaded(
      playlists: _playlists,
      selectedIndex: _selectedIndex,
      filterUnconfigured: _filterUnconfigured,
      exporting: exporting,
      exportProgress: exportProgress,
      exportResult: exportResult ?? _latestExportResult,
      rebuildNotice: rebuildNotice,
    );
  }

  Future<ExportResult> _runExport({
    required PlaylistWithStatus playlist,
    required String targetPath,
    required Emitter<PlaylistState> emit,
    required List<ExportFailureItem>? onlyFailures,
  }) async {
    final now = DateTime.now();
    final failures = <ExportFailureItem>[];
    var successCount = 0;

    final failureMap = onlyFailures == null
        ? <String, ExportFailureItem>{}
        : {
            for (final f in onlyFailures)
              _exportFailureKey(
                hash: f.hash,
                songName: f.songName,
              ): f,
          };
    final songsToExport = onlyFailures == null
        ? playlist.songs
        : playlist.songs.where((song) {
            final key = _exportFailureKey(
              hash: song.song.hash,
              songName: song.song.songName,
            );
            return failureMap.containsKey(key);
          }).toList();

    final total = songsToExport.isEmpty ? 1 : songsToExport.length + 1;
    emit(_buildLoadedState(exporting: true, exportProgress: 0));

    try {
      final srcPlaylistFile = File(playlist.info.filePath);
      final playlistFileName = p.basename(playlist.info.filePath);
      final destPlaylistFile = File(p.join(targetPath, playlistFileName));
      await destPlaylistFile.parent.create(recursive: true);
      await srcPlaylistFile.copy(destPlaylistFile.path);
    } catch (e) {
      failures.add(ExportFailureItem(
        songName: playlist.info.title,
        hash: '-',
        reason: 'playlist_copy_failed: $e',
        timestamp: now,
      ));
    }

    for (var i = 0; i < songsToExport.length; i++) {
      emit(_buildLoadedState(
        exporting: true,
        exportProgress: (i + 1) / total,
      ));
      final song = songsToExport[i];
      final title = song.song.songName?.trim().isNotEmpty == true
          ? song.song.songName!
          : song.song.hash;

      if (song.matchedLevel == null) {
        failures.add(ExportFailureItem(
          songName: title,
          hash: song.song.hash,
          reason: 'not_downloaded',
          timestamp: DateTime.now(),
        ));
        continue;
      }
      try {
        final level = song.matchedLevel!;
        final srcDir = Directory(level.levelPath);
        final destDir =
            Directory(p.join(targetPath, p.basename(level.levelPath)));
        await _copyDirectory(srcDir, destDir);
        successCount++;
      } catch (e) {
        failures.add(ExportFailureItem(
          songName: title,
          hash: song.song.hash,
          reason: 'copy_failed: $e',
          timestamp: DateTime.now(),
          levelPath: song.matchedLevel?.levelPath,
        ));
      }
    }

    String? reportPath;
    if (failures.isNotEmpty) {
      reportPath = await _writeFailureReport(targetPath, failures);
    }

    return ExportResult(
      successCount: successCount,
      failedCount: failures.length,
      targetPath: targetPath,
      failureReportPath: reportPath,
      failures: failures,
    );
  }

  Future<String> _writeFailureReport(
      String targetPath, List<ExportFailureItem> failures) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      p.join(targetPath, 'playlist_export_failures_$timestamp.json'),
    );
    final payload = {
      'generatedAt': DateTime.now().toIso8601String(),
      'failures': failures.map((e) => e.toMap()).toList(),
    };
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return file.path;
  }

  String _exportFailureKey({
    required String hash,
    String? songName,
  }) {
    final normalizedHash = hash.trim().toLowerCase();
    final normalizedSongName = (songName == null || songName.trim().isEmpty)
        ? normalizedHash
        : songName.trim().toLowerCase();
    return '$normalizedHash:$normalizedSongName';
  }

  static Future<void> _copyDirectory(
      Directory source, Directory destination) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }
    await for (final entity in source.list()) {
      final newPath = p.join(destination.path, p.basename(entity.path));
      if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      }
    }
  }

  @override
  Future<void> close() async {
    await _downloadSub?.cancel();
    return super.close();
  }
}

class _BatchCandidate {
  final PlaylistSongWithStatus song;
  final String reason;
  const _BatchCandidate({required this.song, required this.reason});
}

class _PlaylistMatchChunk {
  final List<Map<String, dynamic>> payload;
  final int songCount;

  const _PlaylistMatchChunk({
    required this.payload,
    required this.songCount,
  });
}

List<Map<String, dynamic>> _matchPlaylistChunkWorker(
    Map<String, dynamic> input) {
  final playlists = (input['playlists'] as List).cast<Map<String, dynamic>>();
  final keyIndex = (input['keyIndex'] as Map).cast<String, String>();
  final hashIndex = (input['hashIndex'] as Map).cast<String, String>();
  final songNameIndex = (input['songNameIndex'] as Map).cast<String, String>();

  final results = <Map<String, dynamic>>[];
  for (final playlist in playlists) {
    final playlistIndex = playlist['index'] as int;
    final songs = (playlist['songs'] as List).cast<Map<String, dynamic>>();
    final matchedPaths = <String?>[];
    for (final song in songs) {
      final key = (song['key'] as String? ?? '').trim().toLowerCase();
      final hash = (song['hash'] as String? ?? '').trim().toLowerCase();
      final songName = (song['songName'] as String? ?? '').trim().toLowerCase();

      String? matchedPath;
      if (key.isNotEmpty) {
        final extractedKey = _extractDirectoryKeyWorker(key);
        if (extractedKey.isNotEmpty) {
          matchedPath = keyIndex[extractedKey];
        }
      }
      if (matchedPath == null && hash.isNotEmpty) {
        for (final candidate in _extractHashCandidatesWorker(hash)) {
          matchedPath = hashIndex[candidate];
          if (matchedPath != null) break;
        }
      }
      if (matchedPath == null && songName.isNotEmpty) {
        matchedPath = songNameIndex[_normalizeSongNameWorker(songName)];
      }
      matchedPaths.add(matchedPath);
    }
    results.add({
      'index': playlistIndex,
      'matchedPaths': matchedPaths,
    });
  }
  return results;
}

String _extractDirectoryKeyWorker(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return '';
  final firstToken = normalized.split(RegExp(r'[\s(_-]')).first.trim();
  if (firstToken.isEmpty) return '';
  final key = firstToken
      .replaceFirst(RegExp(r'^customlevel'), '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  return key;
}

Iterable<String> _extractHashCandidatesWorker(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return const [];

  final candidates = <String>{};
  final compact = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');
  final noPrefix = compact.replaceFirst(RegExp(r'^customlevel'), '');
  if (noPrefix.isNotEmpty) {
    candidates.add(noPrefix);
  }

  final firstToken = normalized.split(RegExp(r'[\s(_-]')).first.trim();
  if (firstToken.isNotEmpty) {
    candidates.add(firstToken.replaceAll(RegExp(r'[^a-z0-9]'), ''));
  }

  final hashMatches = RegExp(r'[a-f0-9]{6,40}')
      .allMatches(normalized)
      .map((m) => m.group(0))
      .whereType<String>();
  candidates.addAll(hashMatches);
  candidates.removeWhere((s) => s.isEmpty);
  return candidates;
}

String _normalizeSongNameWorker(String name) {
  return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
