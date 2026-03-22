import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/main.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class AudioPreviewPanel extends StatefulWidget {
  const AudioPreviewPanel({super.key, required this.filePath});
  final String filePath;

  @override
  State<AudioPreviewPanel> createState() => _AudioPreviewPanelState();
}

class _AudioPreviewPanelState extends State<AudioPreviewPanel> {
  late final Player _player;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = playerService.createAudioPlayer();
    _player.open(Media(widget.filePath), play: false);
    _player.stream.playing.listen((p) {
      if (mounted) setState(() => _playing = p);
    });
    _player.stream.position.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.stream.duration.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    playerService.disposePlayer(_player);
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _playing ? Icons.pause : Icons.play_arrow,
                  color: AppColors.brandPurple,
                ),
                onPressed: () => _player.playOrPause(),
              ),
              Flexible(
                child: Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Slider(
            value: _duration.inMilliseconds > 0
                ? _position.inMilliseconds / _duration.inMilliseconds
                : 0,
            onChanged: (v) {
              _player.seek(Duration(
                  milliseconds:
                      (v * _duration.inMilliseconds).toInt()));
            },
            activeColor: AppColors.brandPurple,
          ),
        ],
      ),
    );
  }
}
