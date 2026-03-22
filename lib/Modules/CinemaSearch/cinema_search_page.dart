// ignore_for_file: public_member_api_docs
import 'dart:async';
import 'dart:io';

import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Common/constants.dart';
import 'package:beat_cinema/Modules/CinemaSearch/bloc/cinema_search_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/level_info.dart';
import 'package:beat_cinema/Modules/Manager/cinema_download_manager.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:beat_cinema/models/cinema_config/cinema_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
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
  late final TextEditingController _searchController;
  final CinemaSearchBloc _searchBloc = CinemaSearchBloc();
  final CinemaDownloadManager _downloadManager = CinemaDownloadManager();
  StreamSubscription<Set<String>>? _downloadTaskSub;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
        text: widget.levelInfo.customLevel.songName ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _triggerSearch();
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
      _triggerSearch();
    });
  }

  @override
  void dispose() {
    _downloadTaskSub?.cancel();
    _searchController.dispose();
    _searchBloc.close();
    super.dispose();
  }

  void _triggerSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    _searchBloc.add(
        CinameSearchTextEvent(query, _searchCount, context.read<AppBloc>()));
  }

  void _switchPlatform(CinemaSearchPlatform platform) {
    final appBloc = context.read<AppBloc>();
    if (appBloc.cinemaSearchPlatform == platform) return;
    appBloc.add(AppCinemaSearchPlatformUpdateEvent(platform));
    _triggerSearch();
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
                        onSubmitted: (_) => _triggerSearch(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: _triggerSearch,
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
          final downloading = videoUrl.isNotEmpty &&
              _downloadManager.isDownloading(
                levelPath: widget.levelInfo.levelPath,
                videoUrl: videoUrl,
              );
          final downloaded = !downloading && _isAlreadyDownloaded(videoUrl);

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
                    height: 54,
                    child: thumb == null
                        ? Container(
                            color: AppColors.surface3,
                            child: const Icon(Icons.image_not_supported,
                                color: AppColors.textDisabled, size: 18),
                          )
                        : Image.network(thumb, fit: BoxFit.cover),
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
                Column(
                  children: [
                    if (downloading)
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
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
                          size: 18,
                          color: downloaded
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        onPressed: downloaded
                            ? null
                            : () {
                                final appBloc = context.read<AppBloc>();
                                if (appBloc.beatSaberPath == null) return;
                                _downloadManager.startCinimaDownload(
                                  context,
                                  appBloc.beatSaberPath!,
                                  videoInfo,
                                  widget.levelInfo,
                                  appBloc.cinemaVideoQuality,
                                );
                                setState(() {});
                              },
                      ),
                    IconButton(
                      tooltip: l10n?.search_tooltip_open_link ?? '打开链接',
                      icon: const Icon(Icons.public, size: 18),
                      onPressed: () {
                        if (url != null && url.trim().isNotEmpty) {
                          launchUrlString(url);
                        }
                      },
                    ),
                  ],
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
