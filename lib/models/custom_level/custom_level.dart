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

  factory CustomLevel.fromMap(Map<String, dynamic> data) => CustomLevel(
        version: data['_version'] as String?,
        songName: data['_songName'] as String?,
        songSubName: data['_songSubName'] as String?,
        songAuthorName: data['_songAuthorName'] as String?,
        levelAuthorName: data['_levelAuthorName'] as String?,
        beatsPerMinute: (data['_beatsPerMinute'] as num?)?.toDouble(),
        songTimeOffset: (data['_songTimeOffset'] as num?)?.toDouble(),
        shuffle: (data['_shuffle'] as num?)?.toDouble(),
        shufflePeriod: (data['_shufflePeriod'] as num?)?.toDouble(),
        previewStartTime: (data['_previewStartTime'] as num?)?.toDouble(),
        previewDuration: (data['_previewDuration'] as num?)?.toDouble(),
        songFilename: data['_songFilename'] as String?,
        coverImageFilename: data['_coverImageFilename'] as String?,
        environmentName: data['_environmentName'] as String?,
        allDirectionsEnvironmentName:
            data['_allDirectionsEnvironmentName'] as String?,
        difficultyBeatmapSets: (data['_difficultyBeatmapSets']
                as List<dynamic>?)
            ?.map(
                (e) => DifficultyBeatmapSet.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

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
