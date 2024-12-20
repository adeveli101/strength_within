// lib/ai_lib/ai_repository.dart

import 'dart:async';
import 'dart:math';
import 'package:logging/logging.dart';

import '../core/ai_constants.dart';
import '../core/ai_data_processor.dart';
import '../core/ai_exceptions.dart';
import '../core/trainingConfig.dart';
import '../models/agde_model.dart';
import '../models/collab_model.dart';
import '../models/knn_model.dart';
import 'dataset_provider.dart';


enum AIRepositoryState {
  uninitialized,
  initializing,
  ready,
  training,
  error
}

class AIRepository {
  // Singleton pattern
  static final AIRepository _instance = AIRepository._internal();
  factory AIRepository() => _instance;
  AIRepository._internal();

  final _logger = Logger('AIRepository');

  // Core components
  final _datasetProvider = DatasetDBProvider();
  final _dataProcessor = AIDataProcessor();

  // Models
  late final AGDEModel _agdeModel;
  late final KNNModel _knnModel;
  late final CollaborativeFilteringModel _collabModel;

  // Repository state
  AIRepositoryState _state = AIRepositoryState.uninitialized;
  AIRepositoryState get state => _state;

  // Stream controllers for metrics and state
  final _metricsController = StreamController<Map<String, dynamic>>.broadcast();
  final _stateController = StreamController<AIRepositoryState>.broadcast();

  // Model states and metrics
  final Map<String, Map<String, double>> _currentMetrics = {};

  // Public streams
  Stream<Map<String, dynamic>> get metricsStream => _metricsController.stream;
  Stream<AIRepositoryState> get stateStream => _stateController.stream;

  // Model weights for ensemble
  final Map<String, double> _modelWeights = {
    'agde': 0.4,
    'knn': 0.3,
    'collaborative': 0.3,
  };

  /// Repository initialization
  Future<void> initialize({Map<String, dynamic>? config}) async {
    if (_state != AIRepositoryState.uninitialized) return;

    try {
      _updateState(AIRepositoryState.initializing);

      // Initialize models
      _agdeModel = AGDEModel();
      _knnModel = KNNModel();
      _collabModel = CollaborativeFilteringModel();

      // Initialize database and get training data
      await _datasetProvider.initDatabase();
      final rawData = await _datasetProvider.getCombinedTrainingData();

      // Validate and process data
      final processedData = await _dataProcessor.processTrainingData();

      // Setup models
      await Future.wait([
        _agdeModel.setup(processedData),
        _knnModel.setup(processedData),
        _collabModel.setup(processedData)
      ]);

      _updateState(AIRepositoryState.ready);
      _logger.info('AI Repository initialized successfully');

    } catch (e) {
      _updateState(AIRepositoryState.error);
      _logger.severe('Repository initialization failed: $e');
      throw AIInitializationException('Repository initialization failed: $e');
    }
  }

  void _updateState(AIRepositoryState newState) {
    _state = newState;
    _stateController.add(newState);
    _logger.info('Repository state updated to: $_state');
  }

  void _updateMetrics(Map<String, Map<String, double>> metrics) {
    _currentMetrics.addAll(metrics);
    _metricsController.add(_currentMetrics);
  }



  Future<void> trainModels({
    required TrainingConfig config,
    bool useBatchProcessing = true,
  }) async {
    if (_state != AIRepositoryState.ready) {
      throw AITrainingException('Repository is not ready for training',
          code: AIConstants.ERROR_INVALID_STATE);
    }

    try {
      _updateState(AIRepositoryState.training);

      // Veri hazırlığı ve validasyon
      final trainingData = await _datasetProvider.getCombinedTrainingData();
      if (trainingData.length < AIConstants.MIN_TRAINING_SAMPLES) {
        throw AITrainingException('Insufficient training data',
            code: AIConstants.ERROR_INSUFFICIENT_DATA);
      }

      // AIDataProcessor'da processTrainingData metodunu doğru şekilde çağır
      final processedData = await _dataProcessor.processTrainingData();

      // Batch processing kontrolü
      if (useBatchProcessing) {
        await _processBatches(processedData, AIConstants.BATCH_SIZE);
      }

      // Model eğitimleri
      await Future.wait([
        _trainAGDEModel(processedData, config),
        _trainKNNModel(processedData, config),
        _trainCollabModel(processedData, config)
      ]);

      _updateState(AIRepositoryState.ready);

    } catch (e) {
      _updateState(AIRepositoryState.error);
      throw AITrainingException('Training failed: $e',
          code: AIConstants.ERROR_TRAINING_FAILED);
    }
  }

// Batch processing için yardımcı metod
  Future<void> _processBatches(List<Map<String, dynamic>> data, int batchSize) async {
    for (var i = 0; i < data.length; i += batchSize) {
      final end = min(i + batchSize, data.length);
      final batch = data.sublist(i, end);
      await _dataProcessor.processTrainingData();
    }
  }


  Future<void> _trainAGDEModel(
      List<Map<String, dynamic>> data,
      TrainingConfig config
      ) async {
    try {
      final trainingConfig = TrainingConfig(
        epochs: AIConstants.EPOCHS,
        batchSize: AIConstants.BATCH_SIZE,
        learningRate: AIConstants.LEARNING_RATE,
        earlyStoppingPatience: AIConstants.EARLY_STOPPING_PATIENCE,
        validationSplit: AIConstants.VALIDATION_SPLIT,
        minimumMetrics: AIConstants.MINIMUM_METRICS,
      );

      await _agdeModel.fit(data);
      final metrics = await _agdeModel.calculateMetrics(data);

      // Metrik validasyonu
      if (metrics['accuracy']! < AIConstants.MIN_ACCURACY) {
        throw AIModelException('Model accuracy below threshold',
            code: AIConstants.ERROR_LOW_ACCURACY);
      }

      _updateMetrics({'agde': metrics});

    } catch (e) {
      _logger.severe('AGDE training failed: $e');
      rethrow;
    }
  }

  Future<void> _trainKNNModel(
      List<Map<String, dynamic>> data,
      TrainingConfig config
      ) async {
    try {
      final knnConfig = TrainingConfig(
          kNeighbors: {
            'exercise': AIConstants.KNN_EXERCISE_K,
            'user': AIConstants.KNN_USER_K,
            'fitness': AIConstants.KNN_FITNESS_K
          },
          minimumConfidence: {
            'exercise': AIConstants.MIN_CONFIDENCE_EXERCISE,
            'user': AIConstants.MIN_CONFIDENCE_USER,
            'fitness': AIConstants.MIN_CONFIDENCE_FITNESS
          }
      );

      await _knnModel.fit(data);
      final metrics = await _knnModel.calculateMetrics(data);
      _updateMetrics({'knn': metrics});

    } catch (e) {
      _logger.severe('KNN training failed: $e');
      rethrow;
    }
  }

  Future<void> _trainCollabModel(
      List<Map<String, dynamic>> data,
      TrainingConfig config
      ) async {
    try {
      final collabConfig = TrainingConfig(
          similarityThreshold: AIConstants.SIMILARITY_THRESHOLD,
          maxRecommendations: AIConstants.MAX_RECOMMENDATIONS,
          featureWeights: AIConstants.FEATURE_WEIGHTS
      );

      await _collabModel.fit(data);
      final metrics = await _collabModel.calculateMetrics(data);
      _updateMetrics({'collaborative': metrics});

    } catch (e) {
      _logger.severe('Collaborative model training failed: $e');
      rethrow;
    }
  }


  /// Tahmin birleştirme
  Map<String, dynamic> _combineModelPredictions(
      Map<String, Map<String, dynamic>> predictions
      ) {
    final combinedPrediction = <String, dynamic>{};
    double totalConfidence = 0.0;

    predictions.forEach((modelName, prediction) {
      final weight = _modelWeights[modelName]!;
      final confidence = prediction['confidence'] as double;

      totalConfidence += confidence * weight;

      // Her modelin tahminini ağırlığına göre birleştir
      prediction.forEach((key, value) {
        if (key != 'confidence') {
          combinedPrediction[key] = value;
        }
      });
    });

    combinedPrediction['confidence'] = totalConfidence;
    return combinedPrediction;
  }

  /// Resource cleanup
  Future<void> dispose() async {
    try {
      await _agdeModel.dispose();
      await _knnModel.dispose();
      await _collabModel.dispose();

      _metricsController.close();
      _stateController.close();

      _state = AIRepositoryState.uninitialized;
      _logger.info('Repository resources released');
    } catch (e) {
      _logger.severe('Error during repository disposal: $e');
      rethrow;
    }
  }
}
