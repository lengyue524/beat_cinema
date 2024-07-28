import 'dart:convert';

import 'color_correction.dart';
import 'environment.dart';
import 'screen_position.dart';

class CinemaConfig {
  String? videoId;
  String? videoUrl;
  String? title;
  String? author;
  String? videoFile;
  int? duration;
  int? offset;
  int? formatVersion;
  bool? loop;
  ScreenPosition? screenPosition;
  bool? disableBigMirrorOverride;
  ColorCorrection? colorCorrection;
  List<Environment>? environment;

  CinemaConfig({
    this.videoId,
    this.videoUrl,
    this.title,
    this.author,
    this.videoFile,
    this.duration,
    this.offset,
    this.formatVersion,
    this.loop,
    this.screenPosition,
    this.disableBigMirrorOverride,
    this.colorCorrection,
    this.environment,
  });

  factory CinemaConfig.fromMap(Map<String, dynamic> data) => CinemaConfig(
        videoId: data['videoID'] as String?,
        videoUrl: data['videoUrl'] as String?,
        title: data['title'] as String?,
        author: data['author'] as String?,
        videoFile: data['videoFile'] as String?,
        duration: data['duration'] as int?,
        offset: data['offset'] as int?,
        formatVersion: data['formatVersion'] as int?,
        loop: data['loop'] as bool?,
        screenPosition: data['screenPosition'] == null
            ? null
            : ScreenPosition.fromMap(
                data['screenPosition'] as Map<String, dynamic>),
        disableBigMirrorOverride: data['disableBigMirrorOverride'] as bool?,
        colorCorrection: data['colorCorrection'] == null
            ? null
            : ColorCorrection.fromMap(
                data['colorCorrection'] as Map<String, dynamic>),
        environment: (data['environment'] as List<dynamic>?)
            ?.map((e) => Environment.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'videoID': videoId,
        'videoUrl': videoUrl,
        'title': title,
        'author': author,
        'videoFile': videoFile,
        'duration': duration,
        'offset': offset,
        'formatVersion': formatVersion,
        'loop': loop,
        'screenPosition': screenPosition?.toMap(),
        'disableBigMirrorOverride': disableBigMirrorOverride,
        'colorCorrection': colorCorrection?.toMap(),
        'environment': environment?.map((e) => e.toMap()).toList(),
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [CinemaConfig].
  factory CinemaConfig.fromJson(String data) {
    return CinemaConfig.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [CinemaConfig] to a JSON string.
  String toJson() => json.encode(toMap());
}
