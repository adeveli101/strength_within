mixin PartTargetValidation {
  static const int MIN_TARGET_PERCENTAGE = 1;
  static const int MAX_TARGET_PERCENTAGE = 100;

  static ValidationResult validatePartTarget({
    required int partId,
    required int bodyPartId,
    required int targetPercentage,
    bool isPrimary = false,
  }) {
    if (partId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz part ID: $partId',
      );
    }

    if (bodyPartId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz vücut bölgesi ID: $bodyPartId',
      );
    }

    if (targetPercentage < MIN_TARGET_PERCENTAGE ||
        targetPercentage > MAX_TARGET_PERCENTAGE) {
      return ValidationResult(
        isValid: false,
        message: 'Hedef yüzdesi $MIN_TARGET_PERCENTAGE-$MAX_TARGET_PERCENTAGE arasında olmalıdır. Girilen: $targetPercentage',
      );
    }

    if (isPrimary && targetPercentage <= 30) {
      return ValidationResult(
        isValid: false,
        message: 'Birincil hedef için yüzde 30\'dan büyük olmalıdır',
      );
    }

    return ValidationResult(isValid: true);
  }
}

class PartTargetedBodyParts with PartTargetValidation {
  final int? id;
  final int partId;
  final int bodyPartId;
  final bool isPrimary;
  final int targetPercentage;
  String? bodyPartName;

  PartTargetedBodyParts._({
    this.id,
    required this.partId,
    required this.bodyPartId,
    required this.isPrimary,
    required this.targetPercentage,
  });

  factory PartTargetedBodyParts({
    int? id,
    required int partId,
    required int bodyPartId,
    required bool isPrimary,
    int targetPercentage = 100,
  }) {
    final validation = PartTargetValidation.validatePartTarget(
      partId: partId,
      bodyPartId: bodyPartId,
      targetPercentage: targetPercentage,
    );

    if (!validation.isValid) {
      throw PartTargetException(validation.message);
    }

    return PartTargetedBodyParts._(
      id: id,
      partId: partId,
      bodyPartId: bodyPartId,
      isPrimary: isPrimary,
      targetPercentage: targetPercentage,
    );
  }

  PartTargetedBodyParts copyWith({
    int? id,
    int? partId,
    int? bodyPartId,
    bool? isPrimary,
    int? targetPercentage,
  }) {
    return PartTargetedBodyParts(
      id: id ?? this.id,
      partId: partId ?? this.partId,
      bodyPartId: bodyPartId ?? this.bodyPartId,
      isPrimary: isPrimary ?? this.isPrimary,
      targetPercentage: targetPercentage ?? this.targetPercentage,
    );
  }

  factory PartTargetedBodyParts.fromMap(Map<String, dynamic> map) {
    try {
      return PartTargetedBodyParts(
        id: map['id'],
        partId: map['partId'] as int,
        bodyPartId: map['bodyPartId'] as int,
        isPrimary: map['isPrimary'] == 1,
        targetPercentage: map['targetPercentage'] ?? 100,
      );
    } catch (e) {
      throw PartTargetException('Veri dönüştürme hatası: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'id': id,
        'partId': partId,
        'bodyPartId': bodyPartId,
        'isPrimary': isPrimary ? 1 : 0,
        'targetPercentage': targetPercentage,
      };
    } catch (e) {
      throw PartTargetException('Veri kaydetme hatası: $e');
    }
  }

  @override
  String toString() {
    return 'PartTargetedBodyParts(id: $id, partId: $partId, bodyPartId: $bodyPartId, '
        'isPrimary: $isPrimary, targetPercentage: $targetPercentage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PartTargetedBodyParts &&
        other.id == id &&
        other.partId == partId &&
        other.bodyPartId == bodyPartId &&
        other.isPrimary == isPrimary &&
        other.targetPercentage == targetPercentage;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      partId,
      bodyPartId,
      isPrimary,
      targetPercentage,
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

class PartTargetException implements Exception {
  final String message;
  PartTargetException(this.message);

  @override
  String toString() => message;
}