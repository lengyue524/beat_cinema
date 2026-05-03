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
      difficulty:
          _stringOf(data['_difficulty']) ?? _stringOf(data['difficulty']),
      difficultyRank:
          _intOf(data['_difficultyRank']) ?? _intOf(data['difficultyRank']),
      beatmapFilename: _stringOf(data['_beatmapFilename']) ??
          _stringOf(data['beatmapFilename']) ??
          _stringOf(data['beatmapDataFilename']),
      noteJumpMovementSpeed: _doubleOf(data['_noteJumpMovementSpeed']) ??
          _doubleOf(data['noteJumpMovementSpeed']),
      noteJumpStartBeatOffset: _doubleOf(data['_noteJumpStartBeatOffset']) ??
          _doubleOf(data['noteJumpStartBeatOffset']),
    );
  }

  static String? _stringOf(dynamic value) => value is String ? value : null;

  static int? _intOf(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  static double? _doubleOf(dynamic value) =>
      value is num ? value.toDouble() : null;

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
