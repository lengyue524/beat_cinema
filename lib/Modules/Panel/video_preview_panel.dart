import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/main.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPreviewPanel extends StatefulWidget {
  const VideoPreviewPanel({super.key, required this.filePath});
  final String filePath;

  @override
  State<VideoPreviewPanel> createState() => _VideoPreviewPanelState();
}

class _VideoPreviewPanelState extends State<VideoPreviewPanel> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _player = playerService.createVideoPlayer();
    _controller = VideoController(_player);
    _player.open(Media(widget.filePath), play: false);
  }

  @override
  void dispose() {
    playerService.disposePlayer(_player);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Video(controller: _controller),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.play_arrow,
                    color: AppColors.brandPurple),
                onPressed: () => _player.playOrPause(),
              ),
              IconButton(
                icon: const Icon(Icons.stop,
                    color: AppColors.textSecondary),
                onPressed: () {
                  _player.pause();
                  _player.seek(Duration.zero);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
