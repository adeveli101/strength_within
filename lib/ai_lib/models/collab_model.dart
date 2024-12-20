import 'dart:async';
import 'dart:math' as math;
import '../ai_data_bloc/dataset_provider.dart';
import '../core/ai_constants.dart';
import '../core/ai_data_processor.dart';
import '../core/ai_exceptions.dart';

/// Collaborative Filtering Model
class CollaborativeModel {
  // Stream controller
  final StreamController<Map<String, double>> _metricsController =
  StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get metricsStream => _metricsController.stream;

  // Singleton pattern
  static final CollaborativeModel _instance = CollaborativeModel._internal();
  factory CollaborativeModel() => _instance;
  CollaborativeModel._internal();

  // Data handlers
  final AIDataProcessor _dataProcessor = AIDataProcessor();
  final DatasetDBProvider _datasetProvider = DatasetDBProvider();

  // Model parametreleri
  late List<List<double>> _userItemMatrix;
  late List<List<double>> _similarityMatrix;
  bool _isInitialized = false;
  bool _isTrained = false;

  // Model metrikleri
  final Map<String, double> _metrics = {
    'accuracy': 0.0,
    'precision': 0.0,
    'recall': 0.0,
    'f1_score': 0.0,
  };

  /// Modeli initialize eder
  Future<void> initialize(int userCount, int itemCount) async {
    try {
      final bmiData = await _datasetProvider.getBMIDataset();
      final exerciseData = await _datasetProvider.getExerciseTrackingData();

      userCount = bmiData.length;
      itemCount = exerciseData.where((e) => e['Workout_Type'] != null).toSet().length;

      _userItemMatrix = List.generate(
        userCount,
            (_) => List.filled(itemCount, 0.0),
      );

      _similarityMatrix = List.generate(
        userCount,
            (_) => List.filled(userCount, 0.0),
      );

      await _initializeUserItemMatrix();
      _isInitialized = true;

      // Metrikleri güncelle
      _metricsController.add(_metrics);
    } catch (e) {
      throw AITrainingException(
        'Model initialization failed: $e',
        code: AIConstants.ERROR_TRAINING_FAILED,
      );
    }
  }

  Future<void> _initializeUserItemMatrix() async {
    final exerciseData = await _datasetProvider.getExerciseTrackingData();
    final processedData = await _dataProcessor.processTrainingData(exerciseData); // Eksik kullanım

    for (var data in processedData) {
      final userId = data['userId'] as int;
      final programId = data['Workout_Type'] as String;
      final rating = _calculateInitialRating(data);
      await updateUserItemMatrix(userId, _getProgramIndex(programId), rating);
    }
    _isTrained = true;
  }


  int _getProgramIndex(String workoutType) {
    final types = ['cardio', 'strength', 'hiit', 'yoga'];
    return types.indexOf(workoutType.toLowerCase());
  }

  double _calculateInitialRating(Map<String, dynamic> data) {
    final duration = data['Session_Duration (hours)'] as double;
    final calories = data['Calories_Burned'] as double;
    final frequency = data['Workout_Frequency (days/week)'] as int;
    return (duration * calories * frequency) / 100;
  }

  Future<void> updateUserItemMatrix(int userId, int itemId, double rating) async {
    if (!_isInitialized) {
      throw AITrainingException(
        'Model is not initialized',
        code: AIConstants.ERROR_TRAINING_FAILED,
      );
    }
    _userItemMatrix[userId][itemId] = rating;
  }

  Future<void> calculateSimilarityMatrix() async {
    for (int i = 0; i < _userItemMatrix.length; i++) {
      for (int j = i + 1; j < _userItemMatrix.length; j++) {
        double similarity = _calculateCosineSimilarity(
          _userItemMatrix[i],
          _userItemMatrix[j],
        );
        _similarityMatrix[i][j] = similarity;
        _similarityMatrix[j][i] = similarity;
      }
    }

    // Metrikleri güncelle
    await _updateMetrics();
  }

  double _calculateCosineSimilarity(List<double> user1, List<double> user2) {
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < user1.length; i++) {
      dotProduct += user1[i] * user2[i];
      norm1 += user1[i] * user1[i];
      norm2 += user2[i] * user2[i];
    }

    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
    return dotProduct / (math.sqrt(norm1) * math.sqrt(norm2));
  }

  Future<List<int>> recommendPrograms(int userId, int numberOfRecommendations) async {
    if (!_isTrained) {
      throw AIPredictionException(
        'Model is not trained',
        code: AIConstants.ERROR_PREDICTION_FAILED,
      );
    }

    try {
      await calculateSimilarityMatrix();
      final predictions = List<double>.filled(_userItemMatrix[0].length, 0.0);
      double totalSimilarity = 0.0;

      for (int j = 0; j < _userItemMatrix.length; j++) {
        if (j != userId) {
          double similarity = _similarityMatrix[userId][j];
          totalSimilarity += similarity.abs();

          for (int k = 0; k < _userItemMatrix[j].length; k++) {
            predictions[k] += similarity * _userItemMatrix[j][k];
          }
        }
      }

      if (totalSimilarity != 0) {
        for (int i = 0; i < predictions.length; i++) {
          predictions[i] /= totalSimilarity;
        }
      }

      return _getTopNIndices(predictions, numberOfRecommendations);
    } catch (e) {
      throw AIPredictionException(
        'Recommendation failed: $e',
        code: AIConstants.ERROR_PREDICTION_FAILED,
      );
    }
  }

  List<int> _getTopNIndices(List<double> list, int n) {
    final indexed = list.asMap().entries.toList();
    indexed.sort((a, b) => b.value.compareTo(a.value));
    return indexed.take(n).map((e) => e.key).toList();
  }

  Future<void> _updateMetrics() async {
    // Metrik hesaplama mantığı
    _metrics['accuracy'] = _calculateAccuracy();
    _metrics['precision'] = _calculatePrecision();
    _metrics['recall'] = _calculateRecall();
    _metrics['f1_score'] = _calculateF1Score();

    _metricsController.add(_metrics);
  }

  double _calculateAccuracy() {
    // Accuracy hesaplama mantığı
    return 0.0; // Placeholder
  }

  double _calculatePrecision() {
    // Precision hesaplama mantığı
    return 0.0; // Placeholder
  }

  double _calculateRecall() {
    // Recall hesaplama mantığı
    return 0.0; // Placeholder
  }

  double _calculateF1Score() {
    // F1 Score hesaplama mantığı
    return 0.0; // Placeholder
  }

  void dispose() {
    _metricsController.close();
  }
}
