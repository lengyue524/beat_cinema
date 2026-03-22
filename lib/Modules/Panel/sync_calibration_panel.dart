import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:beat_cinema/App/theme/app_colors.dart';
import 'package:beat_cinema/Services/services/atomic_file_service.dart';
import 'package:beat_cinema/l10n/app_localizations.dart';
import 'package:beat_cinema/main.dart';
import 'package:beat_cinema/models/level_metadata.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;

class SyncCalibrationPanel extends StatefulWidget {
  const SyncCalibrationPanel({super.key, required this.metadata});
  final LevelMetadata metadata;

  @override
  State<SyncCalibrationPanel> createState() => _SyncCalibrationPanelState();
}

class _SyncCalibrationPanelState extends State<SyncCalibrationPanel> {
  late final Player _audioPlayer;
  late final Player _videoPlayer;
  late final VideoController _videoController;
  final _offsetFocus = FocusNode();
  int _offsetMs = 0;
  final _offsetController = TextEditingController(text: '0');
  bool _playing = false;

  bool _channelSepActive = false;
  bool _channelSepFailed = false;
  String _channelSepStatus = '';
  StreamSubscription<String>? _audioErrorSub;
  StreamSubscription<String>? _videoErrorSub;

  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  static const _kLeftFilter = 'lavfi=[pan=stereo|c0=c0+c1|c1=0*c0]';
  static const _kRightFilter = 'lavfi=[pan=stereo|c0=0*c0|c1=c0+c1]';

  @override
  void initState() {
    super.initState();
    _audioPlayer = playerService.createAudioPlayer();
    _videoPlayer = playerService.createVideoPlayer();
    _videoController = VideoController(_videoPlayer);

    _audioPlayer.stream.playing.listen((playing) {
      if (mounted) setState(() => _playing = playing);
    });

    _positionSub = _videoPlayer.stream.position.listen((pos) {
      if (mounted) setState(() => _videoPosition = pos);
    });
    _durationSub = _videoPlayer.stream.duration.listen((dur) {
      if (mounted) setState(() => _videoDuration = dur);
    });

    _audioErrorSub = _audioPlayer.stream.error.listen(_onPlayerError);
    _videoErrorSub = _videoPlayer.stream.error.listen(_onPlayerError);

    _offsetFocus.addListener(_onOffsetFocusChange);

    final existing = widget.metadata.cinemaConfig?.offset;
    if (existing != null) {
      _offsetMs = existing;
      _offsetController.text = _offsetMs.toString();
    }

    _initPlayers();
  }

  void _onPlayerError(String error) {
    debugPrint('[SyncCal] player error: $error');
    if (error.contains('Audio filter') && _channelSepActive) {
      _resetFilters();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _channelSepActive = false;
          _channelSepFailed = true;
          _channelSepStatus =
              l10n?.sync_filter_unavailable ?? 'Filter unavailable';
        });
      }
    }
  }

  void _onOffsetFocusChange() {
    if (!_offsetFocus.hasFocus) {
      _applyOffsetToCurrentPosition();
    }
  }

  Future<void> _initPlayers() async {
    final audioFile = _findFile({'.ogg', '.egg'});
    final videoFile = _findFile({'.mp4', '.mkv', '.webm'});
    if (audioFile != null) {
      debugPrint('[SyncCal] audioFile=$audioFile');
      await _audioPlayer.open(Media(audioFile), play: false);
    }
    if (videoFile != null) {
      debugPrint('[SyncCal] videoFile=$videoFile');
      await _videoPlayer.open(Media(videoFile), play: false);
    }
    _applyChannelSeparation();
  }

  @override
  void dispose() {
    _offsetFocus.removeListener(_onOffsetFocusChange);
    _offsetFocus.dispose();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _audioErrorSub?.cancel();
    _videoErrorSub?.cancel();
    playerService.disposePlayer(_audioPlayer);
    playerService.disposePlayer(_videoPlayer);
    _offsetController.dispose();
    super.dispose();
  }

  String? _findFile(Set<String> extensions) {
    final dir = Directory(widget.metadata.levelPath);
    for (final f in dir.listSync()) {
      if (f is File) {
        final ext = p.extension(f.path).toLowerCase();
        if (extensions.contains(ext)) return f.path;
      }
    }
    return null;
  }

  Future<void> _applyChannelSeparation() async {
    final nativeAudio = _audioPlayer.platform as NativePlayer;
    final nativeVideo = _videoPlayer.platform as NativePlayer;

    await nativeAudio.setProperty('af', _kLeftFilter);
    await nativeVideo.setProperty('af', _kRightFilter);

    await Future<void>.delayed(const Duration(milliseconds: 100));

    final audioAf = await nativeAudio.getProperty('af');
    final videoAf = await nativeVideo.getProperty('af');
    debugPrint('[SyncCal] audio af="$audioAf"');
    debugPrint('[SyncCal] video af="$videoAf"');

    if (audioAf.isEmpty && videoAf.isEmpty) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _channelSepActive = false;
          _channelSepFailed = true;
          _channelSepStatus =
              l10n?.sync_filter_unavailable ?? 'Filter unavailable';
        });
      }
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _channelSepActive = true;
          _channelSepStatus = l10n?.sync_channel_sep_active ?? 'L=Song R=Video';
        });
      }
    }
  }

  Future<void> _resetFilters() async {
    try {
      final nativeAudio = _audioPlayer.platform as NativePlayer;
      final nativeVideo = _videoPlayer.platform as NativePlayer;
      await nativeAudio.setProperty('af', '');
      await nativeVideo.setProperty('af', '');
    } catch (e) {
      debugPrint('[SyncCal] resetFilters error: $e');
    }
  }

  Future<void> _toggleChannelSep() async {
    if (_channelSepFailed) return;
    if (_channelSepActive) {
      await _resetFilters();
      if (mounted) {
        setState(() {
          _channelSepActive = false;
          _channelSepStatus = '';
        });
      }
    } else {
      await _applyChannelSeparation();
    }
  }

  void _applyOffsetToCurrentPosition() {
    final audioMs = _audioPlayer.state.position.inMilliseconds;
    final targetVideoMs = audioMs + _offsetMs;
    _videoPlayer.seek(Duration(milliseconds: targetVideoMs.clamp(0, _videoDuration.inMilliseconds)));
  }

  void _playBoth() {
    if (_offsetMs >= 0) {
      _audioPlayer.seek(Duration.zero);
      _videoPlayer.seek(Duration(milliseconds: _offsetMs));
    } else {
      _audioPlayer.seek(Duration(milliseconds: -_offsetMs));
      _videoPlayer.seek(Duration.zero);
    }
    _audioPlayer.play();
    _videoPlayer.play();
  }

  void _pauseBoth() {
    _audioPlayer.pause();
    _videoPlayer.pause();
  }

  void _resetBoth() {
    _audioPlayer.pause();
    _videoPlayer.pause();
    _audioPlayer.seek(Duration.zero);
    _videoPlayer.seek(Duration.zero);
  }

  Future<void> _saveOffset() async {
    final configPath =
        p.join(widget.metadata.levelPath, 'cinema-video.json');
    final file = File(configPath);
    Map<String, dynamic> config = {};
    if (await file.exists()) {
      try {
        config = json.decode(await file.readAsString())
            as Map<String, dynamic>;
      } catch (_) {}
    }
    config['offset'] = _offsetMs;
    await AtomicFileService().writeString(configPath, json.encode(config));
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.config_saved ?? 'Config saved')),
      );
    }
  }

  Widget _buildChannelToggle() {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.headphones, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          l10n?.sync_channel_separation ?? 'Channel separation',
          style: TextStyle(
            fontSize: 12,
            color: _channelSepFailed
                ? AppColors.textSecondary.withValues(alpha: 0.5)
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          height: 24,
          child: Switch(
            value: _channelSepActive,
            onChanged: _channelSepFailed ? null : (_) => _toggleChannelSep(),
            activeThumbColor: AppColors.brandPurple,
          ),
        ),
        if (_channelSepStatus.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            _channelSepStatus,
            style: TextStyle(
              fontSize: 11,
              color: _channelSepFailed
                  ? Colors.red.shade300
                  : AppColors.brandPurple,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progressFraction = _videoDuration.inMilliseconds > 0
        ? (_videoPosition.inMilliseconds / _videoDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Video(
              controller: _videoController,
              controls: NoVideoControls,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              _formatDuration(_videoPosition),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: AppColors.brandPurple,
                  inactiveTrackColor:
                      AppColors.textSecondary.withValues(alpha: 0.2),
                  thumbColor: AppColors.brandPurple,
                ),
                child: Slider(
                  value: progressFraction,
                  onChanged: (v) {
                    final videoMs =
                        (v * _videoDuration.inMilliseconds).toInt();
                    final audioMs = (videoMs - _offsetMs).clamp(0, 999999999);
                    _videoPlayer.seek(Duration(milliseconds: videoMs));
                    _audioPlayer.seek(Duration(milliseconds: audioMs));
                  },
                ),
              ),
            ),
            Text(
              _formatDuration(_videoDuration),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _playing ? Icons.pause : Icons.play_arrow,
                color: AppColors.brandPurple,
              ),
              onPressed: _playing ? _pauseBoth : _playBoth,
            ),
            IconButton(
              icon:
                  const Icon(Icons.replay, color: AppColors.textSecondary),
              onPressed: _resetBoth,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildChannelToggle(),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${l10n?.config_offset ?? 'Offset (ms)'}: $_offsetMs',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        Slider(
          value: _offsetMs.toDouble().clamp(-5000, 5000),
          min: -5000,
          max: 5000,
          divisions: 200,
          label: '$_offsetMs ms',
          activeColor: AppColors.brandPurple,
          onChanged: (v) {
            setState(() {
              _offsetMs = v.toInt();
              _offsetController.text = _offsetMs.toString();
            });
          },
          onChangeEnd: (_) => _applyOffsetToCurrentPosition(),
        ),
        Center(
          child: SizedBox(
            width: 100,
            child: TextField(
              controller: _offsetController,
              focusNode: _offsetFocus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration:
                  const InputDecoration(suffixText: 'ms', isDense: true),
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null) {
                  setState(() => _offsetMs = parsed);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: ElevatedButton.icon(
            onPressed: _saveOffset,
            icon: const Icon(Icons.save),
            label: Text(l10n?.config_save ?? 'Save'),
          ),
        ),
      ],
    );
  }
}
