import 'dart:convert';

class ColorCorrection {
  double? gamma;
  double? saturation;

  ColorCorrection({this.gamma, this.saturation});

  factory ColorCorrection.fromMap(Map<String, dynamic> data) {
    return ColorCorrection(
      gamma: (data['gamma'] as num?)?.toDouble(),
      saturation: (data['saturation'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'gamma': gamma,
        'saturation': saturation,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [ColorCorrection].
  factory ColorCorrection.fromJson(String data) {
    return ColorCorrection.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [ColorCorrection] to a JSON string.
  String toJson() => json.encode(toMap());
}
