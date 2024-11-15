import '../utils/routine_helpers.dart';

enum MainTargetedBodyPart { abs, arm, back, chest, leg, shoulder, core }

class BodyParts {
  final int id;
  final String name;
  final MainTargetedBodyPart mainTargetedBodyPart;

  const BodyParts({
    required this.id,
    required this.name,
    required this.mainTargetedBodyPart,
  });

  String get mainTargetedBodyPartString => mainTargetedBodyPartToStringConverter(mainTargetedBodyPart);

  factory BodyParts.fromMap(Map<String, dynamic> map) {
    print('BodyPart fromMap çağrıldı: $map'); // Hata ayıklama için
    return BodyParts(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      mainTargetedBodyPart: MainTargetedBodyPart.values[map['mainTargetedBodyPart'] as int? ?? 0],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mainTargetedBodyPart': mainTargetedBodyPart.index,
    };
  }

  BodyParts copyWith({
    int? id,
    String? name,
    MainTargetedBodyPart? mainTargetedBodyPart,
  }) {
    return BodyParts(
      id: id ?? this.id,
      name: name ?? this.name,
      mainTargetedBodyPart: mainTargetedBodyPart ?? this.mainTargetedBodyPart,
    );
  }

  @override
  String toString() => 'BodyPart(id: $id, name: $name, mainTargetedBodyPart: $mainTargetedBodyPartString)';
}