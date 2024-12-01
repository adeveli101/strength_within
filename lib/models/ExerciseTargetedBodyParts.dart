mixin ExerciseTargetValidation {
  static const int MIN_TARGET_PERCENTAGE = 1;
  static const int MAX_TARGET_PERCENTAGE = 100;

  static ValidationResult validateExerciseTarget({
    required int exerciseId,
    required int bodyPartId,
    required int targetPercentage,
  }) {
    if (exerciseId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz egzersiz ID',
      );
    }

    if (bodyPartId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz vücut bölgesi ID',
      );
    }

    if (targetPercentage < MIN_TARGET_PERCENTAGE ||
        targetPercentage > MAX_TARGET_PERCENTAGE) {
      return ValidationResult(
        isValid: false,
        message: 'Hedef yüzdesi $MIN_TARGET_PERCENTAGE-$MAX_TARGET_PERCENTAGE arasında olmalıdır',
      );
    }

    return ValidationResult(isValid: true);
  }
}

class ExerciseTargetedBodyParts with ExerciseTargetValidation {
  final int? id;
  final int exerciseId;
  final int bodyPartId;
  final bool isPrimary;
  final int targetPercentage;

  const ExerciseTargetedBodyParts._({
    this.id,
    required this.exerciseId,
    required this.bodyPartId,
    required this.isPrimary,
    required this.targetPercentage,
  });

  factory ExerciseTargetedBodyParts({
    int? id,
    required int exerciseId,
    required int bodyPartId,
    required bool isPrimary,
    int targetPercentage = 100,
  }) {
    final validation = ExerciseTargetValidation.validateExerciseTarget(
      exerciseId: exerciseId,
      bodyPartId: bodyPartId,
      targetPercentage: targetPercentage,
    );

    if (!validation.isValid) {
      throw ExerciseTargetException(validation.message);
    }

    return ExerciseTargetedBodyParts._(
      id: id,
      exerciseId: exerciseId,
      bodyPartId: bodyPartId,
      isPrimary: isPrimary,
      targetPercentage: targetPercentage,
    );
  }

  factory ExerciseTargetedBodyParts.fromMap(Map<String, dynamic> map) {
    try {
      return ExerciseTargetedBodyParts(
        id: map['id'],
        exerciseId: map['exerciseId'] as int,
        bodyPartId: map['bodyPartId'] as int,
        isPrimary: map['isPrimary'] == 1,
        targetPercentage: map['targetPercentage'] ?? 100,
      );
    } catch (e) {
      throw ExerciseTargetException('Veri dönüştürme hatası: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'id': id,
        'exerciseId': exerciseId,
        'bodyPartId': bodyPartId,
        'isPrimary': isPrimary ? 1 : 0,
        'targetPercentage': targetPercentage,
      };
    } catch (e) {
      throw ExerciseTargetException('Veri kaydetme hatası: $e');
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

class ExerciseTargetException implements Exception {
  final String message;
  ExerciseTargetException(this.message);

  @override
  String toString() => message;
}