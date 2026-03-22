import 'dart:async';

import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Common/log.dart';
import 'package:beat_cinema/main.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPreviewDialog extends StatefulWidget {
  const VideoPreviewDialog({
    super.key,
    required this.filePath,
    this.title,
    this.autoCloseOnError = false,
    this.onPlaybackError,
  });
  final String filePath;
  final String? title;
  final bool autoCloseOnError;
  final Future<String?> Function()? onPlaybackError;

  static Future<bool> show(
    BuildContext context, {
    required String filePath,
    String? title,
    bool autoCloseOnError = false,
    Future<String?> Function()? onPlaybackError,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => VideoPreviewDialog(
        filePath: filePath,
        title: title,
        autoCloseOnError: autoCloseOnError,
        onPlaybackError: onPlaybackError,
      ),
    ).then((value) => value ?? true);
  }

  @override
  State<VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<VideoPreviewDialog> {
  late final Player _player;
  late final VideoController _controller;
  StreamSubscription<String>? _errorSub;
  bool _hasPlaybackError = false;
  bool _handlingPlaybackError = false;
  bool _fallbackAttempted = false;

  @override
  void initState() {
    super.initState();
    _player = playerService.createVideoPlayer();
    _controller = VideoController(_player);
    _errorSub = _player.stream.error.listen(_onPlayerError);
    _openMedia();
  }

  Future<void> _openMedia() async {
    try {
      await _player.open(Media(widget.filePath), play: true);
    } catch (e, st) {
      _hasPlaybackError = true;
      log.e('[VideoPreviewDialog] open failed path=${widget.filePath}', e, st);
      if (!mounted || !widget.autoCloseOnError) return;
      Navigator.of(context).pop(false);
    }
  }

  void _onPlayerError(String error) {
    if (_handlingPlaybackError) return;
    if (_hasPlaybackError && _fallbackAttempted) return;
    _handlingPlaybackError = true;
    _hasPlaybackError = true;
    log.w('[VideoPreviewDialog] player error path=${widget.filePath} error=$error');
    _handlePlaybackError();
  }

  Future<void> _handlePlaybackError() async {
    if (widget.onPlaybackError != null && !_fallbackAttempted) {
      _fallbackAttempted = true;
      try {
        final fallbackPath = await widget.onPlaybackError!.call();
        if (!mounted) return;
        if (fallbackPath != null && fallbackPath.trim().isNotEmpty) {
          _hasPlaybackError = false;
          await _player.open(Media(fallbackPath.trim()), play: true);
          return;
        }
      } catch (e, st) {
        log.e('[VideoPreviewDialog] fallback playback failed', e, st);
      } finally {
        _handlingPlaybackError = false;
      }
      return;
    }
    _handlingPlaybackError = false;
    if (!mounted || !widget.autoCloseOnError) return;
    Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    _errorSub?.cancel();
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
                    onPressed: () => Navigator.of(context).pop(true),
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Video(controller: _controller),
                    ),
                    if (_handlingPlaybackError)
                      const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
