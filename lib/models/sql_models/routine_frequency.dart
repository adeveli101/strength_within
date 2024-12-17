mixin RoutineFrequencyValidation {
  static const int MIN_FREQUENCY = 1;
  static const int MAX_FREQUENCY = 7;
  static const int MIN_REST_DAYS = 0;
  static const int MAX_REST_DAYS = 7;

  static ValidationResult validateRoutineFrequency({
    required int routineId,
    required int recommendedFrequency,
    required int minRestDays,
  }) {
    if (routineId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz routine ID',
      );
    }

    if (recommendedFrequency < MIN_FREQUENCY || recommendedFrequency > MAX_FREQUENCY) {
      return ValidationResult(
        isValid: false,
        message: 'Önerilen frekans $MIN_FREQUENCY-$MAX_FREQUENCY arasında olmalıdır',
      );
    }

    if (minRestDays < MIN_REST_DAYS || minRestDays > MAX_REST_DAYS) {
      return ValidationResult(
        isValid: false,
        message: 'Minimum dinlenme günü $MIN_REST_DAYS-$MAX_REST_DAYS arasında olmalıdır',
      );
    }

    if (minRestDays >= recommendedFrequency) {
      return ValidationResult(
        isValid: false,
        message: 'Dinlenme günü, önerilen frekanstan küçük olmalıdır',
      );
    }

    return ValidationResult(isValid: true);
  }
}

class RoutineFrequency with RoutineFrequencyValidation {
  final int? id;
  final int routineId;
  final int recommendedFrequency;
  final int minRestDays;

  const RoutineFrequency._({
    this.id,
    required this.routineId,
    required this.recommendedFrequency,
    required this.minRestDays,
  });

  factory RoutineFrequency({
    int? id,
    required int routineId,
    required int recommendedFrequency,
    required int minRestDays,
  }) {
    final validation = RoutineFrequencyValidation.validateRoutineFrequency(
      routineId: routineId,
      recommendedFrequency: recommendedFrequency,
      minRestDays: minRestDays,
    );

    if (!validation.isValid) {
      throw RoutineFrequencyException(validation.message);
    }

    return RoutineFrequency._(
      id: id,
      routineId: routineId,
      recommendedFrequency: recommendedFrequency,
      minRestDays: minRestDays,
    );
  }

  factory RoutineFrequency.fromMap(Map<String, dynamic> map) {
    try {
      return RoutineFrequency(
        id: map['id'],
        routineId: map['routineId'] as int,
        recommendedFrequency: map['recommendedFrequency'] as int,
        minRestDays: map['minRestDays'] as int,
      );
    } catch (e) {
      throw RoutineFrequencyException('Veri dönüştürme hatası: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'id': id,
        'routineId': routineId,
        'recommendedFrequency': recommendedFrequency,
        'minRestDays': minRestDays,
      };
    } catch (e) {
      throw RoutineFrequencyException('Veri kaydetme hatası: $e');
    }
  }

  @override
  String toString() {
    return 'RoutineFrequency(id: $id, routineId: $routineId, '
        'recommendedFrequency: $recommendedFrequency, minRestDays: $minRestDays)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoutineFrequency &&
        other.id == id &&
        other.routineId == routineId &&
        other.recommendedFrequency == recommendedFrequency &&
        other.minRestDays == minRestDays;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      routineId,
      recommendedFrequency,
      minRestDays,
    );
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

class RoutineFrequencyException implements Exception {
  final String message;
  RoutineFrequencyException(this.message);

  @override
  String toString() => message;
}