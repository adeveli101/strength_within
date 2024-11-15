// lib/firebase_class/Feature.dart

import 'dart:convert';

class Feature {
  final int id;
  List<double> values;

  Feature({
    required this.id,
    required this.values,
  });

  Feature copyWith({
    int? id,
    List<double>? values,
  }) {
    return Feature(
      id: id ?? this.id,
      values: values ?? List<double>.from(this.values),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'values': values,
    };
  }

  factory Feature.fromMap(Map<String, dynamic> map) {
    return Feature(
      id: map['id'] as int,
      values: List<double>.from(map['values']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Feature.fromJson(String source) => Feature.fromMap(json.decode(source));

  @override
  String toString() => 'Feature(id: $id, values: $values)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Feature &&
        other.id == id &&
        listEquals(other.values, values);
  }

  @override
  int get hashCode => id.hashCode ^ values.hashCode;

  // AI modülü için eklenen metodlar
  void removeValueAtIndex(int index) {
    if (index >= 0 && index < values.length) {
      values.removeAt(index);
    }
  }

  static List<Feature> copyFeatures(List<Feature> features) {
    return features.map((feature) => Feature(
      id: feature.id,
      values: List<double>.from(feature.values),
    )).toList();
  }
}

// Yardımcı fonksiyon
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
