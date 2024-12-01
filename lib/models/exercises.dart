mixin ExerciseValidation {
  static const int MIN_NAME_LENGTH = 1;
  static const int MAX_NAME_LENGTH = 100;
  static const double MIN_WEIGHT = 0.0;
  static const double MAX_WEIGHT = 500.0;
  static const int MIN_SETS = 1;
  static const int MAX_SETS = 10;
  static const int MIN_REPS = 1;
  static const int MAX_REPS = 100;

  static ValidationResult validateExercise({
    required String name,
    required double defaultWeight,
    required int defaultSets,
    required int defaultReps,
    required int workoutTypeId,
  }) {
    if (name.length < MIN_NAME_LENGTH || name.length > MAX_NAME_LENGTH) {
      return ValidationResult(
        isValid: false,
        message: 'İsim $MIN_NAME_LENGTH-$MAX_NAME_LENGTH karakter arasında olmalıdır',
      );
    }

    if (defaultWeight < MIN_WEIGHT || defaultWeight > MAX_WEIGHT) {
      return ValidationResult(
        isValid: false,
        message: 'Ağırlık $MIN_WEIGHT-$MAX_WEIGHT kg arasında olmalıdır',
      );
    }

    if (defaultSets < MIN_SETS || defaultSets > MAX_SETS) {
      return ValidationResult(
        isValid: false,
        message: 'Set sayısı $MIN_SETS-$MAX_SETS arasında olmalıdır',
      );
    }

    if (defaultReps < MIN_REPS || defaultReps > MAX_REPS) {
      return ValidationResult(
        isValid: false,
        message: 'Tekrar sayısı $MIN_REPS-$MAX_REPS arasında olmalıdır',
      );
    }

    if (workoutTypeId < 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz workout type ID',
      );
    }

    return ValidationResult(isValid: true);
  }
}

class Exercises with ExerciseValidation {
  final int id;
  final String name;
  final double defaultWeight;
  final int defaultSets;
  final int defaultReps;
  final int workoutTypeId;
  final String description;
  final String? gifUrl;

  const Exercises._({
    required this.id,
    required this.name,
    required this.defaultWeight,
    required this.defaultSets,
    required this.defaultReps,
    required this.workoutTypeId,
    required this.description,
    this.gifUrl,
  });

  factory Exercises({
    required int id,
    required String name,
    required double defaultWeight,
    required int defaultSets,
    required int defaultReps,
    required int workoutTypeId,
    required String description,
    String? gifUrl,
  }) {
    final validation = ExerciseValidation.validateExercise(
      name: name,
      defaultWeight: defaultWeight,
      defaultSets: defaultSets,
      defaultReps: defaultReps,
      workoutTypeId: workoutTypeId,
    );

    if (!validation.isValid) {
      throw ExerciseException(validation.message);
    }

    return Exercises._(
      id: id,
      name: name,
      defaultWeight: defaultWeight,
      defaultSets: defaultSets,
      defaultReps: defaultReps,
      workoutTypeId: workoutTypeId,
      description: description,
      gifUrl: gifUrl,
    );
  }

  factory Exercises.fromMap(Map<String, dynamic> map) {
    try {
      return Exercises(
        id: map['id'] as int? ?? 0,
        name: map['name'] as String? ?? '',
        defaultWeight: (map['defaultWeight'] as num?)?.toDouble() ?? 0.0,
        defaultSets: map['defaultSets'] as int? ?? 0,
        defaultReps: map['defaultReps'] as int? ?? 0,
        workoutTypeId: map['workoutTypeId'] as int? ?? 0,
        description: map['description'] as String? ?? '',
        gifUrl: map['gifUrl'] as String?,
      );
    } catch (e) {
      throw ExerciseException('Veri dönüştürme hatası: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'defaultWeight': defaultWeight,
      'defaultSets': defaultSets,
      'defaultReps': defaultReps,
      'workoutTypeId': workoutTypeId,
      'description': description,
      'gifUrl': gifUrl,
    };
  }
}

class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult({
    required this.isValid,
    this.message = '',
  });
}

class ExerciseException implements Exception {
  final String message;
  ExerciseException(this.message);

  @override
  String toString() => message;
}