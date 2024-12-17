// ignore_for_file: unused_field

import 'dart:math';
import '../core/ai_constants.dart';
import '../core/ai_data_processor.dart';
import '../core/ai_exceptions.dart';


/// K-Nearest Neighbors Model
class KNNModel {
  // Singleton pattern
  static final KNNModel _instance = KNNModel._internal();
  factory KNNModel() => _instance;
  KNNModel._internal();

  final AIDataProcessor _dataProcessor = AIDataProcessor();

  // Kullanıcı verileri ve benzerlik matrisleri
  late List<Map<String, dynamic>> _userData;
  late List<List<double>> _similarityMatrix;

  /// Model durumu
  bool _isInitialized = false;

  /// Modeli initialize eder
  Future<void> initialize(List<Map<String, dynamic>> userData) async {
    try {
      _userData = userData;
      _similarityMatrix = List.generate(userData.length, (_) => List.filled(userData.length, 0.0));
      _isInitialized = true;
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

    for (int i = 0; i < _userData.length; i++) {
      for (int j = i + 1; j < _userData.length; j++) {
        double similarity = _calculateCosineSimilarity(_userData[i], _userData[j]);
        _similarityMatrix[i][j] = similarity;
        _similarityMatrix[j][i] = similarity; // Symmetric matrix
      }
    }
  }

  /// Kosinüs benzerliği hesaplar
  double _calculateCosineSimilarity(Map<String, dynamic> user1, Map<String, dynamic> user2) {
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    // Kullanıcı özelliklerini al
    final features1 = user1['features'] as List<double>;
    final features2 = user2['features'] as List<double>;

    for (int i = 0; i < features1.length; i++) {
      dotProduct += features1[i] * features2[i];
      norm1 += features1[i] * features1[i];
      norm2 += features2[i] * features2[i];
    }

    if (norm1 == 0.0 || norm2 == 0.0) return 0.0; // Zero vector check
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  /// Öneri yapar
  Future<List<int>> recommend(int userId, int k) async {
    if (!_isInitialized) {
      throw AIPredictionException('Model is not initialized');
    }

    await calculateSimilarities();

    // Kullanıcının benzerliklerini al
    final similarities = _similarityMatrix[userId];

    // En yüksek k benzer kullanıcıyı bul
    List<int> nearestNeighbors = [];
    var sortedIndices = List.generate(similarities.length, (index) => index)
      ..sort((a, b) => similarities[b].compareTo(similarities[a]));

    nearestNeighbors = sortedIndices.take(k).toList();

    // Öneri oluşturma mantığı burada uygulanabilir.

    // Öneri olarak en çok beğenilen programları döndürme
    return nearestNeighbors; // Bu örnekte sadece komşuları döndürüyoruz.
  }
}
