
enum WorkoutType { cardio, weight }

class Exercise {
  final int id;
  final String name;
  final double? defaultWeight;
  late final int? defaultSets;
  late final String? defaultReps;  // Change this to nullable
  final WorkoutType workoutType;

  Exercise({
    required this.id,
    required this.name,
    this.defaultWeight,
    this.defaultSets,
    this.defaultReps,
    this.workoutType = WorkoutType.weight,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int,
      name: map['name'] as String,
      defaultWeight: (map['defaultWeight'] as num?)?.toDouble(),
      defaultSets: map['defaultSets'] as int?,
      defaultReps: map['defaultReps'] as String?,
      workoutType: WorkoutType.values[map['workoutType'] as int? ?? 0],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'defaultWeight': defaultWeight,
      'defaultSets': defaultSets,
      'defaultReps': defaultReps,
      'workoutType': workoutType.index,
    };
  }

  Exercise copyWith({
    int? id,
    String? name,
    double? defaultWeight,
    int? defaultSets,
    String? defaultReps,
    WorkoutType? workoutType,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultWeight: defaultWeight ?? this.defaultWeight,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      workoutType: workoutType ?? this.workoutType,
    );
  }

  @override
  String toString() => 'Exercise(id: $id, name: $name, defaultWeight: $defaultWeight, defaultSets: $defaultSets, defaultReps: $defaultReps)';
}
