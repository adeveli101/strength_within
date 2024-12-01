mixin WorkoutTypeValidation {
  static const int MIN_NAME_LENGTH = 2;
  static const int MAX_NAME_LENGTH = 50;

  static ValidationResult validateWorkoutType({
    required String name,
  }) {
    if (name.isEmpty || name.length < MIN_NAME_LENGTH || name.length > MAX_NAME_LENGTH) {
      return ValidationResult(
        isValid: false,
        message: 'İsim $MIN_NAME_LENGTH-$MAX_NAME_LENGTH karakter arasında olmalıdır',
      );
    }

    return ValidationResult(isValid: true);
  }
}

class WorkoutTypes with WorkoutTypeValidation {
  final int id;
  final String name;

  const WorkoutTypes._({
    required this.id,
    required this.name,
  });

  factory WorkoutTypes({
    required int id,
    required String name,
  }) {
    final validation = WorkoutTypeValidation.validateWorkoutType(
      name: name,
    );

    if (!validation.isValid) {
      throw WorkoutTypeException(validation.message);
    }

    return WorkoutTypes._(
      id: id,
      name: name,
    );
  }

  factory WorkoutTypes.fromMap(Map<String, dynamic> map) {
    try {
      return WorkoutTypes(
        id: map['id'] as int? ?? 0,
        name: map['name'] as String? ?? '',
      );
    } catch (e) {
      throw WorkoutTypeException('Veri dönüştürme hatası: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'id': id,
        'name': name,
      };
    } catch (e) {
      throw WorkoutTypeException('Veri kaydetme hatası: $e');
    }
  }

  WorkoutTypes copyWith({
    int? id,
    String? name,
  }) {
    return WorkoutTypes(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  String toString() => 'WorkoutType(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutTypes &&
        other.id == id &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}

class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult({
    required this.isValid,
    this.message = '',
  });
}

class WorkoutTypeException implements Exception {
  final String message;
  WorkoutTypeException(this.message);

  @override
  String toString() => message;
}