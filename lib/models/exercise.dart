import 'dart:convert';

enum WorkoutType { cardio, weight }

class Exercise {
  String name;
  double weight;
  int sets;
  String reps;
  WorkoutType workoutType;
  Map<String, dynamic> exHistory;

  Exercise({
    required this.name,
    required this.weight,
    required this.sets,
    required this.reps,
    this.workoutType = WorkoutType.weight,
    Map<String, dynamic>? exHistory,
  }) : exHistory = exHistory ?? {};

  Exercise.fromMap(Map<String, dynamic> map)
      : name = map["name"] ?? '',
        weight = double.tryParse(map["weight"]?.toString() ?? '0') ?? 0,
        sets = int.tryParse(map["sets"]?.toString() ?? '0') ?? 0,
        reps = map["reps"] ?? '',
        workoutType = intToWorkoutTypeConverter(map['workoutType'] ?? 1),
        exHistory = jsonDecode(map["history"] ?? '{}');

  Map<String, dynamic> toMap() => {
    'name': name,
    'weight': weight.toStringAsFixed(1),
    'sets': sets,
    'reps': reps,
    'workoutType': workoutTypeToIntConverter(workoutType),
    'history': jsonEncode(exHistory),
  };

  Exercise.copyFromExercise(Exercise ex)
      : name = ex.name,
        weight = ex.weight,
        sets = ex.sets,
        reps = ex.reps,
        workoutType = ex.workoutType,
        exHistory = Map.from(ex.exHistory); // Shallow copy

  Exercise.copyFromExerciseWithoutHistory(Exercise ex)
      : name = ex.name,
        weight = ex.weight,
        sets = ex.sets,
        reps = ex.reps,
        workoutType = ex.workoutType,
        exHistory = {}; // Empty history

  @override
  String toString() {
    return "Instance of Exercise: name: $name";
  }
}

int workoutTypeToIntConverter(WorkoutType wt) {
  switch (wt) {
    case WorkoutType.cardio:
      return 0;
    case WorkoutType.weight:
      return 1;
    default:
      throw Exception('Invalid Workout Type');
  }
}

WorkoutType intToWorkoutTypeConverter(int i) {
  switch (i) {
    case 0:
      return WorkoutType.cardio;
    case 1:
      return WorkoutType.weight;
    default:
      throw Exception('Invalid integer for Workout Type');
  }
}