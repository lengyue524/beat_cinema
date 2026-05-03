import 'dart:convert';

import 'difficulty_beatmap_set.dart';

class CustomLevel {
  String? version;
  String? songName;
  String? songSubName;
  String? songAuthorName;
  String? levelAuthorName;
  double? beatsPerMinute;
  double? songTimeOffset;
  double? shuffle;
  double? shufflePeriod;
  double? previewStartTime;
  double? previewDuration;
  String? songFilename;
  String? coverImageFilename;
  String? environmentName;
  String? allDirectionsEnvironmentName;
  List<DifficultyBeatmapSet>? difficultyBeatmapSets;

  CustomLevel({
    this.version,
    this.songName,
    this.songSubName,
    this.songAuthorName,
    this.levelAuthorName,
    this.beatsPerMinute,
    this.songTimeOffset,
    this.shuffle,
    this.shufflePeriod,
    this.previewStartTime,
    this.previewDuration,
    this.songFilename,
    this.coverImageFilename,
    this.environmentName,
    this.allDirectionsEnvironmentName,
    this.difficultyBeatmapSets,
  });

  factory CustomLevel.fromMap(Map<String, dynamic> data) {
    final songNode = data['song'];
    final song = songNode is Map<String, dynamic> ? songNode : null;
    final sets = _resolveDifficultyBeatmapSets(data);
    return CustomLevel(
      version: _stringOf(data['_version']) ?? _stringOf(data['version']),
      songName: _stringOf(data['_songName']) ?? _stringOf(song?['title']),
      songSubName:
          _stringOf(data['_songSubName']) ?? _stringOf(song?['subTitle']),
      songAuthorName:
          _stringOf(data['_songAuthorName']) ?? _stringOf(song?['author']),
      levelAuthorName: _stringOf(data['_levelAuthorName']) ??
          _stringOf(data['levelAuthorName']),
      beatsPerMinute: _doubleOf(data['_beatsPerMinute']) ??
          _doubleOf(data['beatsPerMinute']),
      songTimeOffset: _doubleOf(data['_songTimeOffset']) ??
          _doubleOf(data['songTimeOffset']),
      shuffle: _doubleOf(data['_shuffle']) ?? _doubleOf(data['shuffle']),
      shufflePeriod:
          _doubleOf(data['_shufflePeriod']) ?? _doubleOf(data['shufflePeriod']),
      previewStartTime: _doubleOf(data['_previewStartTime']) ??
          _doubleOf(data['previewStartTime']),
      previewDuration: _doubleOf(data['_previewDuration']) ??
          _doubleOf(data['previewDuration']),
      songFilename: _stringOf(data['_songFilename']) ??
          _stringOf(data['songFilename']) ??
          _stringOf(data['audio']),
      coverImageFilename: _stringOf(data['_coverImageFilename']) ??
          _stringOf(data['coverImageFilename']),
      environmentName: _stringOf(data['_environmentName']) ??
          _stringOf(data['environmentName']),
      allDirectionsEnvironmentName:
          _stringOf(data['_allDirectionsEnvironmentName']) ??
              _stringOf(data['allDirectionsEnvironmentName']),
      difficultyBeatmapSets: sets,
    );
  }

  static List<DifficultyBeatmapSet>? _resolveDifficultyBeatmapSets(
    Map<String, dynamic> data,
  ) {
    final legacySets = data['_difficultyBeatmapSets'] as List<dynamic>?;
    if (legacySets != null) {
      return legacySets
          .whereType<Map<String, dynamic>>()
          .map(DifficultyBeatmapSet.fromMap)
          .toList(growable: false);
    }

    final v4Beatmaps = data['difficultyBeatmaps'] as List<dynamic>?;
    if (v4Beatmaps == null || v4Beatmaps.isEmpty) {
      return null;
    }
    return [
      DifficultyBeatmapSet.fromMap(<String, dynamic>{
        '_beatmapCharacteristicName': 'Standard',
        '_difficultyBeatmaps': v4Beatmaps,
      }),
    ];
  }

  static String? _stringOf(dynamic value) {
    if (value is String) return value;
    return null;
  }

  static double? _doubleOf(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  Map<String, dynamic> toMap() => {
        '_version': version,
        '_songName': songName,
        '_songSubName': songSubName,
        '_songAuthorName': songAuthorName,
        '_levelAuthorName': levelAuthorName,
        '_beatsPerMinute': beatsPerMinute,
        '_songTimeOffset': songTimeOffset,
        '_shuffle': shuffle,
        '_shufflePeriod': shufflePeriod,
        '_previewStartTime': previewStartTime,
        '_previewDuration': previewDuration,
        '_songFilename': songFilename,
        '_coverImageFilename': coverImageFilename,
        '_environmentName': environmentName,
        '_allDirectionsEnvironmentName': allDirectionsEnvironmentName,
        '_difficultyBeatmapSets':
            difficultyBeatmapSets?.map((e) => e.toMap()).toList(),
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [CustomLevel].
  factory CustomLevel.fromJson(String data) {
    return CustomLevel.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [CustomLevel] to a JSON string.
  String toJson() => json.encode(toMap());
}
