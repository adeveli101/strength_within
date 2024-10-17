import 'WorkoutType.dart';
import 'BodyPart.dart';

class Exercises {
  final int id;
  final String name;
  final double defaultWeight;
  final int defaultSets;
  final int defaultReps;
  final WorkoutTypes workoutType;
  final MainTargetedBodyPart mainTargetedBodyPart;

  Exercises({
    required this.id,
    required this.name,
    required this.defaultWeight,
    required this.defaultSets,
    required this.defaultReps,
    required this.workoutType,
    required this.mainTargetedBodyPart,
  });

  factory Exercises.fromMap(Map<String, dynamic> map) {
    return Exercises(
      id: map['Id'] as int,
      name: map['Name'] as String,
      defaultWeight: map['DefaultWeight'] as double,
      defaultSets: map['DefaultSets'] as int,
      defaultReps: map['DefaultReps'] as int,
      workoutType: WorkoutTypes.fromMap(map['WorkoutType'] as Map<String, dynamic>),
      mainTargetedBodyPart: MainTargetedBodyPart.values[map['MainTargetedBodyPart'] as int],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Name': name,
      'DefaultWeight': defaultWeight,
      'DefaultSets': defaultSets,
      'DefaultReps': defaultReps,
      'WorkoutType': workoutType.toMap(),
      'MainTargetedBodyPart': mainTargetedBodyPart.index,
    };
  }
  Exercises copyWith({
    int? id,
    String? name,
    double? defaultWeight,
    int? defaultSets,
    int? defaultReps,
    WorkoutTypes? workoutType,
    MainTargetedBodyPart? mainTargetedBodyPart,
  }) {
    return Exercises(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultWeight: defaultWeight ?? this.defaultWeight,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      workoutType: workoutType ?? this.workoutType,
      mainTargetedBodyPart: mainTargetedBodyPart ?? this.mainTargetedBodyPart,
    );
  }

  @override
  String toString() => 'Exercise(id: $id, name: $name, workoutType: ${workoutType.name}, mainTargetedBodyPart: ${mainTargetedBodyPart.name})';
}
