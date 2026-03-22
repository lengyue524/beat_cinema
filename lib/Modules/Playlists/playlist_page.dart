import 'dart:convert';

import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Modules/CustomLevels/bloc/custom_levels_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/widgets/level_list_view.dart';
import 'package:beat_cinema/Modules/Playlists/bloc/playlist_bloc.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final ScrollController _playlistListScrollController = ScrollController();

  @override
  void dispose() {
    _playlistListScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CustomLevelsBloc, CustomLevelsState>(
          listenWhen: (previous, current) =>
              previous is! CustomLevelsLoaded && current is CustomLevelsLoaded,
          listener: (context, state) {
            _loadPlaylists(context);
          },
        ),
        BlocListener<PlaylistBloc, PlaylistState>(
          listenWhen: (previous, current) {
            if (previous is! PlaylistLoaded || current is! PlaylistLoaded) {
              return false;
            }
            return previous.exportResult != current.exportResult &&
                current.exportResult != null &&
                !current.exporting;
          },
          listener: (context, state) {
            final loaded = state as PlaylistLoaded;
            final result = loaded.exportResult;
            if (result == null) return;
            if (result.failedCount == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('导出成功')),
              );
              context.read<PlaylistBloc>().add(DismissExportResultEvent());
            }
          },
        ),
        BlocListener<PlaylistBloc, PlaylistState>(
          listenWhen: (previous, current) {
            if (previous is! PlaylistLoaded || current is! PlaylistLoaded) {
              return false;
            }
            return previous.rebuildNotice?.serial !=
                    current.rebuildNotice?.serial &&
                current.rebuildNotice != null;
          },
          listener: (context, state) {
            final loaded = state as PlaylistLoaded;
            final notice = loaded.rebuildNotice;
            if (notice == null) return;
            final l10n = AppLocalizations.of(context);
            final message = notice.success
                ? (l10n?.playlist_rebuild_success ?? 'Index rebuild completed')
                : _resolveRebuildFailureMessage(l10n, notice);
            assert(() {
              if (!notice.success && (notice.detail ?? '').trim().isNotEmpty) {
                log.w(
                  '[PlaylistRebuild] debug detail: ${notice.detail}',
                );
              }
              return true;
            }());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: notice.success ? null : AppColors.error,
                action: notice.success
                    ? null
                    : SnackBarAction(
                        label: l10n?.playlist_rebuild_retry ?? 'Retry',
                        onPressed: () {
                          context
                              .read<PlaylistBloc>()
                              .add(RebuildPlaylistHashIndexEvent());
                        },
                      ),
              ),
            );
            context
                .read<PlaylistBloc>()
                .add(DismissPlaylistRebuildNoticeEvent());
          },
        ),
      ],
      child:
          BlocBuilder<PlaylistBloc, PlaylistState>(builder: (context, state) {
        if (state is PlaylistInitial) {
          _loadPlaylists(context);
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (state is PlaylistLoading) {
          return _PlaylistLoadingView(state: state);
        }
        if (state is PlaylistError) {
          return Center(
            child: Text(state.message,
                style: const TextStyle(color: AppColors.error)),
          );
        }
        if (state is PlaylistLoaded) {
          if (state.selectedPlaylist != null) {
            return _PlaylistDetail(
              playlist: state.selectedPlaylist!,
              filterUnconfigured: state.filterUnconfigured,
              exporting: state.exporting,
              exportProgress: state.exportProgress,
              exportResult: state.exportResult,
            );
          }
          return _PlaylistList(
            playlists: state.playlists,
            scrollController: _playlistListScrollController,
            onRebuildIndex: () => _confirmAndRebuild(context),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  void _loadPlaylists(BuildContext context) {
    final appState = context.read<AppBloc>().state;
    if (appState is! AppLaunchComplated || appState.beatSaberPath == null) {
      return;
    }
    final levelsState = context.read<CustomLevelsBloc>().state;
    final levels = switch (levelsState) {
      CustomLevelsLoaded loaded => loaded.allLevels,
      CustomLevelsLoading loading => loading.cachedLevels,
      _ => <LevelMetadata>[],
    };
    context
        .read<PlaylistBloc>()
        .add(LoadPlaylistsEvent(appState.beatSaberPath!, levels));
  }

  Future<void> _confirmAndRebuild(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            l10n?.playlist_rebuild_confirm_title ?? 'Rebuild hash index',
          ),
          content: Text(
            l10n?.playlist_rebuild_confirm_message ??
                'Rebuilding index can be slow. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n?.common_cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child:
                  Text(l10n?.playlist_rebuild_confirm_continue ?? 'Continue'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    context.read<PlaylistBloc>().add(RebuildPlaylistHashIndexEvent());
  }

  String _resolveRebuildFailureMessage(
    AppLocalizations? l10n,
    PlaylistRebuildNotice notice,
  ) {
    final title = l10n?.playlist_rebuild_failed ?? 'Index rebuild failed';
    final reason = switch (notice.message) {
      'playlist_rebuild_error_permission' =>
        l10n?.playlist_rebuild_error_permission ??
            'Permission denied while rebuilding index',
      'playlist_rebuild_error_path_not_found' =>
        l10n?.playlist_rebuild_error_path_not_found ??
            'Song path does not exist',
      'playlist_rebuild_error_cache_write' =>
        l10n?.playlist_rebuild_error_cache_write ??
            'Failed to write index cache',
      _ => l10n?.playlist_rebuild_error_unknown ??
          'Unexpected error while rebuilding index',
    };
    return '$title: $reason';
  }
}

class _PlaylistLoadingView extends StatelessWidget {
  const _PlaylistLoadingView({required this.state});

  final PlaylistLoading state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = state.progress;
    final processed = state.processedSongs;
    final total = state.totalSongs;
    final isLevelScanStage = state.stage == 'refresh-levels-fast' ||
        state.stage == 'refresh-levels-hash' ||
        state.stage == 'rebuild-index-hash';
    final stageText = switch (state.stage) {
      'parse-playlists' =>
        l10n?.playlist_loading_parse_playlists ?? 'Reading playlist files...',
      'refresh-levels-fast' => l10n?.playlist_loading_refresh_levels_fast ??
          'Refreshing local song index (fast)...',
      'refresh-levels-hash' => l10n?.playlist_loading_refresh_levels_hash ??
          'Building song hash index (slower, fallback only)...',
      'match-songs' =>
        l10n?.playlist_loading_match_songs ?? 'Matching playlist songs...',
      'rebuild-index-scan' =>
        l10n?.playlist_rebuild_stage_scan ?? 'Preparing index rebuild...',
      'rebuild-index-hash' =>
        l10n?.playlist_rebuild_stage_hash ?? 'Rebuilding song hash index...',
      'rebuild-index-save' =>
        l10n?.playlist_rebuild_stage_save ?? 'Saving index cache...',
      _ => l10n?.playlist_loading_default ?? 'Loading playlists...'
    };
    final percentText =
        progress == null ? '--' : '${(progress * 100).toStringAsFixed(1)}%';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                stageText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isLevelScanStage
                    ? (l10n?.playlist_loading_level_progress(
                            processed, total, percentText) ??
                        'Parsed level folders $processed / $total  ($percentText)')
                    : (l10n?.playlist_loading_song_progress(
                            processed, total, percentText) ??
                        'Matched songs $processed / $total  ($percentText)'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: progress,
                color: AppColors.brandPurple,
                backgroundColor: AppColors.surface3,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n?.playlist_loading_playlists_progress(
                      state.parsedPlaylists,
                      state.totalPlaylists,
                    ) ??
                    'Playlist files ${state.parsedPlaylists} / ${state.totalPlaylists}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistList extends StatelessWidget {
  const _PlaylistList({
    required this.playlists,
    required this.scrollController,
    required this.onRebuildIndex,
  });
  final List<PlaylistWithStatus> playlists;
  final ScrollController scrollController;
  final VoidCallback onRebuildIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.queue_music,
                size: 48, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n?.playlist_empty ?? 'No playlists found',
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n?.playlist_empty_desc ??
                  'Place .bplist files in Beat Saber/Playlists',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.playlist_list_title ?? 'Playlists',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Tooltip(
                message: l10n?.playlist_rebuild_button ?? 'Rebuild index',
                child: IconButton(
                  onPressed: onRebuildIndex,
                  icon: const Icon(Icons.restart_alt, size: 20),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: const PageStorageKey<String>('playlist_list_scroll'),
            controller: scrollController,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final pl = playlists[index];
              return _PlaylistTile(
                playlist: pl,
                onTap: () => context
                    .read<PlaylistBloc>()
                    .add(SelectPlaylistEvent(index)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist, this.onTap});
  final PlaylistWithStatus playlist;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final info = playlist.info;
    final songCount = info.songs.length;
    final stats =
        '${playlist.configuredCount}/$songCount ${l10n?.playlist_configured ?? 'configured'}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.surface3,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              _buildCover(info.imageBase64),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$songCount ${l10n?.playlist_songs ?? 'songs'}  •  $stats',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(String? imageBase64) {
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        String raw = imageBase64;
        if (raw.contains(',')) raw = raw.split(',').last;
        final bytes = base64Decode(raw);
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.memory(bytes,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _defaultCover()),
        );
      } catch (_) {
        return _defaultCover();
      }
    }
    return _defaultCover();
  }

  Widget _defaultCover() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(4),
      ),
      child:
          const Icon(Icons.queue_music, color: AppColors.brandPurple, size: 24),
    );
  }
}

class _PlaylistDetail extends StatefulWidget {
  const _PlaylistDetail({
    required this.playlist,
    required this.filterUnconfigured,
    required this.exporting,
    required this.exportProgress,
    required this.exportResult,
  });
  final PlaylistWithStatus playlist;
  final bool filterUnconfigured;
  final bool exporting;
  final double exportProgress;
  final ExportResult? exportResult;

  @override
  State<_PlaylistDetail> createState() => _PlaylistDetailState();
}

class _PlaylistDetailState extends State<_PlaylistDetail> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final songs = widget.filterUnconfigured
        ? widget.playlist.songs
            .where((s) =>
                s.matchedLevel == null || s.matchedLevel!.cinemaConfig == null)
            .toList()
        : widget.playlist.songs;
    final matchedLevels =
        songs.map((s) => s.matchedLevel).whereType<LevelMetadata>().toList();
    final missingSongs = songs.where((s) => s.matchedLevel == null).toList();
    final unmatchedCount = songs.length - matchedLevels.length;

    return Column(
      children: [
        _buildHeader(context, l10n),
        if (missingSongs.isNotEmpty)
          _buildMissingSongsSection(context, l10n, missingSongs),
        if (unmatchedCount > 0)
          _buildUnmatchedBanner(context, l10n, unmatchedCount, songs.length),
        if (widget.exportResult != null && widget.exportResult!.failedCount > 0)
          _buildExportResultBanner(context, widget.exportResult!),
        if (widget.exporting)
          LinearProgressIndicator(
            value: widget.exportProgress > 0 ? widget.exportProgress : null,
            color: AppColors.brandPurple,
            backgroundColor: AppColors.surface3,
          ),
        Expanded(
          child: matchedLevels.isEmpty
              ? Center(
                  child: Text(
                    songs.isEmpty
                        ? (l10n?.playlist_all_configured ??
                            'All songs are configured')
                        : (l10n?.playlist_not_installed ?? 'Not installed'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : LevelListView.fromLevels(
                  levels: matchedLevels,
                  autoReloadAfterConfigDownload: false,
                ),
        ),
      ],
    );
  }

  Widget _buildMissingSongsSection(
    BuildContext context,
    AppLocalizations? l10n,
    List<PlaylistSongWithStatus> songs,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.playlist_not_installed ?? 'Not installed',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: songs.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, index) {
                final item = songs[index];
                final title = item.song.songName?.trim().isNotEmpty == true
                    ? item.song.songName!
                    : item.song.hash;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                            if (item.downloadError != null)
                              Text(
                                item.downloadError!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 11,
                                ),
                              )
                            else if (item.song.missingKey)
                              const Text(
                                '歌单条目缺少 key，已自动回退 hash 匹配',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (item.downloading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.download, size: 18),
                          tooltip: 'Download',
                          onPressed: () => context
                              .read<PlaylistBloc>()
                              .add(DownloadMissingSongEvent(item)),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnmatchedBanner(
    BuildContext context,
    AppLocalizations? l10n,
    int unmatchedCount,
    int visibleCount,
  ) {
    final matchedCount = visibleCount - unmatchedCount;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${l10n?.playlist_matched ?? 'Matched'}: $matchedCount/$visibleCount  •  '
        '$unmatchedCount ${l10n?.playlist_not_installed ?? 'Not installed'}',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildExportResultBanner(BuildContext context, ExportResult result) {
    final failed = result.failedCount;
    final success = result.successCount;
    final hasFailures = failed > 0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: hasFailures ? AppColors.surface3 : AppColors.surface2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: hasFailures ? AppColors.warning : AppColors.divider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasFailures
                  ? '导出部分成功：成功 $success，失败 $failed'
                  : '导出成功：共 $success 首',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
          if (hasFailures)
            TextButton(
              onPressed: () =>
                  context.read<PlaylistBloc>().add(RetryFailedExportEvent()),
              child: const Text('仅重试失败项'),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? l10n) {
    final total = widget.playlist.songs.length;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () =>
                context.read<PlaylistBloc>().add(DeselectPlaylistEvent()),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.playlist.info.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  '${widget.playlist.configuredCount}/$total ${l10n?.playlist_configured ?? 'configured'}  •  '
                  '${widget.playlist.matchedCount}/$total ${l10n?.playlist_matched ?? 'matched'}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Tooltip(
            message:
                l10n?.playlist_filter_unconfigured ?? 'Show unconfigured only',
            child: IconButton(
              icon: Icon(
                Icons.filter_alt,
                size: 20,
                color: widget.filterUnconfigured
                    ? AppColors.brandPurple
                    : AppColors.textSecondary,
              ),
              onPressed: () => context
                  .read<PlaylistBloc>()
                  .add(ToggleFilterUnconfiguredEvent()),
            ),
          ),
          Tooltip(
            message: 'Download missing songs',
            child: IconButton(
              icon: const Icon(Icons.download_for_offline, size: 20),
              onPressed: () => _startBatchDownload(context),
            ),
          ),
          Tooltip(
            message: l10n?.playlist_export ?? 'Export',
            child: IconButton(
              icon: const Icon(Icons.drive_folder_upload, size: 20),
              onPressed: widget.exporting ? null : () => _startExport(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startExport(BuildContext context) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select export folder',
    );
    if (result != null && context.mounted) {
      context.read<PlaylistBloc>().add(ExportPlaylistEvent(result));
    }
  }

  Future<void> _startBatchDownload(BuildContext context) async {
    final options = await _showBatchDownloadDialog(context);
    if (options == null || !context.mounted) return;
    context.read<PlaylistBloc>().add(
          DownloadAllMissingSongsEvent(
            includeExistingUpdates: options.includeExistingUpdates,
            forceUpdateExisting: options.forceUpdateExisting,
          ),
        );
  }

  Future<_BatchDownloadOptions?> _showBatchDownloadDialog(
      BuildContext context) async {
    var includeExistingUpdates = false;
    var forceUpdateExisting = false;

    return showDialog<_BatchDownloadOptions>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('下载全部缺失歌曲'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('仅下载缺失'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('缺失+更新'),
                      ),
                    ],
                    selected: {includeExistingUpdates},
                    onSelectionChanged: (selection) {
                      setState(() {
                        includeExistingUpdates = selection.first;
                        if (!includeExistingUpdates) {
                          forceUpdateExisting = false;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '判定: 文件缺失 / 版本不一致 / 强制更新',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (includeExistingUpdates)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: forceUpdateExisting,
                      title: const Text('强制更新已存在歌曲'),
                      onChanged: (value) {
                        setState(() {
                          forceUpdateExisting = value ?? false;
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    _BatchDownloadOptions(
                      includeExistingUpdates: includeExistingUpdates,
                      forceUpdateExisting: forceUpdateExisting,
                    ),
                  ),
                  child: const Text('开始'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BatchDownloadOptions {
  final bool includeExistingUpdates;
  final bool forceUpdateExisting;

  const _BatchDownloadOptions({
    required this.includeExistingUpdates,
    required this.forceUpdateExisting,
  });
}
