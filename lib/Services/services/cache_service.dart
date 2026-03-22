import 'dart:convert';
import 'dart:io';

import 'package:beat_cinema/models/level_metadata.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CacheService {
  final Map<String, LevelMetadata> _memoryCache = {};
  File? _cacheFile;

  Map<String, LevelMetadata> get memoryCache =>
      Map.unmodifiable(_memoryCache);

  Future<void> init() async {
    final appDir = await getApplicationSupportDirectory();
    _cacheFile = File(p.join(appDir.path, 'level_cache.json'));
    await _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    if (_cacheFile == null || !await _cacheFile!.exists()) return;
    try {
      final jsonStr = await _cacheFile!.readAsString();
      final list = json.decode(jsonStr) as List<dynamic>;
      for (final item in list) {
        final meta =
            LevelMetadata.fromMap(item as Map<String, dynamic>);
        _memoryCache[meta.levelPath] = meta;
      }
    } catch (_) {
      _memoryCache.clear();
    }
  }

  Future<void> _saveToDisk() async {
    if (_cacheFile == null) return;
    final tmpFile = File('${_cacheFile!.path}.tmp');
    try {
      final list = _memoryCache.values.map((m) => m.toMap()).toList();
      await tmpFile.writeAsString(json.encode(list), flush: true);
      await tmpFile.rename(_cacheFile!.path);
    } catch (_) {
      try { await tmpFile.delete(); } catch (_) {}
    }
  }

  List<LevelMetadata> getAll() => _memoryCache.values.toList();

  LevelMetadata? get(String path) => _memoryCache[path];

  bool isStale(String dirPath) {
    final cached = _memoryCache[dirPath];
    if (cached == null) return true;
    try {
      final stat = Directory(dirPath).statSync();
      return stat.modified.isAfter(cached.lastModified);
    } catch (_) {
      return true;
    }
  }

  List<String> findStale(List<String> dirPaths) {
    return dirPaths.where((d) => isStale(d)).toList();
  }

  Future<void> putAll(List<LevelMetadata> items) async {
    for (final item in items) {
      _memoryCache[item.levelPath] = item;
    }
    await _saveToDisk();
  }

  Future<void> invalidate(String path) async {
    _memoryCache.remove(path);
    await _saveToDisk();
  }

  Future<void> invalidateAll() async {
    _memoryCache.clear();
    await _saveToDisk();
  }
}
