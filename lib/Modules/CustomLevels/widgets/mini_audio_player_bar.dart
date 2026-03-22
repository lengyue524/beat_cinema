import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MiniAudioPlayerBar extends StatefulWidget {
  const MiniAudioPlayerBar({
    super.key,
    required this.visible,
    required this.songName,
    required this.onStop,
    required this.stopTooltip,
    required this.position,
    required this.duration,
    this.onSeek,
    this.coverImage,
    this.coverSemanticLabel,
  });

  final bool visible;
  final String songName;
  final VoidCallback onStop;
  final String stopTooltip;
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration>? onSeek;
  final ImageProvider? coverImage;
  final String? coverSemanticLabel;

  @override
  State<MiniAudioPlayerBar> createState() => _MiniAudioPlayerBarState();
}

class _MiniAudioPlayerBarState extends State<MiniAudioPlayerBar>
    with SingleTickerProviderStateMixin {
  static const double _barMinWidth = 420;
  static const double _barMaxWidth = 760;
  static const double _songNameMaxWidth = 180;
  static const double _songNameMinWidth = 80;
  late final AnimationController _rotationController;
  double? _draggingValueMs;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (widget.visible) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MiniAudioPlayerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!widget.visible && _rotationController.isAnimating) {
      _rotationController.stop();
      _rotationController.value = 0;
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return const SizedBox.shrink();
    }

    final durationMs = widget.duration.inMilliseconds;
    final positionMs = widget.position.inMilliseconds
        .clamp(0, durationMs > 0 ? durationMs : 0);
    final canSeek = durationMs > 0 && widget.onSeek != null;
    final sliderMax = durationMs > 0 ? durationMs.toDouble() : 1.0;
    final sliderValue =
        (_draggingValueMs ?? positionMs.toDouble()).clamp(0.0, sliderMax);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : _barMaxWidth;
        final barWidth = maxWidth.clamp(_barMinWidth, _barMaxWidth).toDouble();
        return Material(
          elevation: 8,
          color: Colors.transparent,
          child: SizedBox(
            width: barWidth,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface2.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.brandPurple.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  RotationTransition(
                    turns: _rotationController,
                    child: Semantics(
                      label: widget.coverSemanticLabel,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surface3,
                        backgroundImage: widget.coverImage,
                        child: widget.coverImage == null
                            ? const Icon(
                                Icons.music_note,
                                color: AppColors.textSecondary,
                                size: 18,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                        minWidth: _songNameMinWidth,
                        maxWidth: _songNameMaxWidth),
                    child: Text(
                      widget.songName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _formatDuration(
                        Duration(milliseconds: sliderValue.toInt())),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Expanded(
                    flex: 99,
                    child: Slider(
                      value: sliderValue,
                      min: 0,
                      max: sliderMax,
                      onChanged: canSeek
                          ? (value) => setState(() => _draggingValueMs = value)
                          : null,
                      onChangeEnd: canSeek
                          ? (value) {
                              widget.onSeek?.call(
                                Duration(milliseconds: value.toInt()),
                              );
                              setState(() => _draggingValueMs = null);
                            }
                          : null,
                    ),
                  ),
                  Text(
                    _formatDuration(widget.duration),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  IconButton(
                    tooltip: widget.stopTooltip,
                    onPressed: widget.onStop,
                    icon: const Icon(Icons.close, color: AppColors.brandPurple),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
