import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import '../core/ai_constants.dart';
import '../core/ai_data_processor.dart';
import '../core/ai_exceptions.dart';
import '../ai_data_bloc/dataset_provider.dart';

class _Prediction {
  final int predicted;
  final int actual;

  _Prediction(this.predicted, this.actual);
}


/// K-Nearest Neighbors Model
class KNNModel {
  // Stream controller
  final StreamController<Map<String, double>> _metricsController =
  StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get metricsStream => _metricsController.stream;

  // Singleton pattern
  static final KNNModel _instance = KNNModel._internal();
  factory KNNModel() => _instance;
  KNNModel._internal();

  // Data handlers
  final AIDataProcessor _dataProcessor = AIDataProcessor();
  final DatasetDBProvider _datasetProvider = DatasetDBProvider();

  // Model verileri
  late List<Map<String, dynamic>> _userData;
  late List<List<double>> _similarityMatrix;
  // ignore: unused_field
  late Map<String, List<double>> _featureRanges;

  // Model durumu
  bool _isInitialized = false;
  bool _isTrained = false;

  final List<_Prediction> _predictions = [];
  final int _truePositives = 0;
  final int _falsePositives = 0;
  final int _falseNegatives = 0;

  // Model metrikleri
  final Map<String, double> _metrics = {
    'accuracy': 0.0,
    'precision': 0.0,
    'recall': 0.0,
    'f1_score': 0.0,
  };

  /// Modeli initialize eder
  Future<void> initialize(List<Map<String, dynamic>> userData) async {
    try {
      final exerciseData = await _datasetProvider.getExerciseTrackingData();
      final processedData = await _dataProcessor.processTrainingData(exerciseData);
      _featureRanges = await _datasetProvider.getFeatureRanges();

      _userData = processedData;
      _similarityMatrix = List.generate(
          processedData.length,
              (_) => List.filled(processedData.length, 0.0)
      );

      _isInitialized = true;
      _metricsController.add(_metrics);
    } catch (e) {
      throw AITrainingException(
        'Model initialization failed: $e',
        code: AIConstants.ERROR_TRAINING_FAILED,
      );
    }
  }

  /// Kullanıcı benzerliklerini hesaplar
  Future<void> calculateSimilarities() async {
    if (!_isInitialized) {
      throw AITrainingException('Model is not initialized');
    }

    try {
      for (int i = 0; i < _userData.length; i++) {
        for (int j = i + 1; j < _userData.length; j++) {
          double similarity = await _calculateUserSimilarity(_userData[i], _userData[j]);
          _similarityMatrix[i][j] = similarity;
          _similarityMatrix[j][i] = similarity;
        }
      }

      _isTrained = true;
      await _updateMetrics();
    } catch (e) {
      throw AITrainingException('Similarity calculation failed: $e');
    }
  }

  /// İki kullanıcı arasındaki benzerliği hesaplar
  Future<double> _calculateUserSimilarity(
      Map<String, dynamic> user1,
      Map<String, dynamic> user2
      ) async {
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    final numericFeatures = [
      'weight_normalized', 'height_normalized', 'bmi_normalized',
      'bfp_normalized', 'age_normalized'
    ];

    for (var feature in numericFeatures) {
      final val1 = user1['features'][feature] as double;
      final val2 = user2['features'][feature] as double;
      dotProduct += val1 * val2;
      norm1 += val1 * val1;
      norm2 += val2 * val2;
    }

    final categoricalFeatures = [
      'gender_male', 'gender_female',
      'workout_cardio', 'workout_strength', 'workout_hiit', 'workout_yoga',
      'experience_beginner', 'experience_intermediate', 'experience_advanced'
    ];

    for (var feature in categoricalFeatures) {
      final val1 = user1['features'][feature] as double;
      final val2 = user2['features'][feature] as double;
      if (val1 == val2) dotProduct += 1;
      norm1 += val1;
      norm2 += val2;
    }

    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }


  /// Program önerisi yapar
  Future<List<int>> recommend(int userId, int k) async {
    if (!_isTrained) {
      throw AIPredictionException('Model is not trained');
    }

    try {
      final similarities = _similarityMatrix[userId];
      var sortedIndices = List.generate(similarities.length, (index) => index)
        ..sort((a, b) => similarities[b].compareTo(similarities[a]));

      final nearestNeighbors = sortedIndices.take(k).toList();
      final programPreferences = <int, double>{};

      for (var neighborId in nearestNeighbors) {
        final neighbor = _userData[neighborId];
        final similarity = similarities[neighborId];
        final programs = neighbor['programs'] as List<int>;

        for (var program in programs) {
          programPreferences[program] =
              (programPreferences[program] ?? 0) + similarity;
        }
      }

      return programPreferences.entries
          .toList()
          .sorted((a, b) => b.value.compareTo(a.value))
          .map((e) => e.key)
          .take(AIConstants.KNN_NEIGHBORS_COUNT)
          .toList();

    } catch (e) {
      throw AIPredictionException(
          'Recommendation failed: $e',
          code: AIConstants.ERROR_PREDICTION_FAILED
      );
    }
  }

  Future<void> _updateMetrics() async {
    try {
      // Metrik hesaplama
      _metrics['accuracy'] = _calculateAccuracy();
      _metrics['precision'] = _calculatePrecision();
      _metrics['recall'] = _calculateRecall();
      _metrics['f1_score'] = _calculateF1Score();

      _metricsController.add(_metrics);
    } catch (e) {
      throw AIException('Metric calculation failed: $e');
    }
  }

  double _calculateAccuracy() {
    if (_predictions.isEmpty) return 0.0;
    int correctPredictions = _predictions.where((p) => p.predicted == p.actual).length;
    return correctPredictions / _predictions.length;
  }

  double _calculatePrecision() {
    if (_truePositives + _falsePositives == 0) return 0.0;
    return _truePositives / (_truePositives + _falsePositives);
  }

  double _calculateRecall() {
    if (_truePositives + _falseNegatives == 0) return 0.0;
    return _truePositives / (_truePositives + _falseNegatives);
  }

  double _calculateF1Score() {
    final precision = _calculatePrecision();
    final recall = _calculateRecall();
    if (precision + recall == 0) return 0.0;
    return 2 * (precision * recall) / (precision + recall);
  }

  void dispose() {
    _metricsController.close();
  }
}
