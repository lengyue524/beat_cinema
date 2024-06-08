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
    return DifficultyBeatmapSet(
      beatmapCharacteristicName: data['_beatmapCharacteristicName'] as String?,
      difficultyBeatmaps: (data['_difficultyBeatmaps'] as List<dynamic>?)
          ?.map((e) => DifficultyBeatmap.fromMap(e as Map<String, dynamic>))
          .toList(),
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
