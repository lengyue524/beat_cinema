import 'dart:convert';

import 'position.dart';
import 'scale.dart';

class Environment {
  String? name;
  bool? active;
  Position? position;
  Scale? scale;

  Environment({this.name, this.active, this.position, this.scale});

  factory Environment.fromMap(Map<String, dynamic> data) => Environment(
        name: data['name'] as String?,
        active: data['active'] as bool?,
        position: data['position'] == null
            ? null
            : Position.fromMap(data['position'] as Map<String, dynamic>),
        scale: data['scale'] == null
            ? null
            : Scale.fromMap(data['scale'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'active': active,
        'position': position?.toMap(),
        'scale': scale?.toMap(),
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Environment].
  factory Environment.fromJson(String data) {
    return Environment.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Environment] to a JSON string.
  String toJson() => json.encode(toMap());
}
