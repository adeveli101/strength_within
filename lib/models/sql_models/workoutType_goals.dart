// models/workout_type_goals.dart
class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult({
    required this.isValid,
    this.message = '',
  });
}
mixin WorkoutTypeGoalValidation {
  static const int MIN_PERCENTAGE = 0;
  static const int MAX_PERCENTAGE = 100;

  static ValidationResult validateWorkoutTypeGoal({
    required int workoutTypeId,
    required int goalId,
    required int recommendedPercentage,
  }) {
    if (workoutTypeId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz antrenman tipi',
      );
    }

    if (goalId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz hedef',
      );
    }

    if (recommendedPercentage < MIN_PERCENTAGE || recommendedPercentage > MAX_PERCENTAGE) {
      return ValidationResult(
        isValid: false,
        message: 'Yüzde değeri $MIN_PERCENTAGE-$MAX_PERCENTAGE arasında olmalıdır',
      );
    }

    return ValidationResult(isValid: true);
  }
}


class WorkoutTypeGoals {
  final int id;
  final int workoutTypeId;
  final int goalId;
  final int recommendedPercentage;

  WorkoutTypeGoals({
    required this.id,
    required this.workoutTypeId,
    required this.goalId,
    this.recommendedPercentage = 100,
  });

  factory WorkoutTypeGoals.fromMap(Map<String, dynamic> map) {
    return WorkoutTypeGoals(
      id: map['id'] as int,
      workoutTypeId: map['workoutTypeId'] as int,
      goalId: map['goalId'] as int,
      recommendedPercentage: map['recommendedPercentage'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutTypeId': workoutTypeId,
      'goalId': goalId,
      'recommendedPercentage': recommendedPercentage,
    };
  }

  WorkoutTypeGoals copyWith({
    int? id,
    int? workoutTypeId,
    int? goalId,
    int? recommendedPercentage,
  }) {
    return WorkoutTypeGoals(
      id: id ?? this.id,
      workoutTypeId: workoutTypeId ?? this.workoutTypeId,
      goalId: goalId ?? this.goalId,
      recommendedPercentage: recommendedPercentage ?? this.recommendedPercentage,
    );
  }

  @override
  String toString() {
    return 'WorkoutTypeGoals(id: $id, workoutTypeId: $workoutTypeId, goalId: $goalId, recommendedPercentage: $recommendedPercentage)';
  }
}
