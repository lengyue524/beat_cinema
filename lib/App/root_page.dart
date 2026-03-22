import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/Modules/Panel/audio_preview_panel.dart';
import 'package:beat_cinema/Modules/CinemaSearch/cinema_search_page.dart';
import 'package:beat_cinema/Modules/Panel/config_edit_panel.dart';
import 'package:beat_cinema/Modules/Panel/cubit/panel_cubit.dart';
import 'package:beat_cinema/Modules/Panel/file_info_panel.dart';
import 'package:beat_cinema/Modules/Panel/panel_host.dart';
import 'package:beat_cinema/Modules/Panel/sync_calibration_panel.dart';
import 'package:beat_cinema/Modules/Panel/video_preview_panel.dart';
import 'package:beat_cinema/Services/managers/download_manager.dart';
import 'package:beat_cinema/Services/repositories/video_repository.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class RootPage extends StatelessWidget {
  const RootPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => PanelCubit(),
      child: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(index),
            labelType: NavigationRailLabelType.none,
            minWidth: 72,
            destinations: [
              NavigationRailDestination(
                icon: Tooltip(
                  message: l10n?.nav_levels ?? 'Levels',
                  child: const Icon(Icons.library_music),
                ),
                label: Text(l10n?.nav_levels ?? 'Levels'),
              ),
              NavigationRailDestination(
                icon: Tooltip(
                  message: l10n?.nav_playlists ?? 'Playlists',
                  child: const Icon(Icons.queue_music),
                ),
                label: Text(l10n?.nav_playlists ?? 'Playlists'),
              ),
              NavigationRailDestination(
                icon: Tooltip(
                  message: l10n?.nav_downloads ?? 'Downloads',
                  child: _buildDownloadsNavIcon(context),
                ),
                label: Text(l10n?.nav_downloads ?? 'Downloads'),
              ),
              NavigationRailDestination(
                icon: Tooltip(
                  message: l10n?.nav_settings ?? 'Settings',
                  child: const Icon(Icons.settings),
                ),
                label: Text(l10n?.nav_settings ?? 'Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: navigationShell),
          PanelHost(
            contentBuilder: (type, ctx) => _buildPanelContent(type, ctx),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadsNavIcon(BuildContext context) {
    final manager = context.read<AppBloc>().downloadManager;
    if (manager == null) {
      return const Icon(Icons.download);
    }
    return StreamBuilder<List<DownloadTask>>(
      stream: manager.taskStream,
      initialData: manager.tasks,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? const <DownloadTask>[];
        final activeCount = tasks
            .where((task) =>
                task.status == DownloadStatus.pending ||
                task.status == DownloadStatus.downloading)
            .length;
        final badgeText = activeCount > 99 ? '99+' : '$activeCount';
        return Badge(
          isLabelVisible: activeCount > 0,
          label: Text(badgeText),
          child: const Icon(Icons.download),
        );
      },
    );
  }

  Widget _buildPanelContent(PanelContentType type, dynamic ctx) {
    final meta = ctx as LevelMetadata?;
    switch (type) {
      case PanelContentType.search:
        if (meta == null) {
          return const Center(
            child:
                Text('请选择歌曲后进行搜索', style: TextStyle(color: Color(0xFF9E9E9E))),
          );
        }
        return CinemaSearchPage(
          key: ValueKey('search-${meta.levelPath}'),
          levelInfo: meta.toLevelInfo(),
        );
      case PanelContentType.configEdit:
        if (meta == null) return const SizedBox.shrink();
        return ConfigEditPanel(
          key: ValueKey('config-${meta.levelPath}'),
          metadata: meta,
        );
      case PanelContentType.fileInfo:
        if (meta == null) return const SizedBox.shrink();
        return FileInfoPanel(
          key: ValueKey('fileinfo-${meta.levelPath}'),
          metadata: meta,
        );
      case PanelContentType.downloadDetail:
        return const Center(child: Text('Download detail'));
      case PanelContentType.audioPreview:
        if (meta == null) return const SizedBox.shrink();
        final audioFile = _findFileByExt(meta.levelPath, {'.ogg', '.egg'});
        if (audioFile == null) {
          return const Center(
            child: Text('No audio file found',
                style: TextStyle(color: Color(0xFF9E9E9E))),
          );
        }
        return AudioPreviewPanel(
          key: ValueKey('audio-${meta.levelPath}'),
          filePath: audioFile,
        );
      case PanelContentType.videoPreview:
        if (meta == null) return const SizedBox.shrink();
        final videoFile =
            _findFileByExt(meta.levelPath, {'.mp4', '.mkv', '.webm'});
        if (videoFile == null) {
          return const Center(
            child: Text('No video file found',
                style: TextStyle(color: Color(0xFF9E9E9E))),
          );
        }
        return VideoPreviewPanel(
          key: ValueKey('video-${meta.levelPath}'),
          filePath: videoFile,
        );
      case PanelContentType.syncCalibration:
        if (meta == null) return const SizedBox.shrink();
        return SyncCalibrationPanel(
          key: ValueKey('sync-${meta.levelPath}'),
          metadata: meta,
        );
    }
  }

  static String? _findFileByExt(String dirPath, Set<String> extensions) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return null;
    for (final f in dir.listSync()) {
      if (f is File && extensions.contains(p.extension(f.path).toLowerCase())) {
        return f.path;
      }
    }
    return null;
  }
}
