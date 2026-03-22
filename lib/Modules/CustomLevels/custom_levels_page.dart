import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Modules/CustomLevels/bloc/custom_levels_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/widgets/level_list_view.dart';
import 'package:beat_cinema/Modules/CustomLevels/widgets/skeleton_list.dart';
import 'package:beat_cinema/Modules/CustomLevels/widgets/summary_bar.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';

class CustomLevelsPage extends StatefulWidget {
  const CustomLevelsPage({super.key});

  @override
  State<CustomLevelsPage> createState() => _CustomLevelsPageState();
}

class _CustomLevelsPageState extends State<CustomLevelsPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _searchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (_searchVisible) {
        _searchFocusNode.requestFocus();
      } else {
        _searchController.clear();
        context.read<CustomLevelsBloc>().add(SearchQueryChanged(''));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _toggleSearch,
      },
      child: Focus(
        autofocus: true,
        child: BlocBuilder<CustomLevelsBloc, CustomLevelsState>(
          builder: (context, state) {
            if (state is CustomLevelsInitial) {
              _loadLevels();
              return _initPage();
            }
            if (state is CustomLevelsLoading) {
              if (state.hasCache && state.cachedLevels.isNotEmpty) {
                return _buildList(
                  state.cachedLevels,
                  loading: true,
                  loadingState: state,
                );
              }
              return _buildLoadingState(state);
            }
            if (state is CustomLevelsError) {
              return Center(
                child: Text(state.message,
                    style: const TextStyle(color: AppColors.error)),
              );
            }
            if (state is CustomLevelsLoaded) {
              return _buildList(state.filteredLevels);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _loadLevels() {
    final path =
        (context.read<AppBloc>().state as AppLaunchComplated).beatSaberPath;
    if (path != null) {
      context.read<CustomLevelsBloc>().add(ReloadCustomLevelsEvent(path));
    }
  }

  void _refreshLevels() {
    _loadLevels();
  }

  Widget _initPage() {
    final path = context.read<AppBloc>().beatSaberPath;
    if (path == null || path.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.set_game_path_tips));
    }
    return const Center(
        child: SizedBox(
            height: 48,
            width: 48,
            child: CircularProgressIndicator.adaptive()));
  }

  Widget _buildList(
    List<LevelMetadata> levels, {
    bool loading = false,
    CustomLevelsLoading? loadingState,
  }) {
    final l10n = AppLocalizations.of(context);
    final total = loadingState?.total ?? 0;
    final parsed = loadingState?.parsed ?? 0;
    final progress = total > 0 ? (parsed / total).clamp(0.0, 1.0) : null;
    return Column(
      children: [
        _buildToolbar(l10n),
        if (loading && total > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n?.levels_loading_progress(parsed, total) ??
                      'Parsed songs: $parsed / $total',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  color: AppColors.brandPurple,
                  backgroundColor: AppColors.surface3,
                ),
              ],
            ),
          ),
        const SummaryBar(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: loading
                ? const SkeletonList(key: ValueKey('skeleton'))
                : LevelListView.fromLevels(
                    key: const ValueKey('list'),
                    levels: levels,
                    autoReloadAfterConfigDownload: false,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(CustomLevelsLoading state) {
    final l10n = AppLocalizations.of(context);
    if (state.total <= 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator.adaptive(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n?.levels_loading_scanning ?? 'Scanning song folders...',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    final progress = (state.parsed / state.total).clamp(0.0, 1.0);
    final stageText = switch (state.stage) {
      CustomLevelsLoadingStage.scanning =>
        l10n?.levels_loading_scanning ?? 'Scanning song folders...',
      CustomLevelsLoadingStage.parsing =>
        l10n?.levels_loading_parsing ?? 'Parsing songs...',
    };
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
                l10n?.levels_loading_title ?? 'Loading songs...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                stageText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n?.levels_loading_progress(state.parsed, state.total) ??
                    'Parsed songs: ${state.parsed} / ${state.total}',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          if (_searchVisible)
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: l10n?.filter_tips ?? '搜索...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _toggleSearch,
                    ),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (value) {
                    context
                        .read<CustomLevelsBloc>()
                        .add(SearchQueryChanged(value));
                  },
                ),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search, size: 20),
              tooltip: 'Ctrl+F',
              onPressed: _toggleSearch,
            ),
            const Spacer(),
          ],
          const SizedBox(width: AppSpacing.sm),
          _buildRefreshButton(l10n),
          const SizedBox(width: AppSpacing.xs),
          _buildMoreButton(l10n),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(AppLocalizations? l10n) {
    return IconButton(
      tooltip: l10n?.refresh_levels ?? 'Refresh Levels',
      icon: const Icon(Icons.refresh, size: 20),
      onPressed: _refreshLevels,
    );
  }

  Widget _buildMoreButton(AppLocalizations? l10n) {
    return BlocBuilder<CustomLevelsBloc, CustomLevelsState>(
      buildWhen: (prev, curr) => curr is CustomLevelsLoaded,
      builder: (context, state) {
        final loaded = state is CustomLevelsLoaded ? state : null;
        final hasFilter = loaded != null && !loaded.filter.isEmpty;

        return PopupMenuButton<String>(
          tooltip: l10n?.more_tooltip ?? 'More',
          icon: Badge(
            isLabelVisible: hasFilter,
            smallSize: 8,
            child: const Icon(Icons.more_vert, size: 20),
          ),
          onSelected: (value) => _handleToolbarSelection(value, loaded),
          itemBuilder: (context) => [
            ..._sortItemsForMoreMenu(loaded, l10n),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'clear',
              enabled: hasFilter,
              child: Text(l10n?.filter_clear ?? '清除筛选'),
            ),
            const PopupMenuDivider(),
            ..._difficultyFilterItems(loaded?.filter),
            const PopupMenuDivider(),
            ..._videoStatusFilterItems(loaded?.filter, l10n),
          ],
        );
      },
    );
  }

  List<PopupMenuEntry<String>> _sortItemsForMoreMenu(
      CustomLevelsLoaded? loaded, AppLocalizations? l10n) {
    final currentField = loaded?.sortField ?? SortField.songName;
    final currentDir = loaded?.sortDirection ?? SortDirection.ascending;
    PopupMenuItem<String> item(SortField field, String label) {
      final isCurrent = currentField == field;
      return PopupMenuItem<String>(
        value: 'sort:${field.name}',
        child: Row(
          children: [
            if (isCurrent)
              Icon(
                currentDir == SortDirection.ascending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 16,
                color: AppColors.brandPurple,
              )
            else
              const SizedBox(width: 16),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      );
    }

    return [
      item(SortField.songName, l10n?.sort_song_name ?? '歌名'),
      item(SortField.songAuthor, l10n?.sort_author ?? '作者'),
      item(SortField.bpm, 'BPM'),
      item(SortField.lastModified, l10n?.sort_modified ?? '修改时间'),
    ];
  }

  void _handleToolbarSelection(String value, CustomLevelsLoaded? loaded) {
    if (value.startsWith('sort:')) {
      final raw = value.substring(5);
      final field = SortField.values.firstWhere(
        (candidate) => candidate.name == raw,
        orElse: () => SortField.songName,
      );
      final currentField = loaded?.sortField ?? SortField.songName;
      final currentDir = loaded?.sortDirection ?? SortDirection.ascending;
      final dir = field == currentField && currentDir == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
      context.read<CustomLevelsBloc>().add(SortChanged(field, dir));
      return;
    }
    _handleFilterSelection(value, loaded);
  }

  List<PopupMenuEntry<String>> _difficultyFilterItems(FilterCriteria? filter) {
    const diffs = ['Easy', 'Normal', 'Hard', 'Expert', 'ExpertPlus'];
    return diffs.map((d) {
      final active = filter?.difficulties.contains(d) ?? false;
      return PopupMenuItem<String>(
        value: 'diff:$d',
        child: Row(
          children: [
            Icon(
              active ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: active ? AppColors.brandPurple : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(d),
          ],
        ),
      );
    }).toList();
  }

  List<PopupMenuEntry<String>> _videoStatusFilterItems(
      FilterCriteria? filter, AppLocalizations? l10n) {
    final items = {
      VideoConfigStatus.none: l10n?.status_no_video ?? '无视频',
      VideoConfigStatus.configured: l10n?.status_configured ?? '已配置',
      VideoConfigStatus.configuredMissingFile:
          l10n?.status_configured_missing_file ?? '已配置（缺少文件）',
      VideoConfigStatus.downloading: l10n?.status_downloading ?? '下载中',
    };
    return items.entries.map((e) {
      final active = filter?.videoStatuses.contains(e.key) ?? false;
      return PopupMenuItem<String>(
        value: 'vs:${e.key.index}',
        child: Row(
          children: [
            Icon(
              active ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: active ? AppColors.brandPurple : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(e.value),
          ],
        ),
      );
    }).toList();
  }

  void _handleFilterSelection(String value, CustomLevelsLoaded? loaded) {
    if (loaded == null) return;
    final bloc = context.read<CustomLevelsBloc>();
    if (value == 'clear') {
      bloc.add(FilterChanged(const FilterCriteria()));
      return;
    }
    if (value.startsWith('diff:')) {
      final d = value.substring(5);
      final current = Set<String>.from(loaded.filter.difficulties);
      if (current.contains(d)) {
        current.remove(d);
      } else {
        current.add(d);
      }
      bloc.add(FilterChanged(loaded.filter.copyWith(difficulties: current)));
    }
    if (value.startsWith('vs:')) {
      final idx = int.parse(value.substring(3));
      final status = VideoConfigStatus.values[idx];
      final current = Set<VideoConfigStatus>.from(loaded.filter.videoStatuses);
      if (current.contains(status)) {
        current.remove(status);
      } else {
        current.add(status);
      }
      bloc.add(FilterChanged(loaded.filter.copyWith(videoStatuses: current)));
    }
  }
}
