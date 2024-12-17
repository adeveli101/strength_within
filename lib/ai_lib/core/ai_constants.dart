/// AI sistemi için gerekli tüm sabit değerleri içeren sınıf
class AIConstants {
  // Private constructor to prevent instantiation
  AIConstants._();

  /// Model eğitim parametreleri
  static const double LEARNING_RATE = 0.001;
  static const int BATCH_SIZE = 32;
  static const int EPOCHS = 100;
  static const int EARLY_STOPPING_PATIENCE = 10;
  static const double VALIDATION_SPLIT = 0.15;

  /// Model boyutları
  static const int INPUT_FEATURES = 7; // weight, height, bmi, bfp, gender, age, experience
  static const int HIDDEN_LAYER_UNITS = 64;
  static const int OUTPUT_CLASSES = 7; // Exercise plan levels (1-7)

  /// Veri normalizasyon sabitleri
  static const double MIN_BMI = 15.0;
  static const double MAX_BMI = 40.0;
  static const double MIN_BFP = 5.0;
  static const double MAX_BFP = 60.0;
  static const int MIN_AGE = 16;
  static const int MAX_AGE = 80;

  /// Model değerlendirme metrikleri için minimum kabul edilebilir değerler
  static const Map<String, double> MINIMUM_METRICS = {
    'accuracy': 0.85,
    'precision': 0.80,
    'recall': 0.80,
    'f1_score': 0.82,
  };

  /// Egzersiz planı seviyeleri ve açıklamaları
  static const Map<int, String> EXERCISE_PLAN_DESCRIPTIONS = {
    1: 'Severely Underweight Program',
    2: 'Underweight Program',
    3: 'Normal Weight Beginner Program',
    4: 'Normal Weight Intermediate Program',
    5: 'Overweight Program',
    6: 'Obese Program',
    7: 'Severely Obese Program',
  };

  /// Model hata kodları
  static const String ERROR_INSUFFICIENT_DATA = 'E001';
  static const String ERROR_LOW_ACCURACY = 'E002';
  static const String ERROR_TRAINING_FAILED = 'E003';
  static const String ERROR_PREDICTION_FAILED = 'E004';
  static const String ERROR_INVALID_INPUT = 'E005';
}
