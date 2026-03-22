import 'dart:async';
import 'dart:io';

import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Services/services/cache_service.dart';
import 'package:beat_cinema/Services/services/level_parse_service.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

part 'custom_levels_event.dart';
part 'custom_levels_state.dart';

class CustomLevelsBloc extends Bloc<CustomLevelsEvent, CustomLevelsState> {
  final LevelParseService _parseService;
  final CacheService _cacheService;

  List<LevelMetadata> _allLevels = [];
  String _searchQuery = '';
  FilterCriteria _filter = const FilterCriteria();
  SortField _sortField = SortField.songName;
  SortDirection _sortDirection = SortDirection.ascending;

  CustomLevelsBloc({
    LevelParseService? parseService,
    CacheService? cacheService,
  })  : _parseService = parseService ?? LevelParseService(),
        _cacheService = cacheService ?? CacheService(),
        super(CustomLevelsInitial()) {
    on<ReloadCustomLevelsEvent>(_onReload);
    on<LoadCachedCustomLevelsEvent>(_onLoadCached);
    on<SearchQueryChanged>(_onSearchChanged);
    on<FilterChanged>(_onFilterChanged);
    on<SortChanged>(_onSortChanged);
  }

  Future<void> _onReload(
      ReloadCustomLevelsEvent event, Emitter<CustomLevelsState> emit) async {
    log.i('[CustomLevels] reload start path=${event.beatSaberPath}');
    final cached = _cacheService.getAll();
    final hasCache = cached.isNotEmpty;

    emit(CustomLevelsLoading(hasCache: hasCache, cachedLevels: cached));

    try {
      final sw = Stopwatch()..start();
      final parsed = await _reloadWithCacheAwareIncremental(
        beatSaberPath: event.beatSaberPath,
        cached: cached,
        onProgress: (parsed, total) {
          emit(
            CustomLevelsLoading(
              parsed: parsed,
              total: total,
              stage: CustomLevelsLoadingStage.parsing,
              hasCache: hasCache,
              cachedLevels: cached,
            ),
          );
        },
      );
      unawaited(_cacheService.putAll(parsed));
      sw.stop();
      _allLevels = parsed;
      _searchQuery = '';
      _filter = const FilterCriteria();
      log.i(
        '[CustomLevels] reload parsed=${parsed.length} '
        'hasCache=$hasCache includeMapHash=false elapsedMs=${sw.elapsedMilliseconds}',
      );
      emit(_buildLoadedState());
    } catch (e) {
      if (hasCache) {
        log.w(
          '[CustomLevels] reload failed, fallback to cache '
          'cached=${cached.length} error=$e',
        );
        _allLevels = cached;
        emit(_buildLoadedState());
      } else {
        emit(CustomLevelsError(e.toString()));
      }
    }
  }

  Future<List<LevelMetadata>> _reloadWithCacheAwareIncremental({
    required String beatSaberPath,
    required List<LevelMetadata> cached,
    void Function(int parsed, int total)? onProgress,
  }) async {
    if (cached.isEmpty) {
      final allDirs = await _listLevelDirectories(beatSaberPath);
      return _parseDirectoriesWithProgress(
        allDirs,
        includeMapHash: false,
        onProgress: onProgress,
      );
    }

    final dirs = await _listLevelDirectories(beatSaberPath);
    if (dirs.isEmpty) {
      onProgress?.call(0, 0);
      return const [];
    }

    final staleDirs = _cacheService.findStale(dirs);
    final currentDirSet = dirs.map((e) => e.trim().toLowerCase()).toSet();
    final merged = <String, LevelMetadata>{
      for (final level in cached)
        if (currentDirSet.contains(level.levelPath.trim().toLowerCase()))
          level.levelPath.trim().toLowerCase(): level,
    };

    final total = dirs.length;
    var parsed = total - staleDirs.length;
    onProgress?.call(parsed, total);

    if (staleDirs.isNotEmpty) {
      final parsedStale = await _parseDirectoriesWithProgress(
        staleDirs,
        includeMapHash: false,
        onProgress: (chunkParsed, _) {
          onProgress?.call(parsed + chunkParsed, total);
        },
      );
      parsed = total;
      onProgress?.call(parsed, total);
      for (final level in parsedStale) {
        merged[level.levelPath.trim().toLowerCase()] = level;
      }
    }

    final results = <LevelMetadata>[];
    for (final dir in dirs) {
      final hit = merged[dir.trim().toLowerCase()];
      if (hit != null) {
        results.add(hit);
      }
    }
    return results;
  }

  Future<List<LevelMetadata>> _parseDirectoriesWithProgress(
    List<String> dirs, {
    required bool includeMapHash,
    void Function(int parsed, int total)? onProgress,
  }) async {
    if (dirs.isEmpty) {
      onProgress?.call(0, 0);
      return const [];
    }
    const chunkSize = 400;
    final results = <LevelMetadata>[];
    var parsed = 0;
    final total = dirs.length;
    onProgress?.call(parsed, total);
    for (var i = 0; i < dirs.length; i += chunkSize) {
      final end = (i + chunkSize < dirs.length) ? i + chunkSize : dirs.length;
      final chunk = dirs.sublist(i, end);
      final parsedChunk = await _parseService.parseDirectories(
        chunk,
        includeMapHash: includeMapHash,
      );
      results.addAll(parsedChunk);
      parsed += chunk.length;
      onProgress?.call(parsed, total);
    }
    return results;
  }

  Future<List<String>> _listLevelDirectories(String beatSaberPath) async {
    final customLevelsPath =
        p.join(beatSaberPath, Constants.dataDir, Constants.customLevelsDir);
    final dir = Directory(customLevelsPath);
    if (!await dir.exists()) return const [];
    return dir.list().where((e) => e is Directory).map((e) => e.path).toList();
  }

  Future<void> _onLoadCached(LoadCachedCustomLevelsEvent event,
      Emitter<CustomLevelsState> emit) async {
    log.i('[CustomLevels] load cache start');
    await _cacheService.init();
    final cached = _cacheService.getAll();
    if (cached.isNotEmpty) {
      log.i('[CustomLevels] cache loaded count=${cached.length}');
      _allLevels = cached;
      emit(_buildLoadedState());
    }
  }

  void _onSearchChanged(
      SearchQueryChanged event, Emitter<CustomLevelsState> emit) {
    _searchQuery = event.query;
    emit(_buildLoadedState());
  }

  void _onFilterChanged(FilterChanged event, Emitter<CustomLevelsState> emit) {
    _filter = event.criteria;
    emit(_buildLoadedState());
  }

  void _onSortChanged(SortChanged event, Emitter<CustomLevelsState> emit) {
    _sortField = event.field;
    _sortDirection = event.direction;
    emit(_buildLoadedState());
  }

  CustomLevelsLoaded _buildLoadedState() {
    var list = List<LevelMetadata>.from(_allLevels);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((l) {
        return l.songName.toLowerCase().contains(q) ||
            l.songSubName.toLowerCase().contains(q) ||
            l.songAuthorName.toLowerCase().contains(q) ||
            l.levelAuthorName.toLowerCase().contains(q);
      }).toList();
    }

    if (_filter.difficulties.isNotEmpty) {
      list = list.where((l) {
        return l.difficulties.any((d) => _filter.difficulties.contains(d));
      }).toList();
    }
    if (_filter.videoStatuses.isNotEmpty) {
      list = list.where((l) {
        return _filter.videoStatuses.contains(l.videoStatus);
      }).toList();
    }

    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case SortField.songName:
          cmp = a.songName.toLowerCase().compareTo(b.songName.toLowerCase());
        case SortField.songAuthor:
          cmp = a.songAuthorName
              .toLowerCase()
              .compareTo(b.songAuthorName.toLowerCase());
        case SortField.bpm:
          cmp = a.bpm.compareTo(b.bpm);
        case SortField.lastModified:
          cmp = a.lastModified.compareTo(b.lastModified);
      }
      return _sortDirection == SortDirection.ascending ? cmp : -cmp;
    });

    return CustomLevelsLoaded(
      allLevels: _allLevels,
      filteredLevels: list,
      searchQuery: _searchQuery,
      filter: _filter,
      sortField: _sortField,
      sortDirection: _sortDirection,
    );
  }
}
