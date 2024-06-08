import 'dart:convert';

class Position {
  double? x;
  double? y;
  double? z;

  Position({this.x, this.y, this.z});

  factory Position.fromMap(Map<String, dynamic> data) => Position(
        x: (data['x'] as num?)?.toDouble(),
        y: (data['y'] as num?)?.toDouble(),
        z: (data['z'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'x': x,
        'y': y,
        'z': z,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Position].
  factory Position.fromJson(String data) {
    return Position.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Position] to a JSON string.
  String toJson() => json.encode(toMap());
}
