import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Core/errors/app_error.dart';
import 'package:beat_cinema/Services/services/proxy_service.dart';
import 'package:beat_cinema/models/dlp_video_info/dlp_video_info.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

class BbDownService {
  BbDownService({
    required this.beatSaberPath,
    this.proxyMode = ProxyMode.system,
    this.customProxy = '',
  });

  final String beatSaberPath;
  final ProxyMode proxyMode;
  final String customProxy;
  static const _githubRepos = <String>['nilaoda/BBDown', 'Jared-02/BBDown'];
  static const _safeUtf8Decoder = Utf8Decoder(allowMalformed: true);
  static const _searchTimeout = Duration(seconds: 30);
  static const _downloadTimeout = Duration(minutes: 10);
  static const _githubTimeout = Duration(seconds: 30);

  String get _bbdownPath =>
      p.join(beatSaberPath, Constants.libsDir, Constants.bbDownName);

  static Future<bool> isInstalled(String beatSaberPath) async {
    final path = p.join(beatSaberPath, Constants.libsDir, Constants.bbDownName);
    return File(path).exists();
  }

  Future<BbDownAuthState> getAuthState() async {
    final dataFile = await _resolveAuthDataFile();
    if (dataFile == null || !await dataFile.exists()) {
      return BbDownAuthState.notLoggedIn;
    }
    try {
      final content = await dataFile.readAsString();
      final normalized = content.toLowerCase();
      if (normalized.contains('sessdata') ||
          normalized.contains('access_token') ||
          normalized.contains('refresh_token')) {
        return BbDownAuthState.loggedIn;
      }
      return BbDownAuthState.unknown;
    } catch (_) {
      return BbDownAuthState.unknown;
    }
  }

  Future<bool> waitForLoginSuccess({
    Duration timeout = const Duration(minutes: 2),
    Duration interval = const Duration(seconds: 2),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      final state = await getAuthState();
      if (state == BbDownAuthState.loggedIn) {
        return true;
      }
      await Future.delayed(interval);
    }
    return false;
  }

  Future<void> launchInteractiveLogin() async {
    if (!await File(_bbdownPath).exists()) {
      throw const AppError(
        type: AppErrorType.process,
        userMessageKey: 'error_bbdown_not_found',
        retryable: false,
      );
    }
    try {
      final env = await _buildProcessEnv();
      final scriptFile = await _createLoginScript(env);
      await Process.start(
        'cmd.exe',
        [
          '/c',
          'start',
          '""',
          scriptFile.path,
        ],
        mode: ProcessStartMode.detached,
      );
      log.i(
        '[BbDownService] login script launched '
        'executable=$_bbdownPath script=${scriptFile.path}',
      );
    } catch (e, st) {
      log.e('[BbDownService] launch login failed error=$e', e, st);
      throw AppError.fromException(e, context: 'bbdown login');
    }
  }

  Future<String> downloadLatestToLibs() async {
    final libsDir = Directory(p.join(beatSaberPath, Constants.libsDir));
    await libsDir.create(recursive: true);
    final client = HttpClient();
    try {
      final proxyApplied = await _applyProxyToHttpClient(client);
      log.i(
        '[BbDownService] download latest start '
        'engine=bbdown-updater proxyApplied=$proxyApplied',
      );
      final asset = await _resolveLatestWindowsAsset(client);
      if (asset == null) {
        throw const AppError(
          type: AppErrorType.network,
          userMessageKey: 'error_bbdown_unknown',
          retryable: true,
        );
      }
      final tempPath = p.join(
        libsDir.path,
        '.bbdown_download_${DateTime.now().millisecondsSinceEpoch}',
      );
      final tempFile = File(tempPath);
      final request = await client
          .getUrl(Uri.parse(asset.downloadUrl))
          .timeout(_githubTimeout);
      request.headers.set(HttpHeaders.userAgentHeader, 'BeatCinema/1.0');
      request.followRedirects = true;
      final response = await request.close().timeout(_githubTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const AppError(
          type: AppErrorType.network,
          userMessageKey: 'error_bbdown_network',
          retryable: true,
        );
      }
      await response
          .pipe(tempFile.openWrite())
          .timeout(_downloadTimeout);

      if (asset.name.toLowerCase().endsWith('.exe')) {
        final bytes = await tempFile.readAsBytes();
        final path = await _writeExecutableBytes(bytes, libsDir.path);
        try {
          await tempFile.delete();
        } catch (_) {}
        return path;
      }

      if (asset.name.toLowerCase().endsWith('.zip')) {
        final bytes = await tempFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        ArchiveFile? exeEntry;
        for (final file in archive.files) {
          if (file.isFile && p.basename(file.name).toLowerCase() == 'bbdown.exe') {
            exeEntry = file;
            break;
          }
        }
        if (exeEntry == null) {
          throw const AppError(
            type: AppErrorType.fileSystem,
            userMessageKey: 'error_bbdown_unknown',
            retryable: false,
          );
        }
        final executableBytes = exeEntry.content as List<int>;
        final path = await _writeExecutableBytes(executableBytes, libsDir.path);
        try {
          await tempFile.delete();
        } catch (_) {}
        return path;
      }

      throw const AppError(
        type: AppErrorType.fileSystem,
        userMessageKey: 'error_bbdown_unknown',
        retryable: false,
      );
    } on AppError {
      rethrow;
    } catch (e, st) {
      log.e('[BbDownService] download latest failed error=$e', e, st);
      throw AppError.fromException(e, context: 'bbdown download latest');
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _writeExecutableBytes(List<int> bytes, String libsPath) async {
    final target = File(p.join(libsPath, Constants.bbDownName));
    final temp = File(p.join(libsPath, '${Constants.bbDownName}.new'));
    await temp.writeAsBytes(bytes, flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await temp.rename(target.path);
    log.i('[BbDownService] installed executable at ${target.path}');
    return target.path;
  }

  Future<_BbDownAsset?> _resolveLatestWindowsAsset(HttpClient client) async {
    for (final repo in _githubRepos) {
      final uri = Uri.https('api.github.com', '/repos/$repo/releases/latest');
      try {
        final request = await client.getUrl(uri).timeout(_githubTimeout);
        request.headers.set(HttpHeaders.userAgentHeader, 'BeatCinema/1.0');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close().timeout(_githubTimeout);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          continue;
        }
        final body = await response.transform(utf8.decoder).join();
        final map = json.decode(body) as Map<String, dynamic>;
        final assets = map['assets'];
        if (assets is! List) continue;
        final parsedAssets = assets.whereType<Map<String, dynamic>>().map((asset) {
          return _BbDownAsset(
            name: asset['name']?.toString() ?? '',
            downloadUrl: asset['browser_download_url']?.toString() ?? '',
          );
        }).where((asset) => asset.name.isNotEmpty && asset.downloadUrl.isNotEmpty).toList();
        final selected = _pickWindowsAsset(parsedAssets);
        if (selected != null) {
          log.i('[BbDownService] resolved release asset repo=$repo asset=${selected.name}');
          return selected;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  _BbDownAsset? _pickWindowsAsset(List<_BbDownAsset> assets) {
    final arch = _detectWindowsArch();
    log.i('[BbDownService] detect windows arch=$arch');

    _BbDownAsset? exactExe;
    _BbDownAsset? windowsArchZip;
    _BbDownAsset? windowsAnyZip;
    _BbDownAsset? windowsAnyExe;
    for (final asset in assets) {
      final name = asset.name.toLowerCase();
      if (name.startsWith('source_code.')) {
        continue;
      }
      final isWindows = name.contains('win') || name.contains('windows');
      if (!isWindows && name != 'bbdown.exe') {
        continue;
      }
      if (name == 'bbdown.exe') {
        exactExe = asset;
        continue;
      }
      final isExe = name.endsWith('.exe');
      final isZip = name.endsWith('.zip');
      final matchesArch = _assetMatchesArch(name, arch);
      if (isZip && matchesArch) {
        windowsArchZip ??= asset;
      } else if (isZip) {
        windowsAnyZip ??= asset;
      } else if (isExe) {
        windowsAnyExe ??= asset;
      }
    }
    final selected = exactExe ?? windowsArchZip ?? windowsAnyExe ?? windowsAnyZip;
    if (selected != null) {
      log.i(
        '[BbDownService] select asset name=${selected.name} arch=$arch',
      );
    }
    return selected;
  }

  bool _assetMatchesArch(String assetNameLower, String arch) {
    switch (arch) {
      case 'arm64':
        return assetNameLower.contains('arm64') ||
            assetNameLower.contains('aarch64');
      case 'x86':
        return assetNameLower.contains('x86') ||
            assetNameLower.contains('win32') ||
            assetNameLower.contains('386');
      case 'x64':
      default:
        return assetNameLower.contains('x64') ||
            assetNameLower.contains('amd64') ||
            assetNameLower.contains('x86_64');
    }
  }

  String _detectWindowsArch() {
    final env = Platform.environment;
    final raw = (env['PROCESSOR_ARCHITEW6432'] ??
            env['PROCESSOR_ARCHITECTURE'] ??
            '')
        .toLowerCase();
    if (raw.contains('arm64') || raw.contains('aarch64')) {
      return 'arm64';
    }
    if (raw.contains('x86')) {
      return 'x86';
    }
    if (raw.contains('amd64') || raw.contains('x64')) {
      return 'x64';
    }
    return 'x64';
  }

  Future<List<DlpVideoInfo>> search(String keyword, {int count = 20}) async {
    if (keyword.trim().isEmpty) return const [];
    final query = keyword.trim();
    final byBbDown = await _searchViaBbDown(query, count: count);
    if (byBbDown.isNotEmpty) {
      return byBbDown.take(count).toList(growable: false);
    }
    return _searchViaBilibiliApi(query, count: count);
  }

  Future<List<DlpVideoInfo>> _searchViaBbDown(
    String keyword, {
    required int count,
  }) async {
    if (!await File(_bbdownPath).exists()) {
      return const [];
    }
    final attempts = <List<String>>[
      ['search', keyword, '--page-size', '$count', '--json'],
      ['search', keyword, '--json'],
      ['search', keyword],
    ];
    final env = await _buildProcessEnv();
    for (final args in attempts) {
      try {
        final result = await Process.run(
          _bbdownPath,
          args,
          environment: env,
        ).timeout(_searchTimeout);
        if (result.exitCode != 0) continue;
        final parsed = _parseBbDownSearchOutput(result.stdout.toString());
        if (parsed.isNotEmpty) {
          log.i(
            '[BbDownService] bbdown search succeeded args=${args.join(' ')} '
            'count=${parsed.length}',
          );
          return parsed;
        }
      } catch (_) {
        // Try next command variant.
      }
    }
    return const [];
  }

  List<DlpVideoInfo> _parseBbDownSearchOutput(String stdout) {
    final results = <DlpVideoInfo>[];
    final trimmed = stdout.trim();
    if (trimmed.isEmpty) return results;

    dynamic root;
    try {
      root = json.decode(trimmed);
    } catch (_) {
      root = null;
    }

    if (root is List) {
      for (final item in root.whereType<Map<String, dynamic>>()) {
        final parsed = _mapBbDownResult(item);
        if (parsed != null) results.add(parsed);
      }
      return results;
    }

    if (root is Map<String, dynamic>) {
      final list = root['list'] ?? root['result'] ?? root['data'];
      if (list is List) {
        for (final item in list.whereType<Map<String, dynamic>>()) {
          final parsed = _mapBbDownResult(item);
          if (parsed != null) results.add(parsed);
        }
        return results;
      }
    }

    for (final line in trimmed.split('\n')) {
      final jsonLine = line.trim();
      if (!jsonLine.startsWith('{') || !jsonLine.endsWith('}')) continue;
      try {
        final map = json.decode(jsonLine) as Map<String, dynamic>;
        final parsed = _mapBbDownResult(map);
        if (parsed != null) results.add(parsed);
      } catch (_) {
        // Keep parsing remaining lines.
      }
    }
    return results;
  }

  DlpVideoInfo? _mapBbDownResult(Map<String, dynamic> map) {
    final title = _stripHtml(map['title']?.toString() ?? '');
    if (title.isEmpty) return null;
    final bvid = map['bvid']?.toString() ??
        map['bv_id']?.toString() ??
        map['id']?.toString() ??
        '';
    var url = map['url']?.toString() ?? map['webpage_url']?.toString() ?? '';
    if (url.isEmpty && bvid.startsWith('BV')) {
      url = 'https://www.bilibili.com/video/$bvid';
    }
    if (url.isEmpty) return null;
    return DlpVideoInfo(
      id: bvid,
      title: title,
      originalUrl: url,
      webpageUrl: url,
      durationString: map['duration']?.toString(),
      thumbnail: _normalizeThumbnail(map['pic']?.toString()),
    );
  }

  Future<List<DlpVideoInfo>> _searchViaBilibiliApi(
    String keyword, {
    required int count,
  }) async {
    final uri = Uri.https(
      'api.bilibili.com',
      '/x/web-interface/search/type',
      <String, String>{
        'search_type': 'video',
        'keyword': keyword,
        'page': '1',
        'page_size': '$count',
      },
    );
    final client = HttpClient();
    try {
      await _applyProxyToHttpClient(client);
      final request = await client.getUrl(uri).timeout(_searchTimeout);
      request.headers.set(HttpHeaders.userAgentHeader, 'BeatCinema/1.0');
      final response = await request.close().timeout(_searchTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }
      final body = await response.transform(utf8.decoder).join();
      final map = json.decode(body) as Map<String, dynamic>;
      final data = map['data'];
      if (data is! Map<String, dynamic>) return const [];
      final list = data['result'];
      if (list is! List) return const [];
      return list.whereType<Map<String, dynamic>>().map((item) {
        final bvid = item['bvid']?.toString() ?? '';
        final url = bvid.isNotEmpty
            ? 'https://www.bilibili.com/video/$bvid'
            : (item['arcurl']?.toString() ?? '');
        return DlpVideoInfo(
          id: bvid,
          title: _stripHtml(item['title']?.toString() ?? ''),
          originalUrl: url,
          webpageUrl: url,
          durationString: item['duration']?.toString(),
          thumbnail: _normalizeThumbnail(item['pic']?.toString()),
          uploader: item['author']?.toString(),
        );
      }).where((item) => (item.originalUrl ?? '').isNotEmpty).toList();
    } catch (e, st) {
      log.w('[BbDownService] search via api failed keyword="$keyword"', e, st);
      return const [];
    } finally {
      client.close(force: true);
    }
  }

  Future<String> downloadPlayableFile({
    required String url,
    required String outputDir,
  }) async {
    if (!await File(_bbdownPath).exists()) {
      throw const AppError(
        type: AppErrorType.process,
        userMessageKey: 'error_bbdown_not_found',
        retryable: false,
      );
    }
    final workDir = Directory(outputDir);
    await workDir.create(recursive: true);
    final args = [url];
    try {
      final env = await _buildProcessEnv();
      final process =
          await Process.start(
        _bbdownPath,
        args,
        workingDirectory: workDir.path,
        environment: env,
      );
      final stdoutFuture = process.stdout.transform(_safeUtf8Decoder).join();
      final stderrFuture = process.stderr.transform(_safeUtf8Decoder).join();
      final exitCode = await process.exitCode.timeout(_downloadTimeout);
      final stdout = await stdoutFuture;
      final stderr = await stderrFuture;
      final combined = '$stdout\n$stderr'.toLowerCase();
      if (exitCode != 0) {
        if (combined.contains('sessdata') || combined.contains('login')) {
          throw const AppError(
            type: AppErrorType.network,
            userMessageKey: 'error_bbdown_login_required',
            retryable: true,
          );
        }
        throw const AppError(
          type: AppErrorType.network,
          userMessageKey: 'error_bbdown_network',
          retryable: true,
        );
      }
      final file = _findPlayableFile(workDir.path);
      if (file == null) {
        throw const AppError(
          type: AppErrorType.fileSystem,
          userMessageKey: 'snack_video_file_unresolved',
          retryable: false,
        );
      }
      return file;
    } on TimeoutException catch (_) {
      throw const AppError(
        type: AppErrorType.network,
        userMessageKey: 'error_ytdlp_search_timeout',
        retryable: true,
      );
    }
  }

  String? _findPlayableFile(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return null;
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) {
          final ext = p.extension(file.path).toLowerCase();
          return ext == '.mp4' || ext == '.mkv' || ext == '.flv' || ext == '.webm';
        })
        .toList(growable: false);
    if (files.isEmpty) return null;
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files.first.path;
  }

  String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]+>'), '').trim();
  }

  String? _normalizeThumbnail(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    if (value.startsWith('//')) return 'https:$value';
    return value;
  }

  Future<Map<String, String>> _buildProcessEnv() async {
    final proxyUrl = await ProxyService.resolveProxyUrl(
      mode: proxyMode,
      customProxy: customProxy,
    );
    if (proxyUrl == null || proxyUrl.isEmpty) {
      return const {};
    }
    log.i('[BbDownService] apply process proxy $proxyUrl');
    return <String, String>{
      'HTTP_PROXY': proxyUrl,
      'HTTPS_PROXY': proxyUrl,
      'http_proxy': proxyUrl,
      'https_proxy': proxyUrl,
    };
  }

  Future<bool> _applyProxyToHttpClient(HttpClient client) async {
    final proxyUrl = await ProxyService.resolveProxyUrl(
      mode: proxyMode,
      customProxy: customProxy,
    );
    if (proxyUrl == null || proxyUrl.isEmpty) {
      return false;
    }
    final hostPort = _proxyHostPort(proxyUrl);
    client.findProxy = (_) => 'PROXY $hostPort';
    log.i('[BbDownService] apply http proxy $hostPort');
    return true;
  }

  String _proxyHostPort(String proxyUrl) {
    final uri = Uri.tryParse(proxyUrl);
    if (uri == null || uri.host.isEmpty || uri.port <= 0) {
      return proxyUrl;
    }
    return '${uri.host}:${uri.port}';
  }

  Future<File> _createLoginScript(Map<String, String> env) async {
    final file = File(
      p.join(
        Directory.systemTemp.path,
        'beat_cinema_bbdown_login_${DateTime.now().millisecondsSinceEpoch}.bat',
      ),
    );
    final buffer = StringBuffer()
      ..writeln('@echo off')
      ..writeln('chcp 65001 >nul')
      ..writeln('cd /d "${p.dirname(_bbdownPath)}"');
    final httpProxy = env['HTTP_PROXY'] ?? '';
    final httpsProxy = env['HTTPS_PROXY'] ?? '';
    if (httpProxy.isNotEmpty) {
      buffer.writeln('set "HTTP_PROXY=$httpProxy"');
      buffer.writeln('set "http_proxy=$httpProxy"');
    }
    if (httpsProxy.isNotEmpty) {
      buffer.writeln('set "HTTPS_PROXY=$httpsProxy"');
      buffer.writeln('set "https_proxy=$httpsProxy"');
    }
    buffer
      ..writeln('"${p.basename(_bbdownPath)}" login')
      ..writeln('echo.')
      ..writeln('echo [BeatCinema] BBDown login process finished. Press any key to close.')
      ..writeln('pause >nul');
    await file.writeAsString(buffer.toString(), flush: true);
    return file;
  }

  Future<File?> _resolveAuthDataFile() async {
    final candidates = <String>[
      p.join(p.dirname(_bbdownPath), 'BBDown.data'),
      if ((Platform.environment['APPDATA'] ?? '').isNotEmpty)
        p.join(Platform.environment['APPDATA']!, 'BBDown', 'BBDown.data'),
      if ((Platform.environment['USERPROFILE'] ?? '').isNotEmpty)
        p.join(
          Platform.environment['USERPROFILE']!,
          '.config',
          'BBDown',
          'BBDown.data',
        ),
    ];
    for (final candidate in candidates) {
      final file = File(candidate);
      if (await file.exists()) {
        return file;
      }
    }
    if (candidates.isEmpty) return null;
    return File(candidates.first);
  }
}

class _BbDownAsset {
  const _BbDownAsset({
    required this.name,
    required this.downloadUrl,
  });

  final String name;
  final String downloadUrl;
}

enum BbDownAuthState {
  notLoggedIn,
  loggedIn,
  unknown,
}
