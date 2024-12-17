mixin PartExerciseValidation {
  static const int MIN_ORDER_INDEX = 0;
  static const int MIN_TARGET_PERCENTAGE = 1;
  static const int MAX_TARGET_PERCENTAGE = 100;

  static ValidationResult validatePartExercise({
    required int partId,
    required int exerciseId,
    required int orderIndex,
    required int targetPercentage,
  }) {
    if (partId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz part ID',
      );
    }

    if (exerciseId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz exercise ID',
      );
    }

    if (orderIndex < MIN_ORDER_INDEX) {
      return ValidationResult(
        isValid: false,
        message: 'Sıralama indeksi negatif olamaz',
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

class PartExercise with PartExerciseValidation {
  final int id;
  final int partId;
  final int exerciseId;
  final int orderIndex;
  final bool isPrimary;
  final int targetPercentage;

  const PartExercise._({
    required this.id,
    required this.partId,
    required this.exerciseId,
    required this.orderIndex,
    required this.isPrimary,
    required this.targetPercentage,
  });

  factory PartExercise({
    required int id,
    required int partId,
    required int exerciseId,
    required int orderIndex,
    bool isPrimary = false,
    int targetPercentage = 100,
  }) {
    final validation = PartExerciseValidation.validatePartExercise(
      partId: partId,
      exerciseId: exerciseId,
      orderIndex: orderIndex,
      targetPercentage: targetPercentage,
    );

    if (!validation.isValid) {
      throw PartExerciseException(validation.message);
    }

    return PartExercise._(
      id: id,
      partId: partId,
      exerciseId: exerciseId,
      orderIndex: orderIndex,
      isPrimary: isPrimary,
      targetPercentage: targetPercentage,
    );
  }

  factory PartExercise.fromMap(Map<String, dynamic> map) {
    try {
      return PartExercise(
        id: map['id'] as int,
        partId: map['partId'] as int,
        exerciseId: int.parse(map['exerciseId'].toString()),
        orderIndex: map['orderIndex'] as int? ?? 0,
        isPrimary: (map['isPrimary'] as int?) == 1,
        targetPercentage: map['targetPercentage'] as int? ?? 100,
      );
    } catch (e) {
      throw PartExerciseException('Veri dönüştürme hatası: $e');
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

class PartExerciseException implements Exception {
  final String message;
  PartExerciseException(this.message);

  @override
  String toString() => message;
}