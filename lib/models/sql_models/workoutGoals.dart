// models/workout_goals.dart

class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult({
    required this.isValid,
    this.message = '',
  });
}
mixin WorkoutGoalValidation {
  static const int MIN_NAME_LENGTH = 2;
  static const int MAX_NAME_LENGTH = 100;
  static const int MAX_DESCRIPTION_LENGTH = 500;
  static const double MIN_BMI = 0.0;
  static const double MAX_BMI = 100.0;
  static const int MIN_INTENSITY = 1;
  static const int MAX_INTENSITY = 5;

  static ValidationResult validateWorkoutGoal({
    required String name,
    String? description,
    double? minBMI,
    double? maxBMI,
    required int recommendedIntensity,
  }) {
    if (name.isEmpty || name.length < MIN_NAME_LENGTH || name.length > MAX_NAME_LENGTH) {
      return ValidationResult(
        isValid: false,
        message: 'İsim $MIN_NAME_LENGTH-$MAX_NAME_LENGTH karakter arasında olmalıdır',
      );
    }

    if (description != null && description.length > MAX_DESCRIPTION_LENGTH) {
      return ValidationResult(
        isValid: false,
        message: 'Açıklama $MAX_DESCRIPTION_LENGTH karakterden uzun olamaz',
      );
    }

    if (minBMI != null && (minBMI < MIN_BMI || minBMI > MAX_BMI)) {
      return ValidationResult(
        isValid: false,
        message: 'Minimum BMI değeri $MIN_BMI-$MAX_BMI arasında olmalıdır',
      );
    }

    if (maxBMI != null && (maxBMI < MIN_BMI || maxBMI > MAX_BMI)) {
      return ValidationResult(
        isValid: false,
        message: 'Maximum BMI değeri $MIN_BMI-$MAX_BMI arasında olmalıdır',
      );
    }

    if (recommendedIntensity < MIN_INTENSITY || recommendedIntensity > MAX_INTENSITY) {
      return ValidationResult(
        isValid: false,
        message: 'Önerilen yoğunluk $MIN_INTENSITY-$MAX_INTENSITY arasında olmalıdır',
      );
    }

    return ValidationResult(isValid: true);
  }
}

class WorkoutGoals {
  final int id;
  final String name;
  final String? description;
  final double? minBMI;
  final double? maxBMI;
  final int recommendedIntensity;
  final bool isHighRisk;

  WorkoutGoals({
    required this.id,
    required this.name,
    this.description,
    this.minBMI,
    this.maxBMI,
    required this.recommendedIntensity,
    this.isHighRisk = false,
  });

  factory WorkoutGoals.fromMap(Map<String, dynamic> map) {
    return WorkoutGoals(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      minBMI: map['minBMI'] as double?,
      maxBMI: map['maxBMI'] as double?,
      recommendedIntensity: map['recommendedIntensity'] as int,
      isHighRisk: map['isHighRisk'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'minBMI': minBMI,
      'maxBMI': maxBMI,
      'recommendedIntensity': recommendedIntensity,
      'isHighRisk': isHighRisk ? 1 : 0,
    };
  }

  WorkoutGoals copyWith({
    int? id,
    String? name,
    String? description,
    double? minBMI,
    double? maxBMI,
    int? recommendedIntensity,
    bool? isHighRisk,
  }) {
    return WorkoutGoals(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      minBMI: minBMI ?? this.minBMI,
      maxBMI: maxBMI ?? this.maxBMI,
      recommendedIntensity: recommendedIntensity ?? this.recommendedIntensity,
      isHighRisk: isHighRisk ?? this.isHighRisk,
    );
  }
}
