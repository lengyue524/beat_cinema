import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:beat_cinema/Services/managers/download_manager.dart';
import 'package:beat_cinema/Services/repositories/video_repository.dart';
import 'package:beat_cinema/Services/services/beatsaver_download_service.dart';
import 'package:beat_cinema/Services/services/level_parse_service.dart';
import 'package:beat_cinema/Services/services/playlist_parse_service.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

part 'playlist_event.dart';
part 'playlist_state.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final PlaylistParseService _parseService;
  final LevelParseService _levelParseService;
  final BeatSaverDownloadService _beatSaverDownloadService;
  final DownloadManager? _downloadManager;

  List<PlaylistWithStatus> _playlists = [];
  int? _selectedIndex;
  bool _filterUnconfigured = false;
  String? _currentBeatSaberPath;

  final Map<String, String> _taskIdToSongHash = {};
  final Set<String> _downloadingHashes = {};
  final Map<String, String> _downloadErrors = {};
  StreamSubscription<List<DownloadTask>>? _downloadSub;
  ExportResult? _latestExportResult;

  PlaylistBloc({
    PlaylistParseService? parseService,
    LevelParseService? levelParseService,
    BeatSaverDownloadService? beatSaverDownloadService,
    DownloadManager? downloadManager,
  })
      : _parseService = parseService ?? PlaylistParseService(),
        _levelParseService = levelParseService ?? LevelParseService(),
        _beatSaverDownloadService =
            beatSaverDownloadService ?? BeatSaverDownloadService(),
        _downloadManager = downloadManager,
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

    _downloadSub = _downloadManager?.taskStream.listen((_) {
      add(DownloadTasksUpdatedEvent());
    });
  }

  Future<void> _onLoad(
      LoadPlaylistsEvent event, Emitter<PlaylistState> emit) async {
    emit(PlaylistLoading());
    try {
      _currentBeatSaberPath = event.beatSaberPath;
      final raw = await _parseService.parseAll(event.beatSaberPath);
      _playlists = _buildPlaylists(raw, event.levels);

      _selectedIndex = null;
      _filterUnconfigured = false;
      emit(_buildLoadedState());
    } catch (e) {
      emit(PlaylistError(e.toString()));
    }
  }

  void _onSelect(
      SelectPlaylistEvent event, Emitter<PlaylistState> emit) {
    _selectedIndex = event.index;
    emit(_buildLoadedState());
  }

  void _onDeselect(
      DeselectPlaylistEvent event, Emitter<PlaylistState> emit) {
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
    if (hash.isEmpty || _downloadManager == null || _currentBeatSaberPath == null) {
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
      runner: (task, onProgress) => _beatSaverDownloadService.downloadSongByHash(
        taskId: task.taskId,
        beatSaberPath: _currentBeatSaberPath!,
        hash: hash,
        titleHint: title,
        onProgress: onProgress,
      ),
    );
    _taskIdToSongHash[taskId] = hash;
    emit(_buildLoadedState());
  }

  Future<void> _onDownloadAllMissingSongs(
      DownloadAllMissingSongsEvent event, Emitter<PlaylistState> emit) async {
    if (_selectedIndex == null || _downloadManager == null || _currentBeatSaberPath == null) {
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
        runner: (task, onProgress) => _beatSaverDownloadService.downloadSongByHash(
          taskId: task.taskId,
          beatSaberPath: _currentBeatSaberPath!,
          hash: hash,
          titleHint: songName,
          onProgress: onProgress,
        ),
      );
      _taskIdToSongHash[taskId] = hash;
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

  Future<void> _onDownloadTasksUpdated(
      DownloadTasksUpdatedEvent event, Emitter<PlaylistState> emit) async {
    final manager = _downloadManager;
    if (manager == null) return;
    final taskMap = {
      for (final task in manager.tasks) task.taskId: task,
    };

    var changed = false;
    var needReload = false;
    final entries = _taskIdToSongHash.entries.toList();
    for (final entry in entries) {
      final task = taskMap[entry.key];
      if (task == null) continue;
      final songHash = entry.value;
      if (task.status == DownloadStatus.pending ||
          task.status == DownloadStatus.downloading) {
        if (_downloadingHashes.add(songHash)) changed = true;
      } else if (task.status == DownloadStatus.completed) {
        _downloadingHashes.remove(songHash);
        _downloadErrors.remove(songHash);
        _taskIdToSongHash.remove(entry.key);
        needReload = true;
        changed = true;
      } else if (task.status == DownloadStatus.failed) {
        _downloadingHashes.remove(songHash);
        _downloadErrors[songHash] = task.errorMessage ?? 'Download failed';
        _taskIdToSongHash.remove(entry.key);
        changed = true;
      } else if (task.status == DownloadStatus.cancelled) {
        _downloadingHashes.remove(songHash);
        _taskIdToSongHash.remove(entry.key);
        changed = true;
      }
    }

    if (needReload && _currentBeatSaberPath != null) {
      final levels = await _levelParseService.parseAll(_currentBeatSaberPath!);
      final raw = await _parseService.parseAll(_currentBeatSaberPath!);
      _playlists = _buildPlaylists(raw, levels);
      if (_selectedIndex != null && _selectedIndex! >= _playlists.length) {
        _selectedIndex = null;
      }
    }

    if (changed || needReload) {
      emit(_buildLoadedState());
    }
  }

  Map<String, LevelMetadata> _buildHashIndex(List<LevelMetadata> levels) {
    final index = <String, LevelMetadata>{};
    for (final level in levels) {
      final dirName = p.basename(level.levelPath).toLowerCase();
      for (final candidate in _extractHashCandidates(dirName)) {
        index.putIfAbsent(candidate, () => level);
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

  LevelMetadata? _matchLevel(
    PlaylistSong song,
    Map<String, LevelMetadata> hashIndex,
    Map<String, LevelMetadata> songNameIndex,
  ) {
    for (final candidate in _extractHashCandidates(song.hash)) {
      final byHash = hashIndex[candidate];
      if (byHash != null) return byHash;
    }

    final songName = song.songName;
    if (songName != null && songName.trim().isNotEmpty) {
      final byName = songNameIndex[_normalizeSongName(songName)];
      if (byName != null) return byName;
    }
    return null;
  }

  Iterable<String> _extractHashCandidates(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    final candidates = <String>{};
    final compact =
        normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final noPrefix = compact.replaceFirst(RegExp(r'^customlevel'), '');
    if (noPrefix.isNotEmpty) {
      candidates.add(noPrefix);
    }

    final firstToken = normalized.split(RegExp(r'[\s(_-]')).first.trim();
    if (firstToken.isNotEmpty) {
      candidates.add(firstToken.replaceAll(RegExp(r'[^a-z0-9]'), ''));
    }

    final hashMatches = RegExp(r'[a-f0-9]{5,40}')
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

  String _songKey(PlaylistSong song) => song.hash.trim().toLowerCase();

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
    final songHashCandidates = _extractHashCandidates(song.song.hash).toSet();
    final localHashCandidates = _extractHashCandidates(localDirName).toSet();
    if (songHashCandidates.isNotEmpty &&
        localHashCandidates.isNotEmpty &&
        songHashCandidates.intersection(localHashCandidates).isEmpty) {
      return 'version_mismatch';
    }
    return null;
  }

  List<PlaylistWithStatus> _buildPlaylists(
      List<PlaylistInfo> infos, List<LevelMetadata> levels) {
    final hashIndex = _buildHashIndex(levels);
    final songNameIndex = _buildSongNameIndex(levels);
    return infos.map((info) {
      final songs = info.songs.map((song) {
        final matched = _matchLevel(song, hashIndex, songNameIndex);
        final key = _songKey(song);
        return PlaylistSongWithStatus(
          song: song,
          matchedLevel: matched,
          downloading: _downloadingHashes.contains(key),
          downloadError: _downloadErrors[key],
        );
      }).toList();
      return PlaylistWithStatus(
        info: info,
        songs: songs,
        matchedCount: songs.where((s) => s.matchedLevel != null).length,
        configuredCount: songs
            .where((s) => s.matchedLevel?.cinemaConfig != null)
            .length,
      );
    }).toList();
  }

  PlaylistLoaded _buildLoadedState({
    bool exporting = false,
    double exportProgress = 0,
    ExportResult? exportResult,
  }) {
    return PlaylistLoaded(
      playlists: _playlists,
      selectedIndex: _selectedIndex,
      filterUnconfigured: _filterUnconfigured,
      exporting: exporting,
      exportProgress: exportProgress,
      exportResult: exportResult ?? _latestExportResult,
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
        final destDir = Directory(p.join(targetPath, p.basename(level.levelPath)));
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
