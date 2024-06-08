import 'dart:convert';

class Scale {
  double? x;
  double? y;
  double? z;

  Scale({this.x, this.y, this.z});

  factory Scale.fromMap(Map<String, dynamic> data) => Scale(
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
  /// Parses the string and returns the resulting Json object as [Scale].
  factory Scale.fromJson(String data) {
    return Scale.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Scale] to a JSON string.
  String toJson() => json.encode(toMap());
}
