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
  static const int CHECKPOINT_INTERVAL = 10; // Her 10 epoch'ta bir checkpoint


  /// Veri normalizasyon sabitleri
  static const double MIN_BMI = 15.0;
  static const double MAX_BMI = 40.0;
  static const double MIN_BFP = 5.0;
  static const double MAX_BFP = 60.0;
  static const int MIN_AGE = 16;
  static const int MAX_AGE = 80;

  static const int KNN_EXERCISE_K = 5;  // Egzersiz önerileri için k değeri
  static const int KNN_USER_K = 10;     // Kullanıcı benzerliği için k değeri
  static const int KNN_FITNESS_K = 3;    // Fitness seviyesi sınıflandırması için k değeri

  // Minimum güven skorları
  static const double MIN_CONFIDENCE_EXERCISE = 0.6;  // Egzersiz önerileri için minimum güven skoru
  static const double MIN_CONFIDENCE_USER = 0.7;      // Kullanıcı benzerliği için minimum güven skoru
  static const double MIN_CONFIDENCE_FITNESS = 0.8;   // Fitness sınıflandırması için minimum güven skoru

  // Hata kodları
  static const String ERROR_INVALID_INPUT = 'INVALID_INPUT';
  static const String ERROR_INSUFFICIENT_DATA = 'INSUFFICIENT_DATA';
  static const String ERROR_INVALID_STATE = 'INVALID_STATE';
  static const String ERROR_LOW_CONFIDENCE = 'LOW_CONFIDENCE';

  // Model parametreleri
  static const int MIN_TRAINING_SAMPLES = 20;        // Minimum eğitim örneği sayısı
  static const int MAX_RECOMMENDATIONS = 10;         // Maksimum öneri sayısı
  static const double SIMILARITY_THRESHOLD = 0.5;    // Benzerlik eşiği

  // Fitness seviyeleri
  static const Map<int, String> FITNESS_LEVELS = {
    1: 'Beginner',
    2: 'Intermediate',
    3: 'Advanced',
    4: 'Expert',
    5: 'Elite'
  };

  // Özellik ağırlıkları
  static const Map<String, double> FEATURE_WEIGHTS = {
    'fitness_level': 0.3,
    'exercise_history': 0.2,
    'preferred_muscle_groups': 0.15,
    'workout_duration': 0.15,
    'intensity_preference': 0.2
  };


  static const double EARLY_STOPPING_THRESHOLD = 1e-4;

  // Feature ranges için normalizasyon değerleri



  // Performans metrikleri
  static const int MAX_INFERENCE_TIME_MS = 1000;     // Maksimum çıkarım süresi (ms)
  static const int MAX_TRAINING_TIME_MS = 5000;      // Maksimum eğitim süresi (ms)
  static const int PERFORMANCE_HISTORY_SIZE = 1000;   // Performans geçmişi boyutu

  // Öneri sistemi sabitleri
  static const int KNN_NEIGHBORS_COUNT = 5;
  static const int COLLAB_RECOMMENDATIONS_COUNT = 5;

  // Minimum metrik değerleri
  static const double MIN_ACCURACY = 0.85;
  static const double MIN_PRECISION = 0.80;
  static const double MIN_RECALL = 0.80;
  static const double MIN_F1_SCORE = 0.82;

  static const int MAX_RETRIES = 3;
  static const int RETRY_DELAY_SECONDS = 1;

  // Bellek yönetimi için
  static const int MAX_CACHE_SIZE = 1000000; // 1M kayıt
  static const int MAX_BATCH_SIZE = 1000;

  // Veri doğrulama için
  static const double MIN_VALID_DATA_RATIO = 0.8; // %80

  // Performans metrikleri için
  static const int MAX_PROCESSING_HISTORY = 1000;




  /// Model hata kodları
  static const String ERROR_LOW_ACCURACY = 'E002';
  static const String ERROR_TRAINING_FAILED = 'E003';
  static const String ERROR_PREDICTION_FAILED = 'E004';



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

  static const Map<String, Map<String, double>> FEATURE_RANGES = {
    'weight': {'min': 40.0, 'max': 150.0},
    'height': {'min': 1.4, 'max': 2.2},
    'bmi': {'min': 16.0, 'max': 40.0},
    'bfp': {'min': 5.0, 'max': 50.0},
    'age': {'min': 16.0, 'max': 80.0},
    'experience': {'min': 0.0, 'max': 10.0},
  };


}
