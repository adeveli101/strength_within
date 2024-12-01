mixin RoutineExerciseValidation {
  static const int MIN_ORDER_INDEX = 0;
  static const int MAX_ORDER_INDEX = 1000;

  static ValidationResult validateRoutineExercise({
    required int routineId,
    required int exerciseId,
    required int orderIndex,
  }) {
    if (routineId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz routine ID',
      );
    }

    if (exerciseId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz exercise ID',
      );
    }

    if (orderIndex < MIN_ORDER_INDEX || orderIndex > MAX_ORDER_INDEX) {
      return ValidationResult(
        isValid: false,
        message: 'Sıralama indeksi $MIN_ORDER_INDEX-$MAX_ORDER_INDEX arasında olmalıdır',
      );
    }

    return ValidationResult(isValid: true);
  }
}

class RoutineExercises with RoutineExerciseValidation {
  final int id;
  final int routineId;
  final int exerciseId;
  final int orderIndex;

  const RoutineExercises._({
    required this.id,
    required this.routineId,
    required this.exerciseId,
    required this.orderIndex,
  });

  factory RoutineExercises({
    required int id,
    required int routineId,
    required int exerciseId,
    required int orderIndex,
  }) {
    final validation = RoutineExerciseValidation.validateRoutineExercise(
      routineId: routineId,
      exerciseId: exerciseId,
      orderIndex: orderIndex,
    );

    if (!validation.isValid) {
      throw RoutineExerciseException(validation.message);
    }

    return RoutineExercises._(
      id: id,
      routineId: routineId,
      exerciseId: exerciseId,
      orderIndex: orderIndex,
    );
  }

  factory RoutineExercises.fromMap(Map<String, dynamic> map) {
    try {
      return RoutineExercises(
        id: map['id'] as int,
        routineId: map['routineId'] as int,
        exerciseId: map['exerciseId'] as int,
        orderIndex: map['orderIndex'] as int,
      );
    } catch (e) {
      throw RoutineExerciseException('Veri dönüştürme hatası: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'id': id,
        'routineId': routineId,
        'exerciseId': exerciseId,
        'orderIndex': orderIndex,
      };
    } catch (e) {
      throw RoutineExerciseException('Veri kaydetme hatası: $e');
    }
  }

  Map<String, dynamic> toFirestore() {
    try {
      return toMap();
    } catch (e) {
      throw RoutineExerciseException('Firestore kaydetme hatası: $e');
    }
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

class RoutineExerciseException implements Exception {
  final String message;
  RoutineExerciseException(this.message);

  @override
  String toString() => message;
}