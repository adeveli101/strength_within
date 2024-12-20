import 'dart:math' show max, sqrt, pow;
import 'package:logging/logging.dart';
import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import '../core/ai_data_processor.dart';
import 'base_model.dart';

enum KNNModelState {
  uninitialized,
  initializing,
  initialized,
  training,
  trained,
  predicting,
  error
}


enum KNNTaskType {
  exerciseRecommendation,
  userSimilarity,
  fitnessLevelClassification
}

class KNNModel extends BaseModel {
  final _logger = Logger('KNNModel');
  final _dataProcessor = AIDataProcessor();

  // Model durumu
  late List<Map<String, dynamic>> _trainingData;
  late Map<KNNTaskType, int> _kValues;
  late Map<KNNTaskType, List<String>> _taskFeatures;

  // Feature normalizasyon değerleri
  final Map<String, Map<String, double>> _featureRanges = {};

  // Task-specific özellikler
  static const Map<KNNTaskType, List<String>> defaultFeatures = {
    KNNTaskType.exerciseRecommendation: [
      'fitness_level',
      'exercise_history',
      'preferred_muscle_groups',
      'workout_duration',
      'intensity_preference'
    ],
    KNNTaskType.userSimilarity: [
      'age',
      'weight',
      'height',
      'fitness_goals',
      'activity_level',
      'exercise_preferences'
    ],
    KNNTaskType.fitnessLevelClassification: [
      'exercise_frequency',
      'workout_intensity',
      'endurance_score',
      'strength_score',
      'recovery_rate'
    ]
  };
  late int _k;


  KNNModelState _modelState = KNNModelState.uninitialized;

  KNNTaskType _currentTaskType = KNNTaskType.exerciseRecommendation;

  // Training history için limit
  static const int MAX_HISTORY_SIZE = 1000;
  final Map<String, List<double>> _trainingHistory = {
    'accuracy': [],
    'precision': [],
    'recall': [],
    'f1_score': [],
  };

  // Metrik güncelleme metodu
  void _updateMetricsWithLimit(Map<String, double> metrics) {
    metrics.forEach((key, value) {
      _trainingHistory[key]?.add(value);
      if ((_trainingHistory[key]?.length ?? 0) > MAX_HISTORY_SIZE) {
        _trainingHistory[key]?.removeAt(0);
      }
    });
  }

  // Task tipi ayarlama metodu
  void setTaskType(KNNTaskType taskType) {
    _currentTaskType = taskType;
    // Task değiştiğinde k değerini güncelle
    if (_kValues.containsKey(taskType)) {
      _k = _kValues[taskType]!;
    }
  }

  // State güncelleme yardımcı metodu
  void _updateState(KNNModelState newState) {
    _modelState = newState;
    _logger.info('KNN Model state updated to: $_modelState');
  }

  // Add metric calculation methods
  double _calculateAccuracy(List<Map<String, dynamic>> predictions, List<Map<String, dynamic>> actual) {
    int correct = 0;
    for (var i = 0; i < predictions.length; i++) {
      if (predictions[i]['prediction'] == actual[i]['label']) {
        correct++;
      }
    }
    return correct / predictions.length;
  }

  double _calculatePrecision(List<Map<String, dynamic>> predictions, List<Map<String, dynamic>> actual) {
    Map<int, Map<String, int>> metrics = {};

    for (var i = 0; i < predictions.length; i++) {
      final predicted = predictions[i]['prediction'] as int;
      final actualLabel = actual[i]['label'] as int;

      metrics.putIfAbsent(predicted, () => {'tp': 0, 'fp': 0});
      if (predicted == actualLabel) {
        metrics[predicted]!['tp'] = metrics[predicted]!['tp']! + 1;
      } else {
        metrics[predicted]!['fp'] = metrics[predicted]!['fp']! + 1;
      }
    }

    double totalPrecision = 0.0;
    int classCount = 0;
    metrics.forEach((key, value) {
      final tp = value['tp']!;
      final fp = value['fp']!;
      if (tp + fp > 0) {
        totalPrecision += tp / (tp + fp);
        classCount++;
      }
    });

    return classCount > 0 ? totalPrecision / classCount : 0.0;
  }

  double _calculateRecall(List<Map<String, dynamic>> predictions, List<Map<String, dynamic>> actual) {
    Map<int, Map<String, int>> metrics = {};

    for (var i = 0; i < predictions.length; i++) {
      final predicted = predictions[i]['prediction'] as int;
      final actualLabel = actual[i]['label'] as int;

      metrics.putIfAbsent(actualLabel, () => {'tp': 0, 'fn': 0});
      if (predicted == actualLabel) {
        metrics[actualLabel]!['tp'] = metrics[actualLabel]!['tp']! + 1;
      } else {
        metrics[actualLabel]!['fn'] = metrics[actualLabel]!['fn']! + 1;
      }
    }

    double totalRecall = 0.0;
    int classCount = 0;
    metrics.forEach((key, value) {
      final tp = value['tp']!;
      final fn = value['fn']!;
      if (tp + fn > 0) {
        totalRecall += tp / (tp + fn);
        classCount++;
      }
    });

    return classCount > 0 ? totalRecall / classCount : 0.0;
  }

  double _calculateF1Score(List<Map<String, dynamic>> predictions, List<Map<String, dynamic>> actual) {
    final precision = _calculatePrecision(predictions, actual);
    final recall = _calculateRecall(predictions, actual);

    return (precision + recall) > 0
        ? 2 * (precision * recall) / (precision + recall)
        : 0.0;
  }


  // Remove duplicate calculateConfidence and replace with override
  @override
  Future<double> calculateConfidence(Map<String, dynamic> input, dynamic prediction) async {
    final distances = prediction['distances'] as List<double>;
    if (distances.isEmpty) return 0.0;

    final maxDistance = distances.reduce(max);
    final confidences = distances.map((d) => 1 - (d / maxDistance)).toList();
    return confidences.reduce((a, b) => a + b) / confidences.length;
  }



  @override
  Future<Map<String, double>> calculateMetrics(List<Map<String, dynamic>> testData) async {
    final predictions = await Future.wait(
        testData.map((sample) => inference(sample))
    );

    return {
      'accuracy': _calculateAccuracy(predictions, testData),
      'precision': _calculatePrecision(predictions, testData),
      'recall': _calculateRecall(predictions, testData),
      'f1_score': _calculateF1Score(predictions, testData)
    };
  }

  @override
  Future<void> fit(List<Map<String, dynamic>> trainingData) async {
    try {
      if (_modelState != KNNModelState.initialized) {
        throw AIModelException('Model must be initialized before training');
      }

      _modelState = KNNModelState.training;

      // Validate input data
      await validateData(trainingData);

      // Store and preprocess training data
      _trainingData = await Future.wait(
          trainingData.map((sample) async {
            final processedSample = Map<String, dynamic>.from(sample);
            // Normalize features
            for (var feature in _taskFeatures[_currentTaskType]!) {
              if (processedSample.containsKey(feature)) {
                processedSample[feature] = _normalizeFeature(
                    feature,
                    processedSample[feature].toDouble()
                );
              }
            }
            return processedSample;
          })
      );

      // Calculate feature ranges for future normalization
      await _calculateFeatureRanges();

      // Calculate initial metrics
      final metrics = await calculateMetrics(trainingData);
      _updateMetricsWithLimit(metrics);

      _modelState = KNNModelState.trained;
      _logger.info('KNN Model training completed with ${_trainingData.length} samples');

    } catch (e) {
      _modelState = KNNModelState.error;
      _logger.severe('Training error: $e');
      throw AIModelException('Model training failed: $e');
    }
  }


  @override
  Future<Map<String, dynamic>> getPredictionMetadata(Map<String, dynamic> input) async {
    return {
      'model_type': 'knn',
      'k_neighbors': _k,
      'training_size': _trainingData.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }


  @override
  Future<void> setup(List<Map<String, dynamic>> trainingData) async {
    try {
      await validateData(trainingData);
      _trainingData = trainingData;

      // Task-specific k değerlerini ayarla
      _kValues = {
        KNNTaskType.exerciseRecommendation: AIConstants.KNN_EXERCISE_K,
        KNNTaskType.userSimilarity: AIConstants.KNN_USER_K,
        KNNTaskType.fitnessLevelClassification: AIConstants.KNN_FITNESS_K,
      };

      _taskFeatures = Map.from(defaultFeatures);

      // Feature ranges'i hesapla
      await _calculateFeatureRanges();

      _logger.info('KNN Model setup completed with ${_trainingData.length} samples');
    } catch (e) {
      _logger.severe('Setup error: $e');
      throw AIModelException('Model setup failed: $e');
    }
  }

  @override
  Future<void> validateData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      throw AIModelException('Empty training data');
    }

    for (var entry in data) {
      for (var taskType in KNNTaskType.values) {
        for (var feature in defaultFeatures[taskType]!) {
          if (!entry.containsKey(feature)) {
            throw AIModelException(
                'Missing required feature: $feature for task ${taskType.toString()}',
                code: AIConstants.ERROR_INVALID_INPUT
            );
          }
        }
      }
    }
  }

  Future<void> _calculateFeatureRanges() async {
    for (var taskType in KNNTaskType.values) {
      for (var feature in _taskFeatures[taskType]!) {
        var values = _trainingData.map((e) => e[feature] as num).toList();
        _featureRanges[feature] = {
          'min': values.reduce((a, b) => a < b ? a : b).toDouble(),
          'max': values.reduce((a, b) => a > b ? a : b).toDouble()
        };
      }
    }
  }

  double _normalizeFeature(String feature, double value) {
    var range = _featureRanges[feature]!;
    return _dataProcessor.normalize(value, range['min']!, range['max']!);
  }

  double _calculateDistance(
      Map<String, dynamic> point1,
      Map<String, dynamic> point2,
      List<String> features
      ) {
    double sum = 0.0;

    for (var feature in features) {
      var value1 = _normalizeFeature(feature, point1[feature]);
      var value2 = _normalizeFeature(feature, point2[feature]);
      sum += pow(value1 - value2, 2);
    }

    return sqrt(sum);
  }

  List<Map<String, dynamic>> _findNearestNeighbors(
      Map<String, dynamic> input,
      KNNTaskType taskType
      ) {
    var distances = _trainingData.map((dataPoint) {
      return {
        'point': dataPoint,
        'distance': _calculateDistance(
            input,
            dataPoint,
            _taskFeatures[taskType]!
        )
      };
    }).toList();

    distances.sort((a, b) =>
        (a['distance'] as double).compareTo(b['distance'] as double));

    return distances
        .take(_kValues[taskType]!)
        .map((e) => e['point'] as Map<String, dynamic>)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> inference(Map<String, dynamic> input) async {
    try {
      if (!input.containsKey('task_type')) {
        throw AIModelException('Task type must be specified');
      }

      final taskType = KNNTaskType.values.firstWhere(
              (e) => e.toString() == input['task_type'],
          orElse: () => throw AIModelException('Invalid task type')
      );

      final neighbors = _findNearestNeighbors(input, taskType);

      switch (taskType) {
        case KNNTaskType.exerciseRecommendation:
          return await _generateExerciseRecommendations(neighbors);

        case KNNTaskType.userSimilarity:
          return await _findSimilarUsers(neighbors);

        case KNNTaskType.fitnessLevelClassification:
          return await _classifyFitnessLevel(neighbors);

        default:
          throw AIModelException('Unsupported task type');
      }
    } catch (e) {
      _logger.severe('Inference error: $e');
      throw AIModelException('Prediction failed: $e');
    }
  }

  Future<Map<String, dynamic>> _generateExerciseRecommendations(
      List<Map<String, dynamic>> neighbors
      ) async {
    // Egzersiz önerilerini oluştur
    var recommendations = <Map<String, dynamic>>[];
    // ... implementasyon
    return {'recommendations': recommendations};
  }

  Future<Map<String, dynamic>> _findSimilarUsers(
      List<Map<String, dynamic>> neighbors
      ) async {
    // Benzer kullanıcıları bul
    var similarUsers = <Map<String, dynamic>>[];
    // ... implementasyon
    return {'similar_users': similarUsers};
  }

  Future<Map<String, dynamic>> _classifyFitnessLevel(
      List<Map<String, dynamic>> neighbors
      ) async {
    // Fitness seviyesini sınıflandır
    var fitnessLevels = neighbors.map((n) => n['fitness_level']).toList();
    // ... implementasyon
    return {'fitness_level': 0}; // örnek dönüş
  }



}