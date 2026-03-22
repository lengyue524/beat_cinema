// ignore_for_file: public_member_api_docs
import 'dart:async';
import 'dart:io';

import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Core/errors/app_error.dart';
import 'package:beat_cinema/Modules/CinemaSearch/bloc/cinema_search_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/bloc/custom_levels_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/level_info.dart';
import 'package:beat_cinema/Modules/Manager/cinema_download_manager.dart';
import 'package:beat_cinema/Modules/Playlists/bloc/playlist_bloc.dart';
import 'package:beat_cinema/Modules/Panel/video_preview_dialog.dart';
import 'package:beat_cinema/Services/repositories/video_repository.dart';
import 'package:beat_cinema/Services/services/bbdown_service.dart';
import 'package:beat_cinema/Services/services/ytdlp_service.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:beat_cinema/models/cinema_config/cinema_config.dart';
import 'package:beat_cinema/models/dlp_video_info/dlp_video_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CinemaSearchPage extends StatefulWidget {
  const CinemaSearchPage({
    super.key,
    required this.levelInfo,
  });

  final LevelInfo levelInfo;

  @override
  State<CinemaSearchPage> createState() => _CinemaSearchPageState();
}

class _CinemaSearchPageState extends State<CinemaSearchPage> {
  static const int _searchCount = 20;
  static const double _thumbHeight = 54;
  static const double _actionButtonSize = 18;
  static const double _actionIconSize = 14;
  late final TextEditingController _searchController;
  final CinemaSearchBloc _searchBloc = CinemaSearchBloc();
  final CinemaDownloadManager _downloadManager = CinemaDownloadManager();
  final Set<String> _resolvingPlayUrls = <String>{};
  StreamSubscription<Set<String>>? _downloadTaskSub;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
        text: widget.levelInfo.customLevel.songName ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_triggerSearch());
    });
    _downloadTaskSub = _downloadManager.downloadingTaskStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant CinemaSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelInfo.levelPath == widget.levelInfo.levelPath) {
      return;
    }
    final nextSongName = widget.levelInfo.customLevel.songName ?? '';
    _searchController.text = nextSongName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_triggerSearch());
    });
  }

  @override
  void dispose() {
    _downloadTaskSub?.cancel();
    _searchController.dispose();
    _searchBloc.close();
    super.dispose();
  }

  Future<void> _triggerSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    final appBloc = context.read<AppBloc>();
    _searchBloc.add(CinameSearchTextEvent(query, _searchCount, appBloc));
  }

  void _switchPlatform(CinemaSearchPlatform platform) {
    final appBloc = context.read<AppBloc>();
    if (appBloc.cinemaSearchPlatform == platform) return;
    appBloc.add(AppCinemaSearchPlatformUpdateEvent(platform));
    unawaited(_triggerSearch());
  }

  Future<void> _playInApp(DlpVideoInfo videoInfo) async {
    final appBloc = context.read<AppBloc>();
    final rawUrl = (videoInfo.originalUrl ?? videoInfo.webpageUrl ?? '').trim();
    final playTitle = (videoInfo.title ?? '').trim();
    final resolvedTitle = playTitle.isNotEmpty ? playTitle : rawUrl;
    if (rawUrl.isEmpty || appBloc.beatSaberPath == null) return;
    final prefersBbDown =
        appBloc.cinemaSearchPlatform == CinemaSearchPlatform.bilibili;
    if (prefersBbDown) {
      final installed = await BbDownService.isInstalled(appBloc.beatSaberPath!);
      if (!installed) {
        log.w(
          '[CinemaSearch] play engine=ytdlp platform=bilibili '
          'reason=bbdown_not_installed',
        );
      } else {
        log.i('[CinemaSearch] play engine=bbdown platform=bilibili');
        await _playInAppByBbDown(
          appBloc: appBloc,
          rawUrl: rawUrl,
          resolvedTitle: resolvedTitle,
        );
        return;
      }
    }
    if (_resolvingPlayUrls.contains(rawUrl)) return;
    setState(() => _resolvingPlayUrls.add(rawUrl));
    log.i('[CinemaSearch] play engine=ytdlp platform=${appBloc.cinemaSearchPlatform.name}');
    final service = YtDlpService(
      beatSaberPath: appBloc.beatSaberPath!,
      proxyMode: appBloc.proxyMode,
      customProxy: appBloc.proxyServer,
    );
    try {
      log.i('[CinemaSearch] in-app play request url=$rawUrl');
      final playableUrl = await service.getPlayableStreamUrl(rawUrl);
      log.i('[CinemaSearch] in-app play resolved url=$playableUrl');
      if (!mounted) return;
      final remotePlayed = await VideoPreviewDialog.show(
        context,
        filePath: playableUrl,
        title: resolvedTitle,
        autoCloseOnError: false,
        onPlaybackError: () => _promptAndDownloadForPlayback(
          service: service,
          rawUrl: rawUrl,
        ),
      );
      if (!remotePlayed) {
        throw const AppError(
          type: AppErrorType.network,
          userMessageKey: 'error_ytdlp_video_unavailable',
          retryable: true,
        );
      }
    } catch (e, st) {
      final primaryErrorCode = _resolvePlayFailureCode(e);
      log.w('[CinemaSearch] in-app play primary failed url=$rawUrl', e, st);
      log.w(
        '[CinemaSearch] in-app play primary failed '
        'url=$rawUrl play_error_code=$primaryErrorCode',
      );
      Object finalError = e;
      StackTrace finalStack = st;
      try {
        log.i('[CinemaSearch] in-app play fallback to local download url=$rawUrl');
        final localPath =
            await _downloadTempPlayableFile(service: service, rawUrl: rawUrl);
        if (!mounted) return;
        final localPlayed = await VideoPreviewDialog.show(
          context,
          filePath: localPath,
          title: resolvedTitle,
          autoCloseOnError: true,
        );
        if (localPlayed) return;
      } catch (fallbackError, fallbackSt) {
        finalError = fallbackError;
        finalStack = fallbackSt;
        log.w(
          '[CinemaSearch] in-app play local fallback failed '
          'url=$rawUrl play_error_code=${_resolvePlayFailureCode(fallbackError)}',
          fallbackError,
          fallbackSt,
        );
      }

      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final reason =
          _resolvePlayFailureReason(finalError, l10n) ??
              _resolvePlayFailureReason(e, l10n) ??
              (l10n?.error_ytdlp_unknown ?? '下载发生错误');
      log.e(
        '[CinemaSearch] in-app play failed '
        'url=$rawUrl play_error_code=${_resolvePlayFailureCode(finalError)} '
        'error=$finalError',
        finalError,
        finalStack,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.search_play_failed_with_reason(reason) ??
                '视频播放失败：$reason',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _resolvingPlayUrls.remove(rawUrl));
      }
    }
  }

  Future<void> _playInAppByBbDown({
    required AppBloc appBloc,
    required String rawUrl,
    required String resolvedTitle,
  }) async {
    if (_resolvingPlayUrls.contains(rawUrl)) return;
    setState(() => _resolvingPlayUrls.add(rawUrl));
    final service = BbDownService(
      beatSaberPath: appBloc.beatSaberPath!,
      proxyMode: appBloc.proxyMode,
      customProxy: appBloc.proxyServer,
    );
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory(p.join(tempDir.path, 'beat_cinema_play_cache'));
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      final targetDir = Directory(
        p.join(cacheDir.path, DateTime.now().millisecondsSinceEpoch.toString()),
      );
      await targetDir.create(recursive: true);
      final playableFile = await service.downloadPlayableFile(
        url: rawUrl,
        outputDir: targetDir.path,
      );
      if (!mounted) return;
      final played = await VideoPreviewDialog.show(
        context,
        filePath: playableFile,
        title: resolvedTitle,
        autoCloseOnError: true,
      );
      if (!played && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.search_play_failed ?? '视频播放失败，请稍后重试',
            ),
          ),
        );
      }
    } catch (e, st) {
      log.w('[CinemaSearch] bbdown in-app play failed url=$rawUrl', e, st);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final reason = _resolvePlayFailureReason(e, l10n) ??
          (l10n?.error_bbdown_unknown ?? 'BBDown 处理失败');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.search_play_failed_with_reason(reason) ?? '视频播放失败：$reason',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _resolvingPlayUrls.remove(rawUrl));
      }
    }
  }

  String? _resolvePlayFailureReason(Object error, AppLocalizations? l10n) {
    if (l10n == null) return null;
    if (error is AppError) {
      switch (error.userMessageKey) {
        case 'error_ytdlp_video_unavailable':
          return l10n.error_ytdlp_video_unavailable;
        case 'error_ytdlp_age_restricted':
          return l10n.error_ytdlp_age_restricted;
        case 'error_ytdlp_network':
          return l10n.error_ytdlp_network;
        case 'error_ytdlp_invalid_url':
          return l10n.error_ytdlp_invalid_url;
        case 'error_ytdlp_not_found':
          return l10n.error_ytdlp_not_found;
        case 'error_ytdlp_search_timeout':
          return l10n.error_ytdlp_search_timeout;
        case 'error_ytdlp_unknown':
          return l10n.error_ytdlp_unknown;
        case 'snack_video_file_unresolved':
          return l10n.snack_video_file_unresolved;
        case 'error_bbdown_not_found':
          return l10n.error_bbdown_not_found;
        case 'error_bbdown_login_required':
          return l10n.error_bbdown_login_required;
        case 'error_bbdown_network':
          return l10n.error_bbdown_network;
        case 'error_bbdown_unknown':
          return l10n.error_bbdown_unknown;
      }
      return error.detail?.trim().isNotEmpty == true
          ? error.detail!.trim()
          : null;
    }
    return null;
  }

  String _resolvePlayFailureCode(Object error) {
    if (error is AppError) {
      return error.userMessageKey;
    }
    return 'playback_unknown';
  }

  Future<String> _downloadTempPlayableFile({
    required YtDlpService service,
    required String rawUrl,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(p.join(tempDir.path, 'beat_cinema_play_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final targetDir = Directory(p.join(cacheDir.path, taskId));
    await targetDir.create(recursive: true);
    final result = await service.download(
      rawUrl,
      targetDir.path,
      taskId: taskId,
      quality: 'best[height<=720]/best',
    );
    if (result.status != DownloadStatus.completed) {
      final message = result.errorMessage?.trim().isNotEmpty == true
          ? result.errorMessage!.trim()
          : 'download failed';
      throw AppError(
        type: AppErrorType.network,
        userMessageKey: 'error_ytdlp_network',
        detail: message,
        retryable: true,
      );
    }
    final playableFile = _findFirstPlayableFile(targetDir.path);
    if (playableFile == null) {
      throw const AppError(
        type: AppErrorType.fileSystem,
        userMessageKey: 'snack_video_file_unresolved',
        retryable: false,
      );
    }
    log.i('[CinemaSearch] local playback cache file=$playableFile');
    return playableFile;
  }

  Future<String?> _promptAndDownloadForPlayback({
    required YtDlpService service,
    required String rawUrl,
  }) async {
    if (!mounted) return null;
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          l10n?.search_play_fallback_title ?? '切换下载播放模式',
        ),
        content: Text(
          l10n?.search_play_fallback_message ??
              '在线播放失败，是否切换为下载后播放？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n?.common_cancel ?? '取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n?.search_play_fallback_confirm ?? '切换并播放',
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return null;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n?.search_play_fallback_loading ?? '正在下载视频用于本地播放...',
              ),
            ),
          ],
        ),
      ),
    );
    try {
      return await _downloadTempPlayableFile(service: service, rawUrl: rawUrl);
    } catch (e, st) {
      log.w('[CinemaSearch] local fallback download failed url=$rawUrl', e, st);
      if (!mounted) return null;
      final reason =
          _resolvePlayFailureReason(e, l10n) ??
              (l10n?.error_ytdlp_unknown ?? '下载发生错误');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.search_play_failed_with_reason(reason) ?? '视频播放失败：$reason',
          ),
        ),
      );
      return null;
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _openInBrowser(DlpVideoInfo videoInfo) async {
    final l10n = AppLocalizations.of(context);
    final targetUrl =
        (videoInfo.originalUrl ?? videoInfo.webpageUrl ?? '').trim();
    if (targetUrl.isEmpty) return;
    try {
      log.i('[CinemaSearch] open external link url=$targetUrl');
      final opened = await launchUrlString(
        targetUrl,
        mode: LaunchMode.externalApplication,
      );
      if (opened) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.search_open_link_failed ?? '无法打开网页链接，请稍后重试',
          ),
        ),
      );
    } catch (e, st) {
      log.w('[CinemaSearch] open external link failed url=$targetUrl', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.search_open_link_failed ?? '无法打开网页链接，请稍后重试',
          ),
        ),
      );
    }
  }

  String? _findFirstPlayableFile(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return null;
    final files = dir
        .listSync()
        .whereType<File>()
        .where((file) {
          final ext = p.extension(file.path).toLowerCase();
          return ext == '.mp4' || ext == '.mkv' || ext == '.webm';
        })
        .toList(growable: false);
    if (files.isEmpty) return null;
    files.sort(
      (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
    );
    return files.first.path;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider.value(
      value: _searchBloc,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: Column(
              children: [
                BlocBuilder<AppBloc, AppState>(
                  builder: (context, state) {
                    final appState = state is AppLaunchComplated ? state : null;
                    final selectedPlatform = appState?.cinemaSearchPlatform ??
                        context.read<AppBloc>().cinemaSearchPlatform;
                    return SegmentedButton<CinemaSearchPlatform>(
                      segments: const [
                        ButtonSegment<CinemaSearchPlatform>(
                          value: CinemaSearchPlatform.youtube,
                          icon: Icon(Icons.ondemand_video, size: 16),
                          label: Text('YouTube'),
                        ),
                        ButtonSegment<CinemaSearchPlatform>(
                          value: CinemaSearchPlatform.bilibili,
                          icon: Icon(Icons.smart_display, size: 16),
                          label: Text('Bilibili'),
                        ),
                      ],
                      selected: {selectedPlatform},
                      onSelectionChanged: (selection) {
                        _switchPlatform(selection.first);
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: l10n?.search_tips ?? '搜索...',
                          hintStyle: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.surface2,
                          prefixIcon: const Icon(Icons.search, size: 18),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.brandPurple, width: 1),
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => unawaited(_triggerSearch()),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: () => unawaited(_triggerSearch()),
                      child: const Icon(Icons.search, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: BlocBuilder<CinemaSearchBloc, CinemaSearchState>(
              builder: (context, state) => _buildContent(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(CinemaSearchState state) {
    final l10n = AppLocalizations.of(context);
    if (state is CinemaSearchLoading || state is CinemaSearchInitial) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (state is CinemaSearchLoaded) {
      if (state.videoInfos.isEmpty) {
        return Center(
          child: Text(
            l10n?.empty_no_video ?? '未找到视频',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.sm),
        itemCount: state.videoInfos.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final videoInfo = state.videoInfos[index];
          final thumb = videoInfo.thumbnail;
          final title = (videoInfo.title ?? '').trim();
          final url = videoInfo.originalUrl;
          final duration = videoInfo.durationString ?? '00:00';
          final resolution = videoInfo.resolution ?? 'unknown';
          final videoUrl = (videoInfo.originalUrl ?? '').trim();
          final playUrl = (videoInfo.originalUrl ?? videoInfo.webpageUrl ?? '').trim();
          final downloading = videoUrl.isNotEmpty &&
              _downloadManager.isDownloading(
                levelPath: widget.levelInfo.levelPath,
                videoUrl: videoUrl,
              );
          final downloaded = !downloading && _isAlreadyDownloaded(videoUrl);
          final resolvingPlay =
              playUrl.isNotEmpty && _resolvingPlayUrls.contains(playUrl);

          return Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 96,
                    height: _thumbHeight,
                    child: thumb == null
                        ? Container(
                            color: AppColors.surface3,
                            child: const Icon(Icons.image_not_supported,
                                color: AppColors.textDisabled, size: 18),
                          )
                        : Image.network(
                            thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              log.w(
                                '[CinemaSearch] thumbnail load failed '
                                'url=$thumb error=$error',
                              );
                              return Container(
                                color: AppColors.surface3,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textDisabled,
                                  size: 18,
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? '-' : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.timer,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            duration,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            resolution,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: _actionButtonSize,
                  height: _thumbHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    if (resolvingPlay)
                      Tooltip(
                        message: l10n?.search_tooltip_play_loading ?? '正在准备播放',
                        child: const SizedBox(
                          width: _actionButtonSize,
                          height: _actionButtonSize,
                          child: Center(
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      )
                    else
                      IconButton(
                        tooltip: l10n?.search_tooltip_play ?? '应用内播放',
                        icon: const Icon(Icons.play_circle_outline, size: _actionIconSize),
                        constraints: const BoxConstraints(
                          minWidth: _actionButtonSize,
                          minHeight: _actionButtonSize,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: (url != null && url.trim().isNotEmpty)
                            ? () => _playInApp(videoInfo)
                            : null,
                      ),
                    IconButton(
                      tooltip: l10n?.search_tooltip_open_link ?? '打开链接',
                      icon: const Icon(Icons.open_in_new, size: _actionIconSize),
                      constraints: const BoxConstraints(
                        minWidth: _actionButtonSize,
                        minHeight: _actionButtonSize,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: (url != null && url.trim().isNotEmpty)
                          ? () => _openInBrowser(videoInfo)
                          : null,
                    ),
                    if (downloading)
                      const SizedBox(
                        width: _actionButtonSize,
                        height: _actionButtonSize,
                        child: Center(
                          child: SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      IconButton(
                        tooltip: downloaded
                            ? (l10n?.search_tooltip_downloaded ?? '已下载')
                            : (l10n?.search_tooltip_download ?? '下载'),
                        icon: Icon(
                          downloaded ? Icons.check_circle : Icons.download,
                          size: _actionIconSize,
                          color: downloaded
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: _actionButtonSize,
                          minHeight: _actionButtonSize,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: downloaded
                            ? null
                            : () async {
                                final appBloc = context.read<AppBloc>();
                                final customLevelsBloc =
                                    context.read<CustomLevelsBloc>();
                                PlaylistBloc? playlistBloc;
                                try {
                                  playlistBloc = context.read<PlaylistBloc>();
                                } catch (_) {
                                  playlistBloc = null;
                                }
                                final beatSaberPath = appBloc.beatSaberPath;
                                if (beatSaberPath == null) return;
                                try {
                                  await _downloadManager.startCinimaDownload(
                                    context,
                                    beatSaberPath,
                                    videoInfo,
                                    widget.levelInfo,
                                    appBloc.cinemaVideoQuality,
                                  );
                                } catch (_) {
                                  if (mounted) setState(() {});
                                  return;
                                }
                                if (!mounted) return;
                                customLevelsBloc.add(
                                  RefreshSingleLevelEvent(
                                    widget.levelInfo.levelPath,
                                  ),
                                );
                                playlistBloc?.add(
                                  RefreshMatchedLevelEvent(
                                    widget.levelInfo.levelPath,
                                  ),
                                );
                                setState(() {});
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  bool _isAlreadyDownloaded(String videoUrl) {
    if (videoUrl.isEmpty) return false;
    final configFile = File(
      p.join(widget.levelInfo.levelPath, Constants.cinemaConfigFileName),
    );
    if (!configFile.existsSync()) return false;
    try {
      final config = CinemaConfig.fromJson(configFile.readAsStringSync());
      if ((config.videoUrl ?? '').trim() != videoUrl) {
        return false;
      }
      final videoFile = (config.videoFile ?? '').trim();
      if (videoFile.isEmpty) return false;
      final resolved = p.isAbsolute(videoFile)
          ? videoFile
          : p.join(widget.levelInfo.levelPath, videoFile);
      return File(resolved).existsSync();
    } catch (_) {
      return false;
    }
  }

}
