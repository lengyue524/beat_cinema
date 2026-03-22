import 'package:beat_cinema/Modules/CustomLevels/level_info.dart';
import 'package:beat_cinema/models/custom_level/custom_level.dart';
import 'package:beat_cinema/models/cinema_config/cinema_config.dart';

enum ParseStatus { success, partial, failed }

enum VideoConfigStatus {
  none,
  configured,
  configuredMissingFile,
  downloading,
  error
}

class LevelMetadata {
  final String levelPath;
  final String songName;
  final String songSubName;
  final String songAuthorName;
  final String levelAuthorName;
  final double bpm;
  final List<String> difficulties;
  final String? coverImageFilename;
  final ParseStatus parseStatus;
  final DateTime lastModified;
  final CinemaConfig? cinemaConfig;
  final CustomLevel? rawLevel;
  final String mapHash;

  double downloadProgress;
  VideoConfigStatus _videoStatus;

  VideoConfigStatus get videoStatus {
    if (downloadProgress > 0 && downloadProgress < 1.0) {
      return VideoConfigStatus.downloading;
    }
    return _videoStatus;
  }

  LevelMetadata({
    required this.levelPath,
    this.songName = '',
    this.songSubName = '',
    this.songAuthorName = '',
    this.levelAuthorName = '',
    this.bpm = 0,
    this.difficulties = const [],
    this.coverImageFilename,
    this.parseStatus = ParseStatus.success,
    required this.lastModified,
    this.cinemaConfig,
    this.rawLevel,
    this.mapHash = '',
    this.downloadProgress = 0,
    VideoConfigStatus videoStatus = VideoConfigStatus.none,
  }) : _videoStatus = videoStatus;

  LevelMetadata copyWith({
    String? levelPath,
    String? songName,
    String? songSubName,
    String? songAuthorName,
    String? levelAuthorName,
    double? bpm,
    List<String>? difficulties,
    String? coverImageFilename,
    ParseStatus? parseStatus,
    DateTime? lastModified,
    CinemaConfig? cinemaConfig,
    CustomLevel? rawLevel,
    String? mapHash,
    double? downloadProgress,
    VideoConfigStatus? videoStatus,
  }) {
    return LevelMetadata(
      levelPath: levelPath ?? this.levelPath,
      songName: songName ?? this.songName,
      songSubName: songSubName ?? this.songSubName,
      songAuthorName: songAuthorName ?? this.songAuthorName,
      levelAuthorName: levelAuthorName ?? this.levelAuthorName,
      bpm: bpm ?? this.bpm,
      difficulties: difficulties ?? this.difficulties,
      coverImageFilename: coverImageFilename ?? this.coverImageFilename,
      parseStatus: parseStatus ?? this.parseStatus,
      lastModified: lastModified ?? this.lastModified,
      cinemaConfig: cinemaConfig ?? this.cinemaConfig,
      rawLevel: rawLevel ?? this.rawLevel,
      mapHash: mapHash ?? this.mapHash,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      videoStatus: videoStatus ?? _videoStatus,
    );
  }

  LevelInfo toLevelInfo() {
    return LevelInfo(
      levelPath,
      rawLevel ?? CustomLevel(songName: songName),
      cinemaConfig,
    );
  }

  Map<String, dynamic> toMap() => {
        'levelPath': levelPath,
        'songName': songName,
        'songSubName': songSubName,
        'songAuthorName': songAuthorName,
        'levelAuthorName': levelAuthorName,
        'bpm': bpm,
        'difficulties': difficulties,
        'coverImageFilename': coverImageFilename,
        'parseStatus': parseStatus.index,
        'lastModified': lastModified.millisecondsSinceEpoch,
        'cinemaConfig': cinemaConfig?.toMap(),
        'mapHash': mapHash,
      };

  factory LevelMetadata.fromMap(Map<String, dynamic> map) {
    return LevelMetadata(
      levelPath: map['levelPath'] as String? ?? '',
      songName: map['songName'] as String? ?? '',
      songSubName: map['songSubName'] as String? ?? '',
      songAuthorName: map['songAuthorName'] as String? ?? '',
      levelAuthorName: map['levelAuthorName'] as String? ?? '',
      bpm: (map['bpm'] as num?)?.toDouble() ?? 0,
      difficulties: (map['difficulties'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      coverImageFilename: map['coverImageFilename'] as String?,
      parseStatus: ParseStatus.values[map['parseStatus'] as int? ?? 0],
      lastModified:
          DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int? ?? 0),
      cinemaConfig: map['cinemaConfig'] != null
          ? CinemaConfig.fromMap(map['cinemaConfig'] as Map<String, dynamic>)
          : null,
      mapHash: map['mapHash'] as String? ?? '',
      videoStatus: _resolveVideoStatusFromMap(map),
    );
  }

  static VideoConfigStatus _resolveVideoStatusFromMap(
      Map<String, dynamic> map) {
    final rawConfig = map['cinemaConfig'];
    if (rawConfig is! Map<String, dynamic>) {
      return VideoConfigStatus.none;
    }
    final config = CinemaConfig.fromMap(rawConfig);
    final hasVideoFile = (config.videoFile ?? '').trim().isNotEmpty;
    final hasVideoUrl = (config.videoUrl ?? '').trim().isNotEmpty;
    final hasVideoId = (config.videoId ?? '').trim().isNotEmpty;
    if (hasVideoFile) {
      return VideoConfigStatus.configured;
    }
    if (hasVideoUrl || hasVideoId) {
      return VideoConfigStatus.configuredMissingFile;
    }
    return VideoConfigStatus.error;
  }
}
