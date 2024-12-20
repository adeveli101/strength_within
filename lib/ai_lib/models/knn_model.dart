import 'dart:math' show max, sqrt, pow;
import 'package:logging/logging.dart';
import '../ai_data_bloc/ai_repository.dart';
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


  // _performanceHistory'de eksik olabilecek metrikleri ekleyelim
  final Map<String, List<double>> _performanceHistory = {
    'inference_time': [],
    'similarity_calculation_time': [],
    'recommendation_generation_time': [],
    'fit_analysis_time': [],      // Eklendi
    'progress_analysis_time': [],  // Eklendi
  };

  @override
  Future<Map<String, dynamic>> analyzeFit(
      int programId,
      UserProfile profile
      ) async {


    try {

      if (_modelState != KNNModelState.trained) {
        throw AIModelException('Model is not trained for analysis');
      }
      final startTime = DateTime.now();
      // Performans izleme için

      // Program ve kullanıcı özelliklerini birleştir
      final inputData = {
        ...profile.toMap(),
        'program_id': programId,
        'task_type': KNNTaskType.exerciseRecommendation.toString(),
      };

      // En yakın komşuları bul
      final neighbors = _findNearestNeighbors(
        inputData,
        KNNTaskType.exerciseRecommendation,
      );

      // Success probability hesapla
      final successProb = _calculateSuccessProbability(neighbors, programId);

      // Kalori tahmini yap
      final expectedCalories = _estimateCaloriesBurn(neighbors, profile);

      // Önerilen frekansı belirle
      final frequency = _determineWorkoutFrequency(neighbors);

      // Yoğunluk ayarlamalarını hesapla
      final intensityAdj = _calculateIntensityAdjustments(neighbors, profile);

      return {
        'success_probability': successProb,
        'expected_calories': expectedCalories,
        'recommended_frequency': frequency,
        'intensity_adjustment': intensityAdj,
      };
    } catch (e) {
      _logger.severe('KNN fit analysis failed: $e');
      throw AIModelException('Fit analysis failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeProgress(
      List<Map<String, dynamic>> userData
      ) async {
    try {
      if (_modelState != KNNModelState.trained) {
        throw AIModelException('Model is not trained for analysis');
      }

      setTaskType(KNNTaskType.fitnessLevelClassification);

      // Son verileri analiz et
      final recentData = userData.take(10).toList();

      // Benzer ilerleme gösteren kullanıcıları bul
      final similarProgressUsers = _findProgressPatterns(recentData);

      // Performans metriklerini hesapla
      final performanceScore = _calculatePerformanceScore(recentData, similarProgressUsers);

      // Yoğunluk seviyesini belirle
      final intensityLevel = _determineIntensityLevel(recentData);

      // Önerileri oluştur
      final recommendations = _generateProgressRecommendations(
          recentData,
          similarProgressUsers,
          performanceScore
      );

      return {
        'intensity_level': intensityLevel,
        'performance_score': performanceScore,
        'recommendations': recommendations,
      };
    } catch (e) {
      _logger.severe('KNN progress analysis failed: $e');
      throw AIModelException('Progress analysis failed: $e');
    }
  }

  // Yardımcı metodlar
  double _calculateSuccessProbability(
      List<Map<String, dynamic>> neighbors,
      int programId
      ) {
    var successfulNeighbors = neighbors.where((n) =>
    n['program_id'] == programId &&
        (n['success_rate'] ?? 0.0) > 0.7
    ).length;

    return successfulNeighbors / neighbors.length;
  }

  double _estimateCaloriesBurn(
      List<Map<String, dynamic>> neighbors,
      UserProfile profile
      ) {
    var totalCalories = 0.0;
    var totalWeight = 0.0;

    for (var neighbor in neighbors) {
      final distance = _calculateDistance(
          neighbor,
          profile.toMap(),
          defaultFeatures[KNNTaskType.userSimilarity]!
      );
      final weight = 1.0 / (distance + 1e-6); // Avoid division by zero

      totalCalories += (neighbor['calories_burned'] ?? 300.0) * weight;
      totalWeight += weight;
    }

    return totalCalories / totalWeight;
  }

  int _determineWorkoutFrequency(List<Map<String, dynamic>> neighbors) {
    var frequencies = neighbors
        .map((n) => n['workout_frequency'] as int? ?? 3)
        .toList()
      ..sort();

    // Medyan frekansı döndür
    return frequencies[frequencies.length ~/ 2];
  }

  Map<String, double> _calculateIntensityAdjustments(
      List<Map<String, dynamic>> neighbors,
      UserProfile profile
      ) {
    var adjustments = {
      'cardio': 0.0,
      'strength': 0.0,
      'flexibility': 0.0
    };

    var totalWeights = 0.0;

    for (var neighbor in neighbors) {
      final distance = _calculateDistance(
          neighbor,
          profile.toMap(),
          defaultFeatures[KNNTaskType.userSimilarity]!
      );
      final weight = 1.0 / (distance + 1e-6);

      adjustments.forEach((key, value) {
        adjustments[key] = value +
            (neighbor['${key}_intensity'] ?? 1.0) * weight;
      });

      totalWeights += weight;
    }

    // Normalize adjustments
    adjustments.forEach((key, value) {
      adjustments[key] = value / totalWeights;
    });

    return adjustments;
  }

  List<Map<String, dynamic>> _findProgressPatterns(
      List<Map<String, dynamic>> recentData
      ) {
    return _trainingData
        .where((data) => _isProgressPatternSimilar(data, recentData))
        .take(_k)
        .toList();
  }

  bool _isProgressPatternSimilar(
      Map<String, dynamic> data,
      List<Map<String, dynamic>> recentData
      ) {
    // Progress pattern similarity logic
    final patternFeatures = [
      'exercise_frequency',
      'workout_intensity',
      'endurance_score',
      'strength_score'
    ];

    var similarityScore = 0.0;
    for (var feature in patternFeatures) {
      final dataValue = data[feature] as double? ?? 0.0;
      final recentAvg = recentData
          .map((d) => d[feature] as double? ?? 0.0)
          .reduce((a, b) => a + b) / recentData.length;

      similarityScore += pow(dataValue - recentAvg, 2);
    }

    return sqrt(similarityScore) < AIConstants.SIMILARITY_THRESHOLD;
  }

  double _calculatePerformanceScore(
      List<Map<String, dynamic>> recentData,
      List<Map<String, dynamic>> similarUsers
      ) {
    // Performance metrics calculation
    final currentMetrics = _calculateCurrentMetrics(recentData);
    final expectedMetrics = _calculateExpectedMetrics(similarUsers);

    return _compareMetrics(currentMetrics, expectedMetrics);
  }

  String _determineIntensityLevel(List<Map<String, dynamic>> recentData) {
    final avgIntensity = recentData
        .map((d) => d['workout_intensity'] as double? ?? 0.0)
        .reduce((a, b) => a + b) / recentData.length;

    if (avgIntensity > 0.8) return 'high';
    if (avgIntensity > 0.5) return 'medium';
    return 'low';
  }

  List<String> _generateProgressRecommendations(
      List<Map<String, dynamic>> recentData,
      List<Map<String, dynamic>> similarUsers,
      double performanceScore
      ) {
    final recommendations = <String>[];

    if (performanceScore < 0.3) {
      recommendations.addAll([
        'Consider reducing workout intensity',
        'Focus on proper form and technique',
        'Increase rest periods between exercises'
      ]);
    } else if (performanceScore < 0.7) {
      recommendations.addAll([
        'Maintain current progress',
        'Gradually increase weights or repetitions',
        'Add variety to your routine'
      ]);
    } else {
      recommendations.addAll([
        'Consider increasing workout intensity',
        'Try more advanced exercise variations',
        'Add complex movement patterns'
      ]);
    }

    return recommendations;
  }

  Map<String, double> _calculateCurrentMetrics(
      List<Map<String, dynamic>> recentData
      ) {
    return {
      'avg_intensity': recentData
          .map((d) => d['workout_intensity'] as double? ?? 0.0)
          .reduce((a, b) => a + b) / recentData.length,
      // _calculateConsistency yerine _calculateF1Score kullan
      'consistency': _calculateF1Score(
          recentData,
          recentData.map((d) => {'label': d['target']}).toList()
      ),
      // _calculateProgressRate yerine performans metriklerinin ortalamasını kullan
      'progress_rate': _calculatePerformanceRate(recentData)
    };
  }

  // Yeni eklenen metod
  double _calculatePerformanceRate(List<Map<String, dynamic>> data) {
    if (data.length < 2) return 0.0;

    var improvements = 0.0;
    for (var i = 1; i < data.length; i++) {
      final current = data[i]['performance_score'] as double? ?? 0.0;
      final previous = data[i-1]['performance_score'] as double? ?? 0.0;
      improvements += (current - previous);
    }

    return improvements / (data.length - 1);
  }

  // Mevcut precision ve recall metodlarını kullanarak tutarlılığı hesapla
  double _calculateOverallConsistency(List<Map<String, dynamic>> data) {
    final predictions = data.map((d) => {
      'prediction': d['actual_performance'],
      'label': d['target_performance']
    }).toList();

    final precision = _calculatePrecision(predictions, data);
    final recall = _calculateRecall(predictions, data);

    // F1 skoru tutarlılık ölçüsü olarak kullan
    return (2 * precision * recall) / (precision + recall);
  }



  Map<String, double> _calculateExpectedMetrics(
      List<Map<String, dynamic>> similarUsers
      ) {
    return {
      'avg_intensity': similarUsers
          .map((u) => u['workout_intensity'] as double? ?? 0.0)
          .reduce((a, b) => a + b) / similarUsers.length,
      'consistency': similarUsers
          .map((u) => u['consistency'] as double? ?? 0.0)
          .reduce((a, b) => a + b) / similarUsers.length,
      'progress_rate': similarUsers
          .map((u) => u['progress_rate'] as double? ?? 0.0)
          .reduce((a, b) => a + b) / similarUsers.length
    };
  }

  double _compareMetrics(
      Map<String, double> current,
      Map<String, double> expected
      ) {
    var totalScore = 0.0;
    current.forEach((key, value) {
      totalScore += value / (expected[key] ?? 1.0);
    });
    return totalScore / current.length;
  }




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