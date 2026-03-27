import 'dart:convert';
import 'dart:io';

import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/Modules/CustomLevels/bloc/custom_levels_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/widgets/level_list_view.dart';
import 'package:beat_cinema/Modules/Playlists/bloc/playlist_bloc.dart';
import 'package:beat_cinema/Modules/Playlists/playlist_cover_candidates.dart';
import 'package:beat_cinema/Modules/Playlists/widgets/playlist_cover_picker_dialog.dart';
import 'package:beat_cinema/Modules/Playlists/widgets/playlist_picker_dialog.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef PlaylistCoverPicker = Future<PlaylistCoverPickerResult?> Function(
  BuildContext context,
  List<PlaylistCoverCandidate> candidates,
);

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({
    super.key,
    this.coverPicker,
  });

  final PlaylistCoverPicker? coverPicker;

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
        BlocListener<PlaylistBloc, PlaylistState>(
          listenWhen: (previous, current) {
            if (previous is! PlaylistLoaded || current is! PlaylistLoaded) {
              return false;
            }
            return previous.actionNotice?.serial != current.actionNotice?.serial &&
                current.actionNotice != null;
          },
          listener: (context, state) {
            final loaded = state as PlaylistLoaded;
            final notice = loaded.actionNotice;
            if (notice == null) return;
            final l10n = AppLocalizations.of(context);
            final summary = l10n?.snack_batch_result(
                  notice.successCount,
                  notice.failedCount,
                ) ??
                '操作完成：成功 ${notice.successCount} / 失败 ${notice.failedCount}';
            final detail = (notice.failureSummary ?? '').trim();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(detail.isEmpty ? summary : '$summary；$detail'),
                backgroundColor:
                    notice.failedCount > 0 ? AppColors.error : null,
              ),
            );
            context.read<PlaylistBloc>().add(DismissPlaylistActionNoticeEvent());
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
              allPlaylists: state.playlists,
              filterUnconfigured: state.filterUnconfigured,
              exporting: state.exporting,
              exportProgress: state.exportProgress,
              exportResult: state.exportResult,
              coverPicker: widget.coverPicker,
            );
          }
          return _PlaylistList(
            playlists: state.playlists,
            scrollController: _playlistListScrollController,
            onRebuildIndex: () => _confirmAndRebuild(context),
            onCreatePlaylist: () => _createPlaylist(context),
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

  Future<void> _createPlaylist(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    var draftTitle = '';
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('新建歌单'),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: '请输入歌单名称',
            ),
            onChanged: (value) => draftTitle = value.trim(),
            onSubmitted: (value) =>
                Navigator.of(dialogContext).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n?.common_cancel ?? '取消'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(draftTitle),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    if (title == null || title.trim().isEmpty || !context.mounted) return;
    context.read<PlaylistBloc>().add(CreatePlaylistEvent(title: title.trim()));
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
    required this.onCreatePlaylist,
  });
  final List<PlaylistWithStatus> playlists;
  final ScrollController scrollController;
  final VoidCallback onRebuildIndex;
  final VoidCallback onCreatePlaylist;

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
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onCreatePlaylist,
              icon: const Icon(Icons.playlist_add, size: 18),
              label: const Text('新建歌单'),
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
                message: '新建歌单',
                child: IconButton(
                  onPressed: onCreatePlaylist,
                  icon: const Icon(Icons.playlist_add, size: 20),
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
    required this.allPlaylists,
    required this.filterUnconfigured,
    required this.exporting,
    required this.exportProgress,
    required this.exportResult,
    this.coverPicker,
  });
  final PlaylistWithStatus playlist;
  final List<PlaylistWithStatus> allPlaylists;
  final bool filterUnconfigured;
  final bool exporting;
  final double exportProgress;
  final ExportResult? exportResult;
  final PlaylistCoverPicker? coverPicker;

  @override
  State<_PlaylistDetail> createState() => _PlaylistDetailState();
}

class _PlaylistDetailState extends State<_PlaylistDetail> {
  List<LevelMetadata> _selectedLevels = const [];

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
                  enablePlaylistBatchActions: false,
                  onSelectionChanged: _handleSelectionChanged,
                ),
        ),
      ],
    );
  }

  void _handleSelectionChanged(List<LevelMetadata> levels) {
    if (!mounted || _sameSelectionByPath(_selectedLevels, levels)) return;
    final schedulerPhase = WidgetsBinding.instance.schedulerPhase;
    final shouldDefer = schedulerPhase == SchedulerPhase.persistentCallbacks ||
        schedulerPhase == SchedulerPhase.transientCallbacks;
    if (shouldDefer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _sameSelectionByPath(_selectedLevels, levels)) return;
        setState(() {
          _selectedLevels = levels;
        });
      });
      return;
    }
    setState(() {
      _selectedLevels = levels;
    });
  }

  bool _sameSelectionByPath(
    List<LevelMetadata> current,
    List<LevelMetadata> next,
  ) {
    if (current.length != next.length) return false;
    final currentPaths = current
        .map((item) => item.levelPath.trim().toLowerCase())
        .toList(growable: false);
    final nextPaths = next
        .map((item) => item.levelPath.trim().toLowerCase())
        .toList(growable: false);
    for (var i = 0; i < currentPaths.length; i++) {
      if (currentPaths[i] != nextPaths[i]) return false;
    }
    return true;
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
                      else ...[
                        IconButton(
                          key: ValueKey('playlist-missing-delete-$index'),
                          icon: const Icon(Icons.delete_forever, size: 18),
                          tooltip: l10n?.common_delete ?? 'Delete',
                          onPressed: () => _confirmDeleteSongs(
                            context,
                            songs: [item],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, size: 18),
                          tooltip: 'Download',
                          onPressed: () => context
                              .read<PlaylistBloc>()
                              .add(DownloadMissingSongEvent(item)),
                        ),
                      ],
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
    final selectedCount = _selectedLevels.length;
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
                if (selectedCount > 0)
                  Text(
                    l10n?.ctx_selected_count(selectedCount) ??
                        '已选择 $selectedCount 项',
                    style: const TextStyle(
                      color: AppColors.brandPurple,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Tooltip(
            message: '设置歌单封面',
            child: IconButton(
              icon: const Icon(Icons.image, size: 20),
              onPressed: () => _setPlaylistCoverFromSong(context),
            ),
          ),
          Tooltip(
            message: l10n?.ctx_add_to_playlist ?? '添加到歌单',
            child: IconButton(
              icon: const Icon(Icons.playlist_add, size: 20),
              onPressed: selectedCount == 0
                  ? null
                  : () => _onAddOrMove(
                        context,
                        mode: PlaylistMutationMode.add,
                      ),
            ),
          ),
          Tooltip(
            message: l10n?.playlist_move_to_playlist ?? '移动到歌单',
            child: IconButton(
              icon: const Icon(Icons.drive_file_move, size: 20),
              onPressed: selectedCount == 0
                  ? null
                  : () => _onAddOrMove(
                        context,
                        mode: PlaylistMutationMode.move,
                      ),
            ),
          ),
          Tooltip(
            message: l10n?.ctx_delete_song_directory ?? '删除歌曲目录',
            child: IconButton(
              icon: const Icon(Icons.delete_forever, size: 20),
              onPressed:
                  selectedCount == 0 ? null : () => _confirmDeleteSelection(context),
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

  Future<void> _setPlaylistCoverFromSong(BuildContext context) async {
    final candidates = buildPlaylistCoverCandidates(
      widget.playlist.songs,
      fileExists: (path) => File(path).existsSync(),
    );
    if (!context.mounted) return;
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未找到可用封面图片')),
      );
      return;
    }
    final picker = widget.coverPicker ??
        ((
          BuildContext ctx,
          List<PlaylistCoverCandidate> items,
        ) =>
            PlaylistCoverPickerDialog.show(ctx, candidates: items));
    final picked = await picker(context, candidates);
    if (picked == null || !context.mounted) return;
    if (picked.clearRequested) {
      context.read<PlaylistBloc>().add(
            UpdatePlaylistCoverEvent(
              playlistPath: widget.playlist.info.filePath,
              imageBase64: null,
            ),
          );
      return;
    }
    try {
      final bytes = await File(picked.filePath!).readAsBytes();
      if (!context.mounted) return;
      context.read<PlaylistBloc>().add(
            UpdatePlaylistCoverEvent(
              playlistPath: widget.playlist.info.filePath,
              imageBase64: 'data:image/png;base64,${base64Encode(bytes)}',
            ),
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('读取封面失败：$e')),
      );
    }
  }

  Future<void> _confirmDeleteSelection(BuildContext context) async {
    final selectedSongs = _selectedSongsForCurrentSelection();
    await _confirmDeleteSongs(
      context,
      songs: selectedSongs,
      selectedLevelPaths: _selectedLevels.map((e) => e.levelPath).toList(),
    );
  }

  Future<void> _confirmDeleteSongs(
    BuildContext context, {
    required List<PlaylistSongWithStatus> songs,
    List<String> selectedLevelPaths = const [],
  }) async {
    if (songs.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    var deleteSongDirectories = false;
    final canDeleteDirectory = songs.any((song) => song.matchedLevel != null);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n?.playlist_delete_title ?? '删除歌单条目'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.playlist_delete_content(songs.length) ??
                        '将删除已选 ${songs.length} 个歌单条目。',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SwitchListTile(
                    value: canDeleteDirectory ? deleteSongDirectories : false,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n?.playlist_delete_with_directory ?? '同步删除歌曲目录'),
                    onChanged: canDeleteDirectory
                        ? (value) {
                            setState(() {
                              deleteSongDirectories = value;
                            });
                          }
                        : null,
                  ),
                  if (!canDeleteDirectory)
                    Text(
                      l10n?.playlist_delete_no_directory_hint ??
                          '当前条目未匹配本地歌曲目录，仅删除歌单项。',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n?.common_cancel ?? '取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n?.common_delete ?? '删除'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || !context.mounted || songs.isEmpty) return;
    final identities = songs.map(_songIdentity).toList();
    context.read<PlaylistBloc>().add(
          DeletePlaylistSongsEvent(
            levelPaths: selectedLevelPaths,
            songIdentities: identities,
            deleteSongDirectories: canDeleteDirectory && deleteSongDirectories,
          ),
        );
    setState(() {
      _selectedLevels = const [];
    });
  }

  List<PlaylistSongWithStatus> _selectedSongsForCurrentSelection() {
    if (_selectedLevels.isEmpty) return const [];
    final selectedPaths =
        _selectedLevels.map((e) => e.levelPath.trim().toLowerCase()).toSet();
    return widget.playlist.songs.where((song) {
      final path = song.matchedLevel?.levelPath.trim().toLowerCase() ?? '';
      return path.isNotEmpty && selectedPaths.contains(path);
    }).toList(growable: false);
  }

  String _songIdentity(PlaylistSongWithStatus status) {
    final song = status.song;
    final key = song.key.trim().toLowerCase();
    final hash = song.hash.trim().toLowerCase();
    return '$key|$hash';
  }

  Future<void> _onAddOrMove(
    BuildContext context, {
    required PlaylistMutationMode mode,
  }) async {
    final targetPlaylistPath =
        await _pickTargetPlaylistPath(context, mode: mode);
    if (targetPlaylistPath == null ||
        targetPlaylistPath.isEmpty ||
        !context.mounted ||
        _selectedLevels.isEmpty) {
      return;
    }
    context.read<PlaylistBloc>().add(
          MutatePlaylistSongsEvent(
            levelPaths: _selectedLevels.map((e) => e.levelPath).toList(),
            targetPlaylistPath: targetPlaylistPath,
            mode: mode,
          ),
        );
    setState(() {
      _selectedLevels = const [];
    });
  }

  Future<String?> _pickTargetPlaylistPath(
    BuildContext context, {
    required PlaylistMutationMode mode,
  }) async {
    return PlaylistPickerDialog.show(
      context,
      playlists: widget.allPlaylists,
      mode: mode,
      currentPlaylistPath: widget.playlist.info.filePath,
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
