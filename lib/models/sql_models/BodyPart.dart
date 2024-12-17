// Validation için mixin
mixin BodyPartValidation {
  static const int MIN_NAME_LENGTH = 2;
  static const int MAX_NAME_LENGTH = 25;

  // Static metod olarak tanımlama
  static ValidationResult validateBodyPart({
    required String name,
    int? parentBodyPartId,
  }) {
    if (name.isEmpty || name.length < MIN_NAME_LENGTH) {
      return ValidationResult(
        isValid: false,
        message: 'İsim en az $MIN_NAME_LENGTH karakter olmalıdır',
      );
    }

    if (name.length > MAX_NAME_LENGTH) {
      return ValidationResult(
        isValid: false,
        message: 'İsim en fazla $MAX_NAME_LENGTH karakter olmalıdır',
      );
    }

    if (parentBodyPartId != null && parentBodyPartId < 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz parent body part ID',
      );
    }

    return ValidationResult(isValid: true);
  }
}


class BodyParts with BodyPartValidation {
  final int id;
  final String name;
  final int? parentBodyPartId;
  final bool isCompound;

  const BodyParts._({
    required this.id,
    required this.name,
    this.parentBodyPartId,
    this.isCompound = false,
  });

  factory BodyParts({
    required int id,
    required String name,
    int? parentBodyPartId,
    bool isCompound = false,
  }) {
    // Statik metodu doğrudan çağırma
    final validation = BodyPartValidation.validateBodyPart(
      name: name,
      parentBodyPartId: parentBodyPartId,
    );

    if (!validation.isValid) {
      throw BodyPartException(validation.message);
    }

    return BodyParts._(
      id: id,
      name: name,
      parentBodyPartId: parentBodyPartId,
      isCompound: isCompound,
    );
  }


  factory BodyParts.fromMap(Map<String, dynamic> map) {
    try {
      return BodyParts(
        id: map['id'] as int? ?? 0,
        name: map['name'] as String? ?? '',
        parentBodyPartId: map['parentBodyPartId'] as int?,
        isCompound: map['isCompound'] == 1,
      );
    } catch (e) {
      throw BodyPartException('Veri dönüştürme hatası: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'id': id,
        'name': name,
        'parentBodyPartId': parentBodyPartId,
        'isCompound': isCompound ? 1 : 0,
      };
    } catch (e) {
      throw BodyPartException('Veri kaydetme hatası: $e');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BodyParts &&
        other.id == id &&
        other.name == name &&
        other.parentBodyPartId == parentBodyPartId &&
        other.isCompound == isCompound;
  }

  @override
  int get hashCode => Object.hash(id, name, parentBodyPartId, isCompound);
}

class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult({
    required this.isValid,
    this.message = '',
  });
}

class BodyPartException implements Exception {
  final String message;
  BodyPartException(this.message);

  @override
  String toString() => message;
}