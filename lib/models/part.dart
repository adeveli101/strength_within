
enum TargetedBodyPart { abs, arm, back, chest, leg, shoulder, fullBody, tricep, bicep }
enum SetType { regular, drop, super_, tri, giant, normal }

class Part {
  int id;
  String name;
  TargetedBodyPart targetedBodyPart;
  SetType setType;
  List<int> exerciseIds;
  String additionalNotes;

  Part({
    required this.id,
    required this.name,
    required this.targetedBodyPart,
    required this.setType,
    required this.exerciseIds,
    this.additionalNotes = '',
  });

  factory Part.fromMap(Map<String, dynamic> map) {
    return Part(
      id: map['id'] as int,
      name: map['partName'] as String,
      targetedBodyPart: _intToTargetedBodyPartConverter(map['bodyPart'] as int),
      setType: _intToSetTypeConverter(map['setType'] as int),
      exerciseIds: List<int>.from(map['exerciseIds'] as List),
      additionalNotes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partName': name,
      'bodyPart': _targetedBodyPartToIntConverter(targetedBodyPart),
      'setType': _setTypeToIntConverter(setType),
      'exerciseIds': exerciseIds,
      'notes': additionalNotes,
    };
  }

  Part copyWith({
    int? id,
    String? name,
    TargetedBodyPart? targetedBodyPart,
    SetType? setType,
    List<int>? exerciseIds,
    String? additionalNotes,
  }) {
    return Part(
      id: id ?? this.id,
      name: name ?? this.name,
      targetedBodyPart: targetedBodyPart ?? this.targetedBodyPart,
      setType: setType ?? this.setType,
      exerciseIds: exerciseIds ?? List.from(this.exerciseIds),
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }

  static int _setTypeToIntConverter(SetType setType) {
    return setType.index;
  }

  static SetType _intToSetTypeConverter(int i) {
    return SetType.values[i];
  }

  static int _targetedBodyPartToIntConverter(TargetedBodyPart tb) {
    return tb.index;
  }

  static TargetedBodyPart _intToTargetedBodyPartConverter(int i) {
    return TargetedBodyPart.values[i];
  }

  @override
  String toString() => 'Part(id: $id, name: $name, exercises: ${exerciseIds.length})';
}
