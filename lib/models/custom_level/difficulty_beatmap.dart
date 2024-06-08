import 'dart:convert';

class DifficultyBeatmap {
  String? difficulty;
  int? difficultyRank;
  String? beatmapFilename;
  double? noteJumpMovementSpeed;
  double? noteJumpStartBeatOffset;

  DifficultyBeatmap({
    this.difficulty,
    this.difficultyRank,
    this.beatmapFilename,
    this.noteJumpMovementSpeed,
    this.noteJumpStartBeatOffset,
  });

  factory DifficultyBeatmap.fromMap(Map<String, dynamic> data) {
    return DifficultyBeatmap(
      difficulty: data['_difficulty'] as String?,
      difficultyRank: data['_difficultyRank'] as int?,
      beatmapFilename: data['_beatmapFilename'] as String?,
      noteJumpMovementSpeed:
          (data['_noteJumpMovementSpeed'] as num?)?.toDouble(),
      noteJumpStartBeatOffset:
          (data['_noteJumpStartBeatOffset'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        '_difficulty': difficulty,
        '_difficultyRank': difficultyRank,
        '_beatmapFilename': beatmapFilename,
        '_noteJumpMovementSpeed': noteJumpMovementSpeed,
        '_noteJumpStartBeatOffset': noteJumpStartBeatOffset,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [DifficultyBeatmap].
  factory DifficultyBeatmap.fromJson(String data) {
    return DifficultyBeatmap.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [DifficultyBeatmap] to a JSON string.
  String toJson() => json.encode(toMap());
}
