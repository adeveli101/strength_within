/// AI sistemi için gerekli tüm sabit değerleri içeren sınıf
class AIConstants {
  // Private constructor to prevent instantiation
  AIConstants._();




  // Thresholds
  static const int DEFAULT_TIMEOUT = 300000; // 5 minutes in milliseconds

  /// Model Eğitim Parametreleri
  static const double LEARNING_RATE = 0.001;
  static const int BATCH_SIZE = 32;
  static const int EPOCHS = 100;
  static const int EARLY_STOPPING_PATIENCE = 10;
  static const double VALIDATION_SPLIT = 0.15;
  static const double EARLY_STOPPING_THRESHOLD = 1e-4;
  static const double MIN_LEARNING_RATE = 0.0001;
  static const double MAX_LEARNING_RATE = 0.1;
  static const double ADAPTIVE_RATE = 0.01;

  /// Model Boyutları ve Yapılandırma
  static const int INPUT_FEATURES = 7;
  static const int HIDDEN_LAYER_UNITS = 64;
  static const int OUTPUT_CLASSES = 7;
  static const int CHECKPOINT_INTERVAL = 10;
  static const int ENSEMBLE_SIZE = 5;

  /// KNN Parametreleri
  static const int KNN_EXERCISE_K = 5;
  static const int KNN_USER_K = 10;
  static const int KNN_FITNESS_K = 3;

  /// Güven Skorları
  static const double MIN_CONFIDENCE_EXERCISE = 0.6;
  static const double MIN_CONFIDENCE_USER = 0.7;
  static const double MIN_CONFIDENCE_FITNESS = 0.8;

  /// Minimum Metrikler
  static const Map<String, double> MINIMUM_METRICS = {
    'accuracy': 0.85,
    'precision': 0.80,
    'recall': 0.80,
    'f1_score': 0.82,
  };

  /// Feature Normalizasyon Aralıkları
  static const Map<String, Map<String, double>> FEATURE_RANGES = {
    'weight': {'min': 40.0, 'max': 150.0},
    'height': {'min': 1.4, 'max': 2.2},
    'bmi': {'min': 16.0, 'max': 40.0},
    'bfp': {'min': 5.0, 'max': 50.0},
    'age': {'min': 16.0, 'max': 80.0},
    'experience': {'min': 0.0, 'max': 10.0},
  };

  /// Hata Kodları

  static const String ERROR_SCENARIO_IN_PROGRESS = 'scenario_in_progress';
  static const String ERROR_EXECUTION_FAILED = 'execution_failed';
  static const String ERROR_NO_RESULTS = 'no_results';
  static const String ERROR_INVALID_SCENARIO = 'invalid_scenario';
  static const double METRIC_TOLERANCE = 0.001;
  static const String ERROR_TIMEOUT = 'TIMEOUT_ERROR';
  static const String ERROR_VALIDATION_FAILED = 'VALIDATION_FAILED';
  static const String ERROR_PRECONDITION_FAILED = 'PRECONDITION_FAILED';
  static const String ERROR_CRITICAL_STEP_FAILED = 'CRITICAL_STEP_FAILED';
  static const String ERROR_INSUFFICIENT_DATA = 'INSUFFICIENT_DATA';
  static const String ERROR_LOW_ACCURACY = 'E002';
  static const String ERROR_TRAINING_FAILED = 'E003';
  static const String ERROR_PREDICTION_FAILED = 'E004';
  static const String ERROR_INVALID_INPUT = 'E005';
  static const String ERROR_BATCH_PROCESSING_FAILED = 'E006';

  /// Sistem Limitleri
  static const int MAX_CACHE_SIZE = 1000000;
  static const int MAX_BATCH_SIZE = 1000;
  static const int MAX_PROCESSING_HISTORY = 1000;
  static const double MIN_VALID_DATA_RATIO = 0.8;
  static const int MAX_RETRIES = 3;
  static const int RETRY_DELAY_SECONDS = 1;



  /// Veri normalizasyon sabitleri
  static const double MIN_BMI = 15.0;
  static const double MAX_BMI = 40.0;
  static const double MIN_BFP = 5.0;
  static const double MAX_BFP = 60.0;
  static const int MIN_AGE = 16;
  static const int MAX_AGE = 80;


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

}



