import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/main.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPreviewDialog extends StatefulWidget {
  const VideoPreviewDialog({super.key, required this.filePath, this.title});
  final String filePath;
  final String? title;

  static Future<void> show(
    BuildContext context, {
    required String filePath,
    String? title,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => VideoPreviewDialog(filePath: filePath, title: title),
    );
  }

  @override
  State<VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<VideoPreviewDialog> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _player = playerService.createVideoPlayer();
    _controller = VideoController(_player);
    _player.open(Media(widget.filePath), play: true);
  }

  @override
  void dispose() {
    playerService.disposePlayer(_player);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface1,
      insetPadding: const EdgeInsets.all(40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (widget.title != null)
                    Expanded(
                      child: Text(
                        widget.title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Video(controller: _controller),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
