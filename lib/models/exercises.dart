
class Exercises {
  final int id;
  final String name;
  final double defaultWeight;
  final int defaultSets;
  final int defaultReps;
  final int workoutTypeId;
  final int mainTargetedBodyPartId;
  final String description;

  const Exercises({
    required this.id,
    required this.name,
    required this.defaultWeight,
    required this.defaultSets,
    required this.defaultReps,
    required this.workoutTypeId,
    required this.mainTargetedBodyPartId,
    required this.description,
  });

  factory Exercises.fromMap(Map<String, dynamic> map) {
    print('Exercise fromMap çağrıldı: $map'); // Hata ayıklama için
    return Exercises(
      id: map['Id'] as int? ?? 0,
      name: map['Name'] as String? ?? '',
      defaultWeight: (map['DefaultWeight'] as num?)?.toDouble() ?? 0.0,
      defaultSets: map['DefaultSets'] as int? ?? 0,
      defaultReps: map['DefaultReps'] as int? ?? 0,
      workoutTypeId: map['WorkoutTypeId'] as int? ?? 0,
      mainTargetedBodyPartId: map['MainTargetedBodyPartId'] as int? ?? 0, description: map['desciption'] as String,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Name': name,
      'DefaultWeight': defaultWeight,
      'DefaultSets': defaultSets,
      'DefaultReps': defaultReps,
      'WorkoutTypeId': workoutTypeId,
      'MainTargetedBodyPartId': mainTargetedBodyPartId,
      'description': description,
    };
  }

  Exercises copyWith({
    int? id,
    String? name,
    double? defaultWeight,
    int? defaultSets,
    int? defaultReps,
    int? workoutTypeId,
    int? mainTargetedBodyPartId,
    String? description,
  }) {
    return Exercises(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultWeight: defaultWeight ?? this.defaultWeight,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      workoutTypeId: workoutTypeId ?? this.workoutTypeId,
      mainTargetedBodyPartId: mainTargetedBodyPartId ?? this.mainTargetedBodyPartId,
      description: description ?? this.description,
    );
  }

  @override
  String toString() => 'Exercise(id: $id, name: $name, workoutTypeId: $workoutTypeId, mainTargetedBodyPartId: $mainTargetedBodyPartId)';
}
