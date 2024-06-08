// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:beat_cinema/models/cinema_config/cinema_config.dart';
import 'package:beat_cinema/models/custom_level/custom_level.dart';

class LevelInfo {
  String levelPath;
  CustomLevel customLevel;
  CinemaConfig? cinemaConfig;
  LevelInfo(
    this.levelPath,
    this.customLevel,
    this.cinemaConfig,
  );

  LevelInfo copyWith({
    String? levelPath,
    CustomLevel? customLevel,
    CinemaConfig? cinemaConfig,
  }) {
    return LevelInfo(
      levelPath ?? this.levelPath,
      customLevel ?? this.customLevel,
      cinemaConfig ?? this.cinemaConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'levelPath': levelPath,
      'customLevel': customLevel.toMap(),
      'cinemaConfig': cinemaConfig?.toMap(),
    };
  }

  factory LevelInfo.fromMap(Map<String, dynamic> map) {
    return LevelInfo(
      map['levelPath'] as String,
      CustomLevel.fromMap(map['customLevel'] as Map<String, dynamic>),
      map['cinemaConfig'] != null
          ? CinemaConfig.fromMap(map['cinemaConfig'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory LevelInfo.fromJson(String source) =>
      LevelInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'LevelInfo(levelPath: $levelPath, customLevel: $customLevel, cinemaConfig: $cinemaConfig)';

  @override
  bool operator ==(covariant LevelInfo other) {
    if (identical(this, other)) return true;

    return other.levelPath == levelPath &&
        other.customLevel == customLevel &&
        other.cinemaConfig == cinemaConfig;
  }

  @override
  int get hashCode =>
      levelPath.hashCode ^ customLevel.hashCode ^ cinemaConfig.hashCode;
}
