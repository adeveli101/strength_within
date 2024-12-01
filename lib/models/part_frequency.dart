mixin PartFrequencyValidation {
  static const int MIN_FREQUENCY = 1;
  static const int MAX_FREQUENCY = 7;
  static const int MIN_REST_DAYS = 0;
  static const int MAX_REST_DAYS = 7;

  static ValidationResult validatePartFrequency({
    required int partId,
    required int recommendedFrequency,
    required int minRestDays,
  }) {
    if (partId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz part ID',
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

class PartFrequency with PartFrequencyValidation {
  final int? id;
  final int partId;
  final int recommendedFrequency;
  final int minRestDays;

  const PartFrequency._({
    this.id,
    required this.partId,
    required this.recommendedFrequency,
    required this.minRestDays,
  });

  factory PartFrequency({
    int? id,
    required int partId,
    required int recommendedFrequency,
    required int minRestDays,
  }) {
    final validation = PartFrequencyValidation.validatePartFrequency(
      partId: partId,
      recommendedFrequency: recommendedFrequency,
      minRestDays: minRestDays,
    );

    if (!validation.isValid) {
      throw PartFrequencyException(validation.message);
    }

    return PartFrequency._(
      id: id,
      partId: partId,
      recommendedFrequency: recommendedFrequency,
      minRestDays: minRestDays,
    );
  }

  factory PartFrequency.fromMap(Map<String, dynamic> map) {
    try {
      return PartFrequency(
        id: map['id'],
        partId: map['partId'] as int,
        recommendedFrequency: map['recommendedFrequency'] as int,
        minRestDays: map['minRestDays'] as int,
      );
    } catch (e) {
      throw PartFrequencyException('Veri dönüştürme hatası: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'id': id,
        'partId': partId,
        'recommendedFrequency': recommendedFrequency,
        'minRestDays': minRestDays,
      };
    } catch (e) {
      throw PartFrequencyException('Veri kaydetme hatası: $e');
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

class PartFrequencyException implements Exception {
  final String message;
  PartFrequencyException(this.message);

  @override
  String toString() => message;
}