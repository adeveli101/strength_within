// ignore_for_file: unused_field

import 'dart:math' as math;
import '../core/ai_constants.dart';
import '../core/ai_data_processor.dart';
import '../core/ai_exceptions.dart';

/// Collaborative Filtering Model
class CollaborativeModel {
  // Singleton pattern
  static final CollaborativeModel _instance = CollaborativeModel._internal();
  factory CollaborativeModel() => _instance;
  CollaborativeModel._internal();

  final AIDataProcessor _dataProcessor = AIDataProcessor();

  // Model parametreleri
  late List<List<double>> _userItemMatrix;
  late List<List<double>> _similarityMatrix;
  bool _isInitialized = false;
  final bool _isTrained = false;

  /// Model metrikleri
  final Map<String, double> _metrics = {
    'accuracy': 0.0,
    'precision': 0.0,
    'recall': 0.0,
    'f1_score': 0.0,
  };

  /// Modeli initialize eder
  Future<void> initialize(int userCount, int itemCount) async {
    try {
      _userItemMatrix = List.generate(
        userCount,
            (_) => List.filled(itemCount, 0.0),
      );

      _similarityMatrix = List.generate(
        userCount,
            (_) => List.filled(userCount, 0.0),
      );

      _isInitialized = true;
    } catch (e) {
      throw AITrainingException(
        'Model initialization failed: $e',
        code: AIConstants.ERROR_TRAINING_FAILED,
      );
    }
  }

  /// Kullanıcı-program matrisini günceller
  Future<void> updateUserItemMatrix(
      int userId,
      int itemId,
      double rating,
      ) async {
    if (!_isInitialized) {
      throw AITrainingException(
        'Model is not initialized',
        code: AIConstants.ERROR_TRAINING_FAILED,
      );
    }
    _userItemMatrix[userId][itemId] = rating;
  }

  /// Kullanıcı benzerlik matrisini hesaplar
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
  }

  /// Kosinüs benzerliği hesaplar
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

  /// Program önerisi yapar
  Future<List<int>> recommendPrograms(
      int userId,
      int numberOfRecommendations,
      ) async {
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

      // Normalize predictions
      if (totalSimilarity != 0) {
        for (int i = 0; i < predictions.length; i++) {
          predictions[i] /= totalSimilarity;
        }
      }

      // Get top N recommendations
      return _getTopNIndices(predictions, numberOfRecommendations);
    } catch (e) {
      throw AIPredictionException(
        'Recommendation failed: $e',
        code: AIConstants.ERROR_PREDICTION_FAILED,
      );
    }
  }

  /// En yüksek N değere sahip indeksleri döndürür
  List<int> _getTopNIndices(List<double> list, int n) {
    final indexed = list.asMap().entries.toList();
    indexed.sort((a, b) => b.value.compareTo(a.value));
    return indexed.take(n).map((e) => e.key).toList();
  }




}
