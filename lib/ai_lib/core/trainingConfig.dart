import 'ai_constants.dart';

class TrainingConfig {
  // Genel eğitim parametreleri
  final int epochs;
  final int batchSize;
  final double learningRate;
  final double validationSplit;
  final bool useEarlyStopping;
  final int earlyStoppingPatience;
  final double earlyStoppingThreshold;

  // Model-spesifik parametreler
  final Map<String, int> kNeighbors;
  final Map<String, double> minimumConfidence;
  final double similarityThreshold;
  final int maxRecommendations;
  final Map<String, double> featureWeights;

  // Performans ve kaynak yönetimi
  final int maxCacheSize;
  final int maxBatchSize;
  final double minValidDataRatio;

  // Metrik eşikleri
  final Map<String, double> minimumMetrics;

  // Veri augmentasyon ve önişleme seçenekleri
  final bool useDataAugmentation;
  final bool normalizeInputs;
  final bool handleMissingValues;

  // Ensemble ve transfer learning seçenekleri
  final bool useEnsembleLearning;
  final bool useTransferLearning;

  // Düzenlileştirme (regularization) seçenekleri
  final double l1Regularization;
  final double l2Regularization;
  final double dropoutRate;

  TrainingConfig({
    this.epochs = AIConstants.EPOCHS,
    this.batchSize = AIConstants.BATCH_SIZE,
    this.learningRate = AIConstants.LEARNING_RATE,
    this.validationSplit = AIConstants.VALIDATION_SPLIT,
    this.useEarlyStopping = true,
    this.earlyStoppingPatience = AIConstants.EARLY_STOPPING_PATIENCE,
    this.earlyStoppingThreshold = AIConstants.EARLY_STOPPING_THRESHOLD,
    this.kNeighbors = const {
      'exercise': AIConstants.KNN_EXERCISE_K,
      'user': AIConstants.KNN_USER_K,
      'fitness': AIConstants.KNN_FITNESS_K
    },
    this.minimumConfidence = const {
      'exercise': AIConstants.MIN_CONFIDENCE_EXERCISE,
      'user': AIConstants.MIN_CONFIDENCE_USER,
      'fitness': AIConstants.MIN_CONFIDENCE_FITNESS
    },
    this.similarityThreshold = AIConstants.SIMILARITY_THRESHOLD,
    this.maxRecommendations = AIConstants.MAX_RECOMMENDATIONS,
    this.featureWeights = AIConstants.FEATURE_WEIGHTS,
    this.maxCacheSize = AIConstants.MAX_CACHE_SIZE,
    this.maxBatchSize = AIConstants.MAX_BATCH_SIZE,
    this.minValidDataRatio = AIConstants.MIN_VALID_DATA_RATIO,
    this.minimumMetrics = AIConstants.MINIMUM_METRICS,
    this.useDataAugmentation = false,
    this.normalizeInputs = true,
    this.handleMissingValues = true,
    this.useEnsembleLearning = false,
    this.useTransferLearning = false,
    this.l1Regularization = 0.0,
    this.l2Regularization = 0.0,
    this.dropoutRate = 0.0,
  });

  // Konfigürasyonu JSON'a dönüştürme
  Map<String, dynamic> toJson() => {
    'epochs': epochs,
    'batchSize': batchSize,
    'learningRate': learningRate,
    'validationSplit': validationSplit,
    'useEarlyStopping': useEarlyStopping,
    'earlyStoppingPatience': earlyStoppingPatience,
    'earlyStoppingThreshold': earlyStoppingThreshold,
    'kNeighbors': kNeighbors,
    'minimumConfidence': minimumConfidence,
    'similarityThreshold': similarityThreshold,
    'maxRecommendations': maxRecommendations,
    'featureWeights': featureWeights,
    'maxCacheSize': maxCacheSize,
    'maxBatchSize': maxBatchSize,
    'minValidDataRatio': minValidDataRatio,
    'minimumMetrics': minimumMetrics,
    'useDataAugmentation': useDataAugmentation,
    'normalizeInputs': normalizeInputs,
    'handleMissingValues': handleMissingValues,
    'useEnsembleLearning': useEnsembleLearning,
    'useTransferLearning': useTransferLearning,
    'l1Regularization': l1Regularization,
    'l2Regularization': l2Regularization,
    'dropoutRate': dropoutRate,
  };

  // JSON'dan konfigürasyon oluşturma
  factory TrainingConfig.fromJson(Map<String, dynamic> json) => TrainingConfig(
    epochs: json['epochs'] ?? AIConstants.EPOCHS,
    batchSize: json['batchSize'] ?? AIConstants.BATCH_SIZE,
    learningRate: json['learningRate'] ?? AIConstants.LEARNING_RATE,
    validationSplit: json['validationSplit'] ?? AIConstants.VALIDATION_SPLIT,
    useEarlyStopping: json['useEarlyStopping'] ?? true,
    earlyStoppingPatience: json['earlyStoppingPatience'] ?? AIConstants.EARLY_STOPPING_PATIENCE,
    earlyStoppingThreshold: json['earlyStoppingThreshold'] ?? AIConstants.EARLY_STOPPING_THRESHOLD,
    kNeighbors: json['kNeighbors'] ?? const {'exercise': AIConstants.KNN_EXERCISE_K, 'user': AIConstants.KNN_USER_K, 'fitness': AIConstants.KNN_FITNESS_K},
    minimumConfidence: json['minimumConfidence'] ?? const {'exercise': AIConstants.MIN_CONFIDENCE_EXERCISE, 'user': AIConstants.MIN_CONFIDENCE_USER, 'fitness': AIConstants.MIN_CONFIDENCE_FITNESS},
    similarityThreshold: json['similarityThreshold'] ?? AIConstants.SIMILARITY_THRESHOLD,
    maxRecommendations: json['maxRecommendations'] ?? AIConstants.MAX_RECOMMENDATIONS,
    featureWeights: json['featureWeights'] ?? AIConstants.FEATURE_WEIGHTS,
    maxCacheSize: json['maxCacheSize'] ?? AIConstants.MAX_CACHE_SIZE,
    maxBatchSize: json['maxBatchSize'] ?? AIConstants.MAX_BATCH_SIZE,
    minValidDataRatio: json['minValidDataRatio'] ?? AIConstants.MIN_VALID_DATA_RATIO,
    minimumMetrics: json['minimumMetrics'] ?? AIConstants.MINIMUM_METRICS,
    useDataAugmentation: json['useDataAugmentation'] ?? false,
    normalizeInputs: json['normalizeInputs'] ?? true,
    handleMissingValues: json['handleMissingValues'] ?? true,
    useEnsembleLearning: json['useEnsembleLearning'] ?? false,
    useTransferLearning: json['useTransferLearning'] ?? false,
    l1Regularization: json['l1Regularization'] ?? 0.0,
    l2Regularization: json['l2Regularization'] ?? 0.0,
    dropoutRate: json['dropoutRate'] ?? 0.0,
  );
}
