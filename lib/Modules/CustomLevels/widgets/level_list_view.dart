import 'dart:async';
import 'dart:io';

import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Modules/CustomLevels/bloc/custom_levels_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/widgets/level_list_tile.dart';
import 'package:beat_cinema/Modules/CustomLevels/widgets/mini_audio_player_bar.dart';
import 'package:beat_cinema/Modules/Panel/context_menu_region.dart';
import 'package:beat_cinema/Modules/Panel/cubit/panel_cubit.dart';
import 'package:beat_cinema/Modules/Panel/video_preview_dialog.dart';
import 'package:beat_cinema/Services/managers/download_manager.dart';
import 'package:beat_cinema/Services/repositories/video_repository.dart';
import 'package:beat_cinema/Services/services/proxy_service.dart';
import 'package:beat_cinema/main.dart';
import 'package:beat_cinema/models/cinema_config/cinema_config.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;

/// A list item that is either a [LevelMetadata] or an opaque placeholder
/// rendered by [LevelListView.placeholderBuilder].
class LevelListItem {
  const LevelListItem.level(this.metadata) : placeholder = null;
  const LevelListItem.placeholder(this.placeholder) : metadata = null;

  final LevelMetadata? metadata;
  final Object? placeholder;

  bool get isLevel => metadata != null;
}

class MiniPlayerDisplayData {
  const MiniPlayerDisplayData({
    required this.songName,
    this.coverFilePath,
  });

  final String songName;
  final String? coverFilePath;
}

MiniPlayerDisplayData? resolveMiniPlayerDisplayData({
  required bool previewPlaying,
  required String? playingLevelPath,
  required List<LevelListItem> items,
  String? fallbackSongName,
  String? fallbackCoverFilePath,
}) {
  if (!previewPlaying) return null;
  final targetPath = (playingLevelPath ?? '').trim();
  if (targetPath.isNotEmpty) {
    for (final item in items) {
      final metadata = item.metadata;
      if (metadata == null) continue;
      if (metadata.levelPath == targetPath) {
        final coverFileName = (metadata.coverImageFilename ?? '').trim();
        final coverFilePath = coverFileName.isEmpty
            ? null
            : p.join(metadata.levelPath, coverFileName);
        return MiniPlayerDisplayData(
          songName: metadata.songName,
          coverFilePath: coverFilePath,
        );
      }
    }
  }

  final cachedName = (fallbackSongName ?? '').trim();
  if (cachedName.isEmpty) {
    return null;
  }
  final cachedCover = (fallbackCoverFilePath ?? '').trim();
  return MiniPlayerDisplayData(
    songName: cachedName,
    coverFilePath: cachedCover.isEmpty ? null : cachedCover,
  );
}

/// Self-contained list widget with audio/video preview and context menu.
///
/// Used by both CustomLevelsPage and PlaylistDetail.
class LevelListView extends StatefulWidget {
  const LevelListView({
    super.key,
    required this.items,
    this.placeholderBuilder,
    this.autoReloadAfterConfigDownload = true,
  });

  /// Ordered list of items. Each item is either a level or a placeholder.
  final List<LevelListItem> items;

  /// Builder for non-level placeholder items.
  final Widget Function(BuildContext context, Object? data)? placeholderBuilder;
  final bool autoReloadAfterConfigDownload;

  /// Convenience constructor that wraps a plain [LevelMetadata] list.
  LevelListView.fromLevels({
    super.key,
    required List<LevelMetadata> levels,
    this.autoReloadAfterConfigDownload = true,
  })  : items = levels.map((m) => LevelListItem.level(m)).toList(),
        placeholderBuilder = null;

  @override
  State<LevelListView> createState() => _LevelListViewState();
}

class _LevelListViewState extends State<LevelListView> {
  static const Set<String> _directVideoExtensions = {
    '.mp4',
    '.mkv',
    '.webm',
    '.mov',
    '.avi',
    '.m4v',
  };

  Player? _previewPlayer;
  String? _playingLevelPath;
  bool _previewPlaying = false;
  String? _playingSongNameCache;
  String? _playingCoverFilePathCache;
  String? _selectedLevelPath;
  StreamSubscription<List<DownloadTask>>? _downloadTaskSubscription;
  DownloadManager? _boundDownloadManager;
  final Map<String, _PendingConfigDownload> _pendingConfigDownloads = {};
  final Map<String, _DirectDownloadSession> _directDownloadSessions = {};
  final Set<String> _pendingConfigDownloadKeys = <String>{};
  final Set<String> _locallyRecoveredVideoLevelPaths = <String>{};
  bool _processingDownloadTasks = false;
  List<DownloadTask>? _queuedDownloadTasks;
  Timer? _reloadDebounceTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindDownloadTaskStream();
  }

  @override
  void dispose() {
    _downloadTaskSubscription?.cancel();
    _reloadDebounceTimer?.cancel();
    _disposePreviewPlayer();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Audio preview
  // ---------------------------------------------------------------------------

  void _toggleAudioPreview(LevelMetadata meta) {
    final audioFile = _findAudioFile(meta.levelPath);
    if (audioFile == null) return;

    if (_playingLevelPath == meta.levelPath) {
      if (_previewPlaying) {
        _previewPlayer?.pause();
      } else {
        _previewPlayer?.play();
      }
      return;
    }

    if (_previewPlayer != null) {
      _disposePreviewPlayer();
    }

    _previewPlayer = playerService.createAudioPlayer();
    _previewPlayer!.stream.playing.listen((playing) {
      if (mounted) setState(() => _previewPlaying = playing);
    });
    _previewPlayer!.stream.completed.listen((completed) {
      if (completed && mounted) {
        setState(() {
          _previewPlaying = false;
          _playingLevelPath = null;
          _playingSongNameCache = null;
          _playingCoverFilePathCache = null;
        });
      }
    });
    _previewPlayer!.open(Media(audioFile));
    final coverFileName = (meta.coverImageFilename ?? '').trim();
    final coverFilePath =
        coverFileName.isEmpty ? null : p.join(meta.levelPath, coverFileName);
    setState(() {
      _playingLevelPath = meta.levelPath;
      _playingSongNameCache = meta.songName;
      _playingCoverFilePathCache = coverFilePath;
    });
  }

  void _stopAudioPreview() {
    _previewPlayer?.stop();
    _disposePreviewPlayer();
    if (!mounted) return;
    setState(() {
      _previewPlaying = false;
      _playingLevelPath = null;
      _playingSongNameCache = null;
      _playingCoverFilePathCache = null;
    });
  }

  void _disposePreviewPlayer() {
    final player = _previewPlayer;
    if (player == null) {
      return;
    }
    _previewPlayer = null;
    unawaited(playerService.disposePlayer(player));
  }

  // ---------------------------------------------------------------------------
  // File helpers
  // ---------------------------------------------------------------------------

  static String? _findAudioFile(String levelPath) {
    try {
      final dir = Directory(levelPath);
      for (final f in dir.listSync()) {
        if (f is File) {
          final ext = p.extension(f.path).toLowerCase();
          if (ext == '.ogg' || ext == '.egg') return f.path;
        }
      }
    } catch (_) {}
    return null;
  }

  static String? _findVideoFile(String levelPath) {
    try {
      final dir = Directory(levelPath);
      for (final f in dir.listSync()) {
        if (f is File) {
          final ext = p.extension(f.path).toLowerCase();
          if (ext == '.mp4' || ext == '.mkv' || ext == '.webm') return f.path;
        }
      }
    } catch (_) {}
    return null;
  }

  static Set<String> _collectVideoFileNames(String levelPath) {
    final names = <String>{};
    try {
      final dir = Directory(levelPath);
      if (!dir.existsSync()) return names;
      for (final f in dir.listSync()) {
        if (f is! File) continue;
        final ext = p.extension(f.path).toLowerCase();
        if (ext == '.mp4' || ext == '.mkv' || ext == '.webm') {
          names.add(p.basename(f.path).toLowerCase());
        }
      }
    } catch (_) {}
    return names;
  }

  // ---------------------------------------------------------------------------
  // Video preview
  // ---------------------------------------------------------------------------

  void _showVideoPreview(LevelMetadata meta) {
    final videoPath = _findVideoFile(meta.levelPath);
    if (videoPath != null) {
      VideoPreviewDialog.show(context,
          filePath: videoPath, title: meta.songName);
    }
  }

  void _bindDownloadTaskStream() {
    final manager = context.read<AppBloc>().downloadManager;
    if (identical(_boundDownloadManager, manager)) {
      return;
    }
    _downloadTaskSubscription?.cancel();
    _boundDownloadManager = manager;
    if (manager == null) {
      return;
    }
    _downloadTaskSubscription = manager.taskStream.listen(_onDownloadTasks);
  }

  Future<void> _onDownloadTasks(List<DownloadTask> tasks) async {
    if (_processingDownloadTasks) {
      _queuedDownloadTasks = tasks;
      return;
    }
    _processingDownloadTasks = true;
    var currentTasks = tasks;
    while (true) {
      await _consumeDownloadTasks(currentTasks);
      final queued = _queuedDownloadTasks;
      if (queued == null) break;
      _queuedDownloadTasks = null;
      currentTasks = queued;
    }
    _processingDownloadTasks = false;
  }

  Future<void> _consumeDownloadTasks(List<DownloadTask> tasks) async {
    if (_pendingConfigDownloads.isEmpty) return;
    final byId = {for (final task in tasks) task.taskId: task};
    final finishedIds = <String>[];
    var shouldReload = false;
    final pendingSnapshot =
        _pendingConfigDownloads.entries.toList(growable: false);
    for (final entry in pendingSnapshot) {
      final task = byId[entry.key];
      if (task == null) continue;
      if (task.status == DownloadStatus.completed) {
        await _handleConfigDownloadSuccess(entry.value);
        _locallyRecoveredVideoLevelPaths.add(entry.value.levelPath);
        shouldReload = true;
        finishedIds.add(entry.key);
      } else if (task.status == DownloadStatus.failed) {
        final l10n = AppLocalizations.of(context);
        final reason = _friendlyDownloadFailureReason(task.errorMessage);
        log.w(
          '[ConfigDownload] task failed '
          'taskId=${task.taskId} song=${entry.value.songName} '
          'url=${entry.value.videoUrl} err=${task.errorMessage}',
        );
        _showSnackBar(
            '${l10n?.snack_video_download_failed ?? '配置视频下载失败'}: ${entry.value.songName}（$reason）');
        finishedIds.add(entry.key);
      } else if (task.status == DownloadStatus.cancelled) {
        log.i(
          '[ConfigDownload] task cancelled '
          'taskId=${task.taskId} song=${entry.value.songName} '
          'url=${entry.value.videoUrl}',
        );
        _showSnackBar('已取消下载: ${entry.value.songName}');
        finishedIds.add(entry.key);
      }
    }
    var changed = false;
    for (final id in finishedIds) {
      final pending = _pendingConfigDownloads.remove(id);
      _directDownloadSessions.remove(id);
      if (pending != null) {
        _pendingConfigDownloadKeys.remove(pending.downloadKey);
        changed = true;
      }
    }
    if (changed && mounted) {
      setState(() {});
    }
    if (shouldReload && widget.autoReloadAfterConfigDownload) {
      _scheduleReloadCustomLevels();
    }
  }

  Future<void> _handleConfigDownloadSuccess(
      _PendingConfigDownload pending) async {
    final l10n = AppLocalizations.of(context);
    final resolvedName = _resolveDownloadedVideoFileName(
      pending.levelPath,
      pending.existingVideoFiles,
    );
    if (resolvedName == null || resolvedName.isEmpty) {
      log.w(
        '[ConfigDownload] completed but video file unresolved '
        'song=${pending.songName} levelPath=${pending.levelPath}',
      );
      _showSnackBar(
          '${l10n?.snack_video_file_unresolved ?? '下载完成，但未识别到视频文件'}: ${pending.songName}');
      return;
    }
    await _updateCinemaConfigVideoFile(
      levelPath: pending.levelPath,
      videoUrl: pending.videoUrl,
      fileName: resolvedName,
    );
    _showSnackBar(
        '${l10n?.snack_video_file_recovered ?? '已补齐视频文件'}: ${pending.songName}');
  }

  String? _resolveDownloadedVideoFileName(
      String levelPath, Set<String> before) {
    try {
      final dir = Directory(levelPath);
      if (!dir.existsSync()) return null;
      final videos = dir.listSync().whereType<File>().where((file) {
        final ext = p.extension(file.path).toLowerCase();
        return ext == '.mp4' || ext == '.mkv' || ext == '.webm';
      }).toList();
      if (videos.isEmpty) return null;

      final newVideos = videos
          .where((f) => !before.contains(p.basename(f.path).toLowerCase()))
          .toList();
      final candidates = newVideos.isNotEmpty ? newVideos : videos;
      candidates.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return p.basename(candidates.first.path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _updateCinemaConfigVideoFile({
    required String levelPath,
    required String videoUrl,
    required String fileName,
  }) async {
    final configFile = File(p.join(levelPath, Constants.cinemaConfigFileName));
    CinemaConfig config = CinemaConfig(videoUrl: videoUrl);
    try {
      if (configFile.existsSync()) {
        config = CinemaConfig.fromJson(await configFile.readAsString());
      }
    } catch (e, st) {
      log.w(
        '[ConfigDownload] read cinema config failed levelPath=$levelPath error=$e',
        e,
        st,
      );
    }
    config.videoUrl =
        (config.videoUrl ?? '').trim().isEmpty ? videoUrl : config.videoUrl;
    config.videoFile = fileName;
    await configFile.writeAsString(config.toJson());
  }

  Future<void> _reloadCustomLevels() async {
    if (!mounted) return;
    final beatSaberPath = context.read<AppBloc>().beatSaberPath;
    if (beatSaberPath == null || beatSaberPath.isEmpty) {
      return;
    }
    try {
      context
          .read<CustomLevelsBloc>()
          .add(ReloadCustomLevelsEvent(beatSaberPath));
    } catch (_) {
      // LevelListView may also be used in contexts without CustomLevelsBloc.
    }
  }

  void _scheduleReloadCustomLevels() {
    _reloadDebounceTimer?.cancel();
    _reloadDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_reloadCustomLevels());
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _downloadFromConfiguredUrl(LevelMetadata meta) {
    _bindDownloadTaskStream();
    final l10n = AppLocalizations.of(context);
    final url = _resolveConfiguredVideoUrl(meta.cinemaConfig);
    if (url.isEmpty) {
      _showSnackBar(l10n?.snack_config_video_url_missing ?? '当前配置没有可用的视频链接');
      return;
    }
    final downloadKey = _configDownloadKey(meta.levelPath, url);
    if (_pendingConfigDownloadKeys.contains(downloadKey)) {
      return;
    }
    final manager = context.read<AppBloc>().downloadManager;
    if (manager == null) {
      _showSnackBar(
          l10n?.snack_download_service_not_ready ?? '下载服务未初始化，请先设置游戏路径');
      return;
    }
    final tool = _selectDownloadTool(url);
    final taskId = switch (tool) {
      _ConfiguredVideoDownloadTool.ytdlp => manager.enqueue(
          url: url,
          outputDir: meta.levelPath,
          title: l10n?.download_task_config_video_title(meta.songName) ??
              '配置视频：${meta.songName}',
          metadata: {
            'source': 'cinema-config-redownload',
            'tool': 'ytdlp',
            'levelPath': meta.levelPath,
          },
        ),
      _ConfiguredVideoDownloadTool.directHttp => _enqueueDirectHttpDownload(
          manager: manager,
          level: meta,
          videoUrl: url,
        ),
    };
    _pendingConfigDownloadKeys.add(downloadKey);
    _pendingConfigDownloads[taskId] = _PendingConfigDownload(
      downloadKey: downloadKey,
      levelPath: meta.levelPath,
      songName: meta.songName,
      videoUrl: url,
      existingVideoFiles: _collectVideoFileNames(meta.levelPath),
    );
    if (mounted) {
      setState(() {});
    }
    log.i(
      '[ConfigDownload] task enqueued '
      'taskId=$taskId tool=${tool.name} song=${meta.songName} url=$url',
    );
    _showSnackBar(
        '${l10n?.snack_video_download_enqueued ?? '已加入下载队列'}: ${meta.songName}');
  }

  // ---------------------------------------------------------------------------
  // Context menu
  // ---------------------------------------------------------------------------

  List<ContextMenuItem> _buildContextMenu(LevelMetadata meta) {
    final l10n = AppLocalizations.of(context);
    final canRedownloadFromConfig =
        _hasConfiguredVideoSource(meta.cinemaConfig) &&
            meta.videoStatus != VideoConfigStatus.configured;
    return [
      ContextMenuItem(
        label: l10n?.ctx_search_video ?? '搜索视频',
        icon: Icons.search,
        onTap: () => context
            .read<PanelCubit>()
            .openPanel(PanelContentType.search, context: meta),
      ),
      if (meta.cinemaConfig != null) ...[
        ContextMenuItem(
          label: l10n?.ctx_sync_calibration ?? '同步校准',
          icon: Icons.tune,
          onTap: () => context
              .read<PanelCubit>()
              .openPanel(PanelContentType.syncCalibration, context: meta),
        ),
        ContextMenuItem(
          label: l10n?.ctx_edit_config ?? '编辑配置',
          icon: Icons.edit,
          onTap: () => context
              .read<PanelCubit>()
              .openPanel(PanelContentType.configEdit, context: meta),
        ),
        if (canRedownloadFromConfig)
          ContextMenuItem(
            label: l10n?.ctx_download_configured_video ?? '按配置下载视频',
            icon: Icons.cloud_download,
            onTap: () => _downloadFromConfiguredUrl(meta),
          ),
      ],
      ContextMenuItem(
        label: l10n?.ctx_file_info ?? '文件信息',
        icon: Icons.info_outline,
        onTap: () => context
            .read<PanelCubit>()
            .openPanel(PanelContentType.fileInfo, context: meta),
      ),
      const ContextMenuItem.divider(),
      ContextMenuItem(
        label: l10n?.ctx_open_folder ?? '打开文件夹',
        icon: Icons.folder_open,
        onTap: () => Process.run('explorer', [meta.levelPath]),
      ),
      ContextMenuItem(
        label: l10n?.ctx_copy_name ?? '复制歌名',
        icon: Icons.copy,
        onTap: () => Clipboard.setData(ClipboardData(text: meta.songName)),
      ),
      if (meta.cinemaConfig != null) ...[
        const ContextMenuItem.divider(),
        ContextMenuItem(
          label: l10n?.ctx_delete_config ?? '删除配置',
          icon: Icons.delete,
          onTap: () => _confirmDeleteConfig(meta),
        ),
      ],
    ];
  }

  void _confirmDeleteConfig(LevelMetadata meta) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.dialog_delete_config_title ?? '删除配置？'),
        content: Text(
          l10n?.dialog_delete_config_content(meta.songName) ??
              '确认删除 ${meta.songName} 的 cinema-video.json 吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.common_cancel ?? '取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final file = File('${meta.levelPath}/cinema-video.json');
              if (file.existsSync()) file.deleteSync();
            },
            child: Text(
              l10n?.common_delete ?? '删除',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  Widget _buildLevelTile(LevelMetadata meta) {
    final l10n = AppLocalizations.of(context);
    final effectiveVideoStatus = _effectiveVideoStatus(meta);
    return LevelListTile(
      metadata: meta,
      videoStatusOverride: effectiveVideoStatus,
      isSelected: meta.levelPath == _selectedLevelPath,
      isPlayingAudio: _playingLevelPath == meta.levelPath && _previewPlaying,
      onPlayAudio: () => _toggleAudioPreview(meta),
      onVideoPreview: effectiveVideoStatus == VideoConfigStatus.configured
          ? () => _showVideoPreview(meta)
          : null,
      onDownloadConfiguredVideo:
          effectiveVideoStatus == VideoConfigStatus.configuredMissingFile
              ? () => _downloadFromConfiguredUrl(meta)
              : null,
      configuredVideoDownloadTooltip:
          l10n?.ctx_download_configured_video ?? '按配置下载视频',
      configuredVideoDownloading: _isConfiguredVideoDownloading(meta),
      onTap: () {
        setState(() => _selectedLevelPath = meta.levelPath);
        context
            .read<PanelCubit>()
            .openPanel(PanelContentType.search, context: meta);
      },
      contextMenuItems: _buildContextMenu(meta),
    );
  }

  ImageProvider? _resolveCoverImageProvider(String? coverFilePath) {
    final normalized = (coverFilePath ?? '').trim();
    if (normalized.isEmpty) return null;
    final coverFile = File(normalized);
    if (!coverFile.existsSync()) return null;
    return FileImage(coverFile);
  }

  bool _isConfiguredVideoDownloading(LevelMetadata meta) {
    final videoUrl = _resolveConfiguredVideoUrl(meta.cinemaConfig);
    if (videoUrl.isEmpty) return false;
    final downloadKey = _configDownloadKey(meta.levelPath, videoUrl);
    return _pendingConfigDownloadKeys.contains(downloadKey);
  }

  VideoConfigStatus _effectiveVideoStatus(LevelMetadata meta) {
    if (_isConfiguredVideoDownloading(meta)) {
      return VideoConfigStatus.downloading;
    }
    if (_locallyRecoveredVideoLevelPaths.contains(meta.levelPath)) {
      return VideoConfigStatus.configured;
    }
    return meta.videoStatus;
  }

  bool _hasConfiguredVideoSource(CinemaConfig? config) {
    return _resolveConfiguredVideoUrl(config).isNotEmpty;
  }

  String _resolveConfiguredVideoUrl(CinemaConfig? config) {
    if (config == null) return '';
    final rawUrl = (config.videoUrl ?? '').trim();
    if (rawUrl.isNotEmpty) return rawUrl;
    final rawId = (config.videoId ?? '').trim();
    if (rawId.isEmpty) return '';
    if (rawId.startsWith('http://') || rawId.startsWith('https://')) {
      return rawId;
    }
    return 'https://www.youtube.com/watch?v=$rawId';
  }

  _ConfiguredVideoDownloadTool _selectDownloadTool(String videoUrl) {
    final uri = Uri.tryParse(videoUrl);
    if (uri == null) {
      return _ConfiguredVideoDownloadTool.ytdlp;
    }
    final isHttp = uri.scheme == 'http' || uri.scheme == 'https';
    final ext = p.extension(uri.path).toLowerCase();
    if (isHttp && _directVideoExtensions.contains(ext)) {
      return _ConfiguredVideoDownloadTool.directHttp;
    }
    return _ConfiguredVideoDownloadTool.ytdlp;
  }

  String _enqueueDirectHttpDownload({
    required DownloadManager manager,
    required LevelMetadata level,
    required String videoUrl,
  }) {
    final uri = Uri.parse(videoUrl);
    final l10n = AppLocalizations.of(context);
    final fileName = _resolveDirectDownloadFileName(uri, level.songName);
    final outputPath = p.join(level.levelPath, fileName);
    final session = _DirectDownloadSession();
    return manager.enqueueCustom(
      title: l10n?.download_task_config_video_title(level.songName) ??
          '配置视频：${level.songName}',
      metadata: {
        'source': 'cinema-config-redownload',
        'tool': 'direct-http',
        'levelPath': level.levelPath,
      },
      runner: (task, onProgress) async {
        _directDownloadSessions[task.taskId] = session;
        return _runDirectHttpDownload(
          task: task,
          onProgress: onProgress,
          url: uri,
          outputPath: outputPath,
          session: session,
        );
      },
      cancel: (task) async {
        final active = _directDownloadSessions[task.taskId];
        if (active == null) return;
        active.cancelled = true;
        active.client?.close(force: true);
        try {
          await active.sink?.close();
        } catch (_) {}
      },
    );
  }

  Future<DownloadResult> _runDirectHttpDownload({
    required DownloadTask task,
    required void Function(double progress) onProgress,
    required Uri url,
    required String outputPath,
    required _DirectDownloadSession session,
  }) async {
    final tempPath = '$outputPath.part';
    final outFile = File(outputPath);
    final tempFile = File(tempPath);
    try {
      session.client = HttpClient();
      final proxy = await _resolveActiveProxyUrl();
      if (proxy != null && proxy.isNotEmpty) {
        session.client!.findProxy = (_) => 'PROXY ${_proxyHostPort(proxy)}';
      }
      final request = await session.client!.getUrl(url);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        log.w(
          '[ConfigDownload] direct http status invalid '
          'taskId=${task.taskId} url=$url status=${response.statusCode}',
        );
        return DownloadResult(
          taskId: task.taskId,
          status: DownloadStatus.failed,
          errorMessage: 'HTTP ${response.statusCode}',
        );
      }
      final total = response.contentLength;
      session.sink = tempFile.openWrite();
      var received = 0;
      await for (final chunk in response) {
        if (session.cancelled) {
          return DownloadResult(
            taskId: task.taskId,
            status: DownloadStatus.cancelled,
          );
        }
        session.sink!.add(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress((received / total).clamp(0.0, 1.0));
        }
      }
      await session.sink!.close();
      session.sink = null;
      if (session.cancelled) {
        return DownloadResult(
          taskId: task.taskId,
          status: DownloadStatus.cancelled,
        );
      }
      if (outFile.existsSync()) {
        await outFile.delete();
      }
      await tempFile.rename(outputPath);
      log.i(
        '[ConfigDownload] direct http completed '
        'taskId=${task.taskId} output=$outputPath',
      );
      return DownloadResult(
        taskId: task.taskId,
        status: DownloadStatus.completed,
        outputPath: outputPath,
      );
    } catch (e) {
      if (session.cancelled) {
        log.i(
          '[ConfigDownload] direct http cancelled in catch '
          'taskId=${task.taskId} url=$url',
        );
        return DownloadResult(
          taskId: task.taskId,
          status: DownloadStatus.cancelled,
        );
      }
      log.e(
        '[ConfigDownload] direct http exception '
        'taskId=${task.taskId} url=$url error=$e',
      );
      return DownloadResult(
        taskId: task.taskId,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
    } finally {
      try {
        await session.sink?.close();
      } catch (_) {}
      session.sink = null;
      session.client?.close(force: true);
      session.client = null;
      if (tempFile.existsSync()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      _directDownloadSessions.remove(task.taskId);
    }
  }

  String _resolveDirectDownloadFileName(Uri uri, String songName) {
    final ext = p.extension(uri.path).toLowerCase();
    final baseName = p.basename(uri.path).trim();
    if (baseName.isNotEmpty) {
      return _sanitizeFileName(baseName);
    }
    final safeSong =
        _sanitizeFileName(songName.trim().isEmpty ? 'video' : songName);
    final safeExt = _directVideoExtensions.contains(ext) ? ext : '.mp4';
    return '$safeSong$safeExt';
  }

  static String _sanitizeFileName(String input) {
    final sanitized = input.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    if (sanitized.isEmpty) return 'video.mp4';
    return sanitized.length <= 200 ? sanitized : sanitized.substring(0, 200);
  }

  static String _configDownloadKey(String levelPath, String videoUrl) {
    return '${levelPath.trim().toLowerCase()}|${videoUrl.trim().toLowerCase()}';
  }

  String _friendlyDownloadFailureReason(String? rawError) {
    final text = (rawError ?? '').trim();
    if (text.isEmpty) {
      return '未知错误，请检查网络与代理设置';
    }
    final lower = text.toLowerCase();
    if (lower.contains('proxy') &&
        (lower.contains('refused') ||
            lower.contains('failed') ||
            lower.contains('timed out'))) {
      return '代理连接失败，请检查“设置 > 代理模式/代理地址”';
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return '连接超时，请检查网络或更换代理';
    }
    if (lower.contains('name or service not known') ||
        lower.contains('failed to resolve') ||
        lower.contains('temporary failure in name resolution')) {
      return 'DNS 解析失败，请检查网络与代理';
    }
    if (lower.contains('network is unreachable') ||
        lower.contains('no route to host') ||
        lower.contains('connection refused')) {
      return '网络不可达，请检查网络与代理';
    }
    if (lower.contains('http error 403') ||
        lower.contains('http error 429') ||
        lower.contains('video unavailable') ||
        lower.contains('this video is unavailable')) {
      return 'YouTube 访问受限或视频不可用，请尝试代理或稍后重试';
    }
    if (lower.contains('http error 416') ||
        lower.contains('requested range not satisfiable')) {
      return 'YouTube 分片下载失败（416），已自动重试兼容模式；请重试或更换代理';
    }
    if (lower.contains('po token') || lower.contains('missing_pot')) {
      return 'YouTube 新策略限制（PO Token），已尝试兼容模式；建议更新 yt-dlp';
    }
    if (lower.contains('http 407')) {
      return '代理需要认证，请使用带认证信息的代理地址';
    }
    if (text.length > 80) {
      return '${text.substring(0, 80)}...';
    }
    return text;
  }

  Future<String?> _resolveActiveProxyUrl() {
    final app = context.read<AppBloc>();
    return ProxyService.resolveProxyUrl(
      mode: app.proxyMode,
      customProxy: app.proxyServer,
    );
  }

  static String _proxyHostPort(String proxyUrl) {
    final uri = Uri.tryParse(proxyUrl);
    if (uri == null || uri.host.isEmpty || uri.port <= 0) return proxyUrl;
    return '${uri.host}:${uri.port}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final miniPlayer = resolveMiniPlayerDisplayData(
      previewPlaying: _previewPlaying,
      playingLevelPath: _playingLevelPath,
      items: widget.items,
      fallbackSongName: _playingSongNameCache,
      fallbackCoverFilePath: _playingCoverFilePathCache,
    );
    final showMiniPlayer = miniPlayer != null;
    return Stack(
      children: [
        ListView.builder(
          padding: EdgeInsets.only(
            bottom: showMiniPlayer ? 84 : 0,
          ),
          itemExtent: 56,
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            if (item.isLevel) {
              return _buildLevelTile(item.metadata!);
            }
            return widget.placeholderBuilder?.call(context, item.placeholder) ??
                const SizedBox.shrink();
          },
        ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: MiniAudioPlayerBar(
            visible: showMiniPlayer,
            songName: miniPlayer?.songName ?? '',
            onStop: _stopAudioPreview,
            coverImage: _resolveCoverImageProvider(miniPlayer?.coverFilePath),
            stopTooltip: l10n?.mini_player_stop ?? '停止播放',
            coverSemanticLabel: l10n?.mini_player_cover_semantic ?? '当前播放歌曲封面',
          ),
        ),
      ],
    );
  }
}

class _PendingConfigDownload {
  final String downloadKey;
  final String levelPath;
  final String songName;
  final String videoUrl;
  final Set<String> existingVideoFiles;

  const _PendingConfigDownload({
    required this.downloadKey,
    required this.levelPath,
    required this.songName,
    required this.videoUrl,
    required this.existingVideoFiles,
  });
}

enum _ConfiguredVideoDownloadTool { ytdlp, directHttp }

class _DirectDownloadSession {
  HttpClient? client;
  IOSink? sink;
  bool cancelled = false;
}
