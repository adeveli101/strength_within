import 'dart:ui';
import '../utils/routine_helpers.dart';
import 'BodyPart.dart';

enum SetType { regular, drop, superSet, tri, giant, normal }

class Part {
  final int id;
  final String name;
  final MainTargetedBodyPart mainTargetedBodyPart;
  final SetType setType;
  final List<int> exerciseIds;
  final String additionalNotes;
  final String mainTargetedBodyPartString;
  final String setTypeString;
  final Color setTypeColor;
  final int exerciseCount;

  Part({
    required this.id,
    required this.name,
    required this.mainTargetedBodyPart,
    required this.setType,
    required this.exerciseIds,
    this.additionalNotes = '',
  }) : mainTargetedBodyPartString = mainTargetedBodyPartToStringConverter(mainTargetedBodyPart),
        setTypeString = setTypeToStringConverter(setType),
        setTypeColor = setTypeToColorConverter(setType),
        exerciseCount = setTypeToExerciseCountConverter(setType);

  factory Part.fromMap(Map<String, dynamic> map) {
    return Part(
      id: map['Id'] as int,
      name: map['Name'] as String,
      mainTargetedBodyPart: MainTargetedBodyPart.values[map['MainTargetedBodyPart'] as int],
      setType: SetType.values[map['SetType'] as int],
      exerciseIds: (map['ExerciseIds'] as String).split(',').map((e) => int.parse(e)).toList(),
      additionalNotes: map['AdditionalNotes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Name': name,
      'MainTargetedBodyPart': mainTargetedBodyPart.index,
      'SetType': setType.index,
      'ExerciseIds': exerciseIds.join(','),
      'AdditionalNotes': additionalNotes,
    };
  }



  Part copyWith({
    int? id,
    String? name,
    MainTargetedBodyPart? mainTargetedBodyPart,
    SetType? setType,
    List<int>? exerciseIds,
    String? additionalNotes,
  }) {
    return Part(
      id: id ?? this.id,
      name: name ?? this.name,
      mainTargetedBodyPart: mainTargetedBodyPart ?? this.mainTargetedBodyPart,
      setType: setType ?? this.setType,
      exerciseIds: exerciseIds ?? List.from(this.exerciseIds),
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }




  @override
  String toString() => 'Part(id: $id, name: $name, mainTargetedBodyPart: $mainTargetedBodyPartString, setType: $setTypeString, exercises: ${exerciseIds.length})';
}
