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
    this.videoStatusOverride,
    this.onContextMenuRequested,
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
  final VideoConfigStatus? videoStatusOverride;
  final VoidCallback? onContextMenuRequested;

  @override
  Widget build(BuildContext context) {
    final effectiveVideoStatus = videoStatusOverride ?? metadata.videoStatus;
    return ContextMenuRegion(
      menuItems: contextMenuItems,
      onBeforeOpen: onContextMenuRequested,
      child: Semantics(
        label: '${metadata.songName} by ${metadata.songAuthorName}',
        selected: isSelected,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.38,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onTap : null,
              hoverColor: AppColors.surface3,
              splashColor: AppColors.surface4,
              child: Container(
                  key: isSelected
                      ? ValueKey('level-tile-selected-${metadata.levelPath}')
                      : ValueKey('level-tile-${metadata.levelPath}'),
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
                          SelectionArea(
                            child: Text(
                              metadata.songName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  metadata.levelAuthorName,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              DifficultyBadge(
                                  difficulties: metadata.difficulties),
                              const SizedBox(width: AppSpacing.xs),
                              _BpmWithIcon(bpm: metadata.bpm),
                              const SizedBox(width: AppSpacing.xs),
                              _SongDurationWithIcon(metadata: metadata),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _VideoStatusIcon(
                      status: effectiveVideoStatus,
                      progress: metadata.downloadProgress,
                      onTap: onVideoPreview,
                      onDownloadConfiguredVideo: onDownloadConfiguredVideo,
                      configuredVideoDownloadTooltip:
                          configuredVideoDownloadTooltip,
                      configuredVideoDownloading: configuredVideoDownloading,
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

class _BpmWithIcon extends StatelessWidget {
  const _BpmWithIcon({required this.bpm});

  final double bpm;

  @override
  Widget build(BuildContext context) {
    if (bpm <= 0) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.av_timer,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 2),
        Text(
          bpm.toStringAsFixed(0),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _SongDurationWithIcon extends StatefulWidget {
  const _SongDurationWithIcon({required this.metadata});

  final LevelMetadata metadata;

  @override
  State<_SongDurationWithIcon> createState() => _SongDurationWithIconState();
}

class _SongDurationWithIconState extends State<_SongDurationWithIcon> {
  static final Map<String, int> _durationCache = <String, int>{};
  static final Map<String, Future<int?>> _pending = <String, Future<int?>>{};
  int? _seconds;

  @override
  void initState() {
    super.initState();
    _seconds = _fallbackPreviewSeconds(widget.metadata);
    _resolveSongDuration();
  }

  @override
  void didUpdateWidget(covariant _SongDurationWithIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metadata.levelPath == widget.metadata.levelPath &&
        oldWidget.metadata.lastModified == widget.metadata.lastModified) {
      return;
    }
    _seconds = _fallbackPreviewSeconds(widget.metadata);
    _resolveSongDuration();
  }

  Future<void> _resolveSongDuration() async {
    final audioPath = _resolveAudioPath(widget.metadata);
    if (audioPath == null) return;
    final cacheKey = audioPath.toLowerCase();
    final cached = _durationCache[cacheKey];
    if (cached != null && cached > 0) {
      if (mounted) {
        setState(() => _seconds = cached);
      }
      return;
    }
    final pending = _pending[cacheKey];
    if (pending != null) {
      final reused = await pending;
      if (!mounted || reused == null || reused <= 0) return;
      setState(() => _seconds = reused);
      return;
    }
    final future = _readAudioDurationSeconds(audioPath);
    _pending[cacheKey] = future;
    final resolved = await future;
    _pending.remove(cacheKey);
    if (resolved == null || resolved <= 0) return;
    _durationCache[cacheKey] = resolved;
    if (!mounted) return;
    setState(() => _seconds = resolved);
  }

  static int? _fallbackPreviewSeconds(LevelMetadata metadata) {
    final raw = metadata.rawLevel?.previewDuration;
    if (raw == null || raw <= 0) return null;
    return raw.floor();
  }

  static String? _resolveAudioPath(LevelMetadata metadata) {
    final fromInfo = (metadata.rawLevel?.songFilename ?? '').trim();
    if (fromInfo.isNotEmpty) {
      final byInfo = p.join(metadata.levelPath, fromInfo);
      if (File(byInfo).existsSync()) return byInfo;
    }
    try {
      final dir = Directory(metadata.levelPath);
      if (!dir.existsSync()) return null;
      final audio = dir.listSync().whereType<File>().firstWhere(
            (file) {
              final ext = p.extension(file.path).toLowerCase();
              return ext == '.egg' ||
                  ext == '.ogg' ||
                  ext == '.wav' ||
                  ext == '.mp3';
            },
            orElse: () => File(''),
          );
      return audio.path.isEmpty ? null : audio.path;
    } catch (_) {
      return null;
    }
  }

  static Future<int?> _readAudioDurationSeconds(String audioPath) async {
    final ext = p.extension(audioPath).toLowerCase();
    if (ext == '.ogg' || ext == '.egg') {
      return _readOggDurationSeconds(audioPath);
    }
    return null;
  }

  static Future<int?> _readOggDurationSeconds(String audioPath) async {
    try {
      final bytes = await File(audioPath).readAsBytes();
      if (bytes.length < 64) return null;
      final sampleRate = _extractVorbisSampleRate(bytes);
      if (sampleRate == null || sampleRate <= 0) return null;
      final granule = _extractLastOggGranulePosition(bytes);
      if (granule == null || granule <= 0) return null;
      return (granule / sampleRate).round();
    } catch (_) {
      return null;
    }
  }

  static int? _extractVorbisSampleRate(List<int> bytes) {
    for (var i = 0; i + 15 < bytes.length; i++) {
      if (bytes[i] == 0x01 &&
          bytes[i + 1] == 0x76 &&
          bytes[i + 2] == 0x6F &&
          bytes[i + 3] == 0x72 &&
          bytes[i + 4] == 0x62 &&
          bytes[i + 5] == 0x69 &&
          bytes[i + 6] == 0x73) {
        final offset = i + 12;
        if (offset + 3 >= bytes.length) return null;
        return bytes[offset] |
            (bytes[offset + 1] << 8) |
            (bytes[offset + 2] << 16) |
            (bytes[offset + 3] << 24);
      }
    }
    return null;
  }

  static int? _extractLastOggGranulePosition(List<int> bytes) {
    var i = 0;
    int? lastGranule;
    while (i + 27 <= bytes.length) {
      final isOggPage = bytes[i] == 0x4F &&
          bytes[i + 1] == 0x67 &&
          bytes[i + 2] == 0x67 &&
          bytes[i + 3] == 0x53;
      if (!isOggPage) {
        i++;
        continue;
      }
      final segmentCount = bytes[i + 26];
      if (i + 27 + segmentCount > bytes.length) break;
      var payloadLen = 0;
      for (var s = 0; s < segmentCount; s++) {
        payloadLen += bytes[i + 27 + s];
      }
      final pageLen = 27 + segmentCount + payloadLen;
      if (i + pageLen > bytes.length) break;
      final granule = _readUint64LittleEndian(bytes, i + 6);
      if (granule > 0) {
        lastGranule = granule;
      }
      i += pageLen;
    }
    return lastGranule;
  }

  static int _readUint64LittleEndian(List<int> bytes, int offset) {
    var value = 0;
    for (var i = 0; i < 8; i++) {
      value |= bytes[offset + i] << (8 * i);
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final rawSeconds = _seconds;
    if (rawSeconds == null || rawSeconds <= 0) {
      return const SizedBox.shrink();
    }
    final formatted = _formatToMmSs(rawSeconds);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.schedule,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 2),
        Text(
          formatted,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatToMmSs(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
