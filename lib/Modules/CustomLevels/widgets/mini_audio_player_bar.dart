import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MiniAudioPlayerBar extends StatefulWidget {
  const MiniAudioPlayerBar({
    super.key,
    required this.visible,
    required this.songName,
    required this.onStop,
    required this.stopTooltip,
    this.coverImage,
    this.coverSemanticLabel,
  });

  final bool visible;
  final String songName;
  final VoidCallback onStop;
  final String stopTooltip;
  final ImageProvider? coverImage;
  final String? coverSemanticLabel;

  @override
  State<MiniAudioPlayerBar> createState() => _MiniAudioPlayerBarState();
}

class _MiniAudioPlayerBarState extends State<MiniAudioPlayerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

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

    return Material(
      elevation: 8,
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface2.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.4)),
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
            Expanded(
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
            IconButton(
              tooltip: widget.stopTooltip,
              onPressed: widget.onStop,
              icon: const Icon(Icons.stop, color: AppColors.brandPurple),
            ),
          ],
        ),
      ),
    );
  }
}
