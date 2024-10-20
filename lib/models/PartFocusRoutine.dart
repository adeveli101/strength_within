import 'dart:ui';
import '../utils/routine_helpers.dart';

enum SetType { regular, drop, superSet, tri, giant, normal }

class Parts {
  final int id;
  final String name;
  final int bodyPartId; // BodyParts tablosuna referans
  final SetType setType;
  final String additionalNotes;

  const Parts({
    required this.id,
    required this.name,
    required this.bodyPartId,
    required this.setType,
    this.additionalNotes = '',
  });

  String get setTypeString => setTypeToStringConverter(setType);
  Color get setTypeColor => setTypeToColorConverter(setType);
  int get exerciseCount => setTypeToExerciseCountConverter(setType);

  factory Parts.fromMap(Map<String, dynamic> map) {
    return Parts(
      id: map['Id'] as int,
      name: map['Name'] as String,
      bodyPartId: map['BodyPartId'] as int,
      setType: SetType.values[map['SetType'] as int],
      additionalNotes: map['AdditionalNotes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Name': name,
      'BodyPartId': bodyPartId,
      'SetType': setType.index,
      'AdditionalNotes': additionalNotes,
    };
  }

  Parts copyWith({
    int? id,
    String? name,
    int? bodyPartId,
    SetType? setType,
    String? additionalNotes,
  }) {
    return Parts(
      id: id ?? this.id,
      name: name ?? this.name,
      bodyPartId: bodyPartId ?? this.bodyPartId,
      setType: setType ?? this.setType,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }

  @override
  String toString() => 'Part(id: $id, name: $name, bodyPartId: $bodyPartId, setType: $setTypeString)';
}
