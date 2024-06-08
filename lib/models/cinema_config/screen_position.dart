import 'dart:convert';

class ScreenPosition {
  double? x;
  double? y;
  double? z;

  ScreenPosition({this.x, this.y, this.z});

  factory ScreenPosition.fromMap(Map<String, dynamic> data) {
    return ScreenPosition(
      x: (data['x'] as num?)?.toDouble(),
      y: (data['y'] as num?)?.toDouble(),
      z: (data['z'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'x': x,
        'y': y,
        'z': z,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [ScreenPosition].
  factory ScreenPosition.fromJson(String data) {
    return ScreenPosition.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [ScreenPosition] to a JSON string.
  String toJson() => json.encode(toMap());
}
