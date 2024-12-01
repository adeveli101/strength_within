mixin RoutineTargetValidation {
  static const int MIN_TARGET_PERCENTAGE = 1;
  static const int MAX_TARGET_PERCENTAGE = 100;

  static ValidationResult validateRoutineTarget({
    required int routineId,
    required int bodyPartId,
    required int targetPercentage,
  }) {
    if (routineId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz routine ID',
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

class RoutineTargetedBodyParts with RoutineTargetValidation {
  final int? id;
  final int routineId;
  final int bodyPartId;
  final int targetPercentage;

  const RoutineTargetedBodyParts._({
    this.id,
    required this.routineId,
    required this.bodyPartId,
    required this.targetPercentage,
  });

  factory RoutineTargetedBodyParts({
    int? id,
    required int routineId,
    required int bodyPartId,
    int targetPercentage = 100,
  }) {
    final validation = RoutineTargetValidation.validateRoutineTarget(
      routineId: routineId,
      bodyPartId: bodyPartId,
      targetPercentage: targetPercentage,
    );

    if (!validation.isValid) {
      throw RoutineTargetException(validation.message);
    }

    return RoutineTargetedBodyParts._(
      id: id,
      routineId: routineId,
      bodyPartId: bodyPartId,
      targetPercentage: targetPercentage,
    );
  }

  factory RoutineTargetedBodyParts.fromMap(Map<String, dynamic> map) {
    try {
      return RoutineTargetedBodyParts(
        id: map['id'],
        routineId: map['routineId'] as int,
        bodyPartId: map['bodyPartId'] as int,
        targetPercentage: map['targetPercentage'] ?? 100,
      );
    } catch (e) {
      throw RoutineTargetException('Veri dönüştürme hatası: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'id': id,
        'routineId': routineId,
        'bodyPartId': bodyPartId,
        'targetPercentage': targetPercentage,
      };
    } catch (e) {
      throw RoutineTargetException('Veri kaydetme hatası: $e');
    }
  }

  @override
  String toString() {
    return 'RoutineTargetedBodyParts(id: $id, routineId: $routineId, '
        'bodyPartId: $bodyPartId, targetPercentage: $targetPercentage)';
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

class RoutineTargetException implements Exception {
  final String message;
  RoutineTargetException(this.message);

  @override
  String toString() => message;
}