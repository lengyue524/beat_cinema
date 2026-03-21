import 'dart:io';

import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Modules/CustomLevels/widgets/difficulty_badge.dart';
import 'package:beat_cinema/Modules/CustomLevels/widgets/status_indicator.dart';
import 'package:beat_cinema/Modules/Panel/context_menu_region.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class LevelListTile extends StatelessWidget {
  const LevelListTile({
    super.key,
    required this.metadata,
    this.isSelected = false,
    this.onTap,
    this.enabled = true,
    this.contextMenuItems = const [],
    this.onPlayAudio,
    this.isPlayingAudio = false,
    this.onVideoPreview,
    this.onDownloadConfiguredVideo,
    this.configuredVideoDownloadTooltip,
    this.configuredVideoDownloading = false,
  });

  final LevelMetadata metadata;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool enabled;
  final List<ContextMenuItem> contextMenuItems;
  final VoidCallback? onPlayAudio;
  final bool isPlayingAudio;
  final VoidCallback? onVideoPreview;
  final VoidCallback? onDownloadConfiguredVideo;
  final String? configuredVideoDownloadTooltip;
  final bool configuredVideoDownloading;

  @override
  Widget build(BuildContext context) {
    return ContextMenuRegion(
      menuItems: contextMenuItems,
      child: Semantics(
        label: '${metadata.songName} by ${metadata.songAuthorName}',
        child: Opacity(
          opacity: enabled ? 1.0 : 0.38,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onTap : null,
              hoverColor: AppColors.surface3,
              splashColor: AppColors.surface4,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: isSelected
                      ? const Border(
                          left: BorderSide(
                              color: AppColors.brandPurple, width: 3))
                      : null,
                ),
                child: Row(
                  children: [
                    _CoverWithPlayButton(
                      metadata: metadata,
                      isPlaying: isPlayingAudio,
                      onPlay: onPlayAudio,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metadata.songName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            metadata.songAuthorName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _VideoStatusIcon(
                      status: metadata.videoStatus,
                      progress: metadata.downloadProgress,
                      onTap: onVideoPreview,
                      onDownloadConfiguredVideo: onDownloadConfiguredVideo,
                      configuredVideoDownloadTooltip:
                          configuredVideoDownloadTooltip,
                      configuredVideoDownloading: configuredVideoDownloading,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    DifficultyBadge(difficulties: metadata.difficulties),
                    const SizedBox(width: AppSpacing.xs),
                    SizedBox(
                      width: 40,
                      child: Text(
                        metadata.bpm > 0 ? metadata.bpm.toStringAsFixed(0) : '',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoStatusIcon extends StatefulWidget {
  const _VideoStatusIcon({
    required this.status,
    this.progress = 0,
    this.onTap,
    this.onDownloadConfiguredVideo,
    this.configuredVideoDownloadTooltip,
    this.configuredVideoDownloading = false,
  });
  final VideoConfigStatus status;
  final double progress;
  final VoidCallback? onTap;
  final VoidCallback? onDownloadConfiguredVideo;
  final String? configuredVideoDownloadTooltip;
  final bool configuredVideoDownloading;

  @override
  State<_VideoStatusIcon> createState() => _VideoStatusIconState();
}

class _VideoStatusIconState extends State<_VideoStatusIcon> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.status == VideoConfigStatus.configuredMissingFile) {
      if (widget.configuredVideoDownloading) {
        return const StatusIndicator(
          status: VideoConfigStatus.downloading,
        );
      }
      final onDownload = widget.onDownloadConfiguredVideo;
      if (onDownload == null) {
        return const StatusIndicator(
          status: VideoConfigStatus.configuredMissingFile,
        );
      }
      return Tooltip(
        message: widget.configuredVideoDownloadTooltip ??
            l10n?.ctx_download_configured_video ??
            '按配置下载视频',
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: onDownload,
            child: SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: Icon(
                  _hovering ? Icons.download_rounded : Icons.cloud_download,
                  size: 20,
                  color: AppColors.warning,
                  semanticLabel:
                      l10n?.ctx_download_configured_video ?? '按配置下载视频',
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (widget.status != VideoConfigStatus.configured) {
      return StatusIndicator(
        status: widget.status,
        progress: widget.progress,
      );
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: Icon(
              _hovering ? Icons.play_circle_filled : Icons.movie,
              size: 20,
              color: _hovering
                  ? AppColors.brandPurple
                  : AppColors.brandPurple.withValues(alpha: 0.7),
              semanticLabel: l10n?.sem_action_play_video ?? '播放视频',
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverWithPlayButton extends StatefulWidget {
  const _CoverWithPlayButton({
    required this.metadata,
    required this.isPlaying,
    this.onPlay,
  });
  final LevelMetadata metadata;
  final bool isPlaying;
  final VoidCallback? onPlay;

  @override
  State<_CoverWithPlayButton> createState() => _CoverWithPlayButtonState();
}

class _CoverWithPlayButtonState extends State<_CoverWithPlayButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPlay,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: _buildCoverImage(),
              ),
              if (_hovering || widget.isPlaying)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      widget.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    final filename = widget.metadata.coverImageFilename;
    if (filename != null && filename.isNotEmpty) {
      return Image.file(
        File(p.join(widget.metadata.levelPath, filename)),
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        cacheWidth: 88,
        errorBuilder: (_, __, ___) => _defaultCover(),
      );
    }
    return _defaultCover();
  }

  Widget _defaultCover() {
    return Container(
      width: 44,
      height: 44,
      color: AppColors.surface3,
      child:
          const Icon(Icons.music_note, color: AppColors.textDisabled, size: 24),
    );
  }
}
