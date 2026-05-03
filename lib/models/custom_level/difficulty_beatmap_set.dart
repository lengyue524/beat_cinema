import 'dart:convert';

import 'difficulty_beatmap.dart';

class DifficultyBeatmapSet {
  String? beatmapCharacteristicName;
  List<DifficultyBeatmap>? difficultyBeatmaps;

  DifficultyBeatmapSet({
    this.beatmapCharacteristicName,
    this.difficultyBeatmaps,
  });

  factory DifficultyBeatmapSet.fromMap(Map<String, dynamic> data) {
    final beatmaps = (data['_difficultyBeatmaps'] ?? data['difficultyBeatmaps'])
        as List<dynamic>?;
    return DifficultyBeatmapSet(
      beatmapCharacteristicName: (data['_beatmapCharacteristicName'] ??
          data['beatmapCharacteristicName']) as String?,
      difficultyBeatmaps: beatmaps
          ?.whereType<Map<String, dynamic>>()
          .map(DifficultyBeatmap.fromMap)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toMap() => {
        '_beatmapCharacteristicName': beatmapCharacteristicName,
        '_difficultyBeatmaps':
            difficultyBeatmaps?.map((e) => e.toMap()).toList(),
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [DifficultyBeatmapSet].
  factory DifficultyBeatmapSet.fromJson(String data) {
    return DifficultyBeatmapSet.fromMap(
        json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [DifficultyBeatmapSet] to a JSON string.
  String toJson() => json.encode(toMap());
}
