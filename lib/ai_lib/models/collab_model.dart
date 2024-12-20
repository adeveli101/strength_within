import 'dart:math' show pow, sqrt;
import 'package:logging/logging.dart';
import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import '../core/ai_data_processor.dart';
import 'base_model.dart';

enum CollabModelState {
  uninitialized,
  initializing, // Doğru sıralama
  initialized,
  training,
  trained,
  predicting,
  error
}

class CollaborativeFilteringModel extends BaseModel {
  final _logger = Logger('CollaborativeFilteringModel');
  final _dataProcessor = AIDataProcessor();




  // Model durumu için değişken
  CollabModelState _modelState = CollabModelState.uninitialized;

  // Getter for model state
  CollabModelState get modelState => _modelState;

  // Model için özel normalizasyon değerleri
  static const _modelNormalizationRanges = {
    'rating': {'min': 1.0, 'max': 5.0},
    'similarity': {'min': -1.0, 'max': 1.0},
    'confidence': {'min': 0.0, 'max': 1.0}
  };

  // User-item matrisi ve similarity matrisi
  late Map<String, Map<String, double>> _userItemRatings;
  late Map<String, Map<String, double>> _userSimilarities;

  static const int MAX_PERFORMANCE_HISTORY = 1000;

  void _trackPerformance(String metric, double value) {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      if (!_performanceHistory.containsKey(metric)) {
        _performanceHistory[metric] = [];
      }

      _performanceHistory[metric]?.add(value);

      if ((_performanceHistory[metric]?.length ?? 0) > MAX_PERFORMANCE_HISTORY) {
        _performanceHistory[metric]?.removeAt(0);
      }

      final avgValue = _performanceHistory[metric]
          ?.reduce((a, b) => a + b) ?? 0.0 / (_performanceHistory[metric]?.length ?? 1);

      _logger.fine('Performance metric tracked: $metric = $value (avg: $avgValue) at $now');
    } catch (e) {
      _logger.warning('Error tracking performance metric: $e');
    }
  }

  @override
  Future<double> calculateConfidence(Map<String, dynamic> input, dynamic prediction) async {
    try {
      final userId = input['user_id'].toString();
      final similarUsers = await _findSimilarUsers(userId, _userItemRatings, AIConstants.KNN_NEIGHBORS_COUNT);

      // Benzerlik skorlarının ortalamasını güven skoru olarak kullan
      if (similarUsers.isEmpty) return 0.0;

      double totalSimilarity = similarUsers.fold(0.0,
              (sum, user) => sum + (user['similarity'] as double));

      return totalSimilarity / similarUsers.length;
    } catch (e) {
      _logger.warning('Confidence calculation failed: $e');
      return 0.0;
    }
  }

  @override
  Future<Map<String, dynamic>> getPredictionMetadata(Map<String, dynamic> input) async {
    return {
      'model_type': 'collaborative_filtering',
      'timestamp': DateTime.now().toIso8601String(),
      'user_count': _userItemRatings.length,
      'similarity_metric': 'pearson_correlation',
      'k_neighbors': AIConstants.KNN_NEIGHBORS_COUNT,
    };
  }

  @override
  Future<void> validateData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      throw AIModelException('Empty training data');
    }

    for (var entry in data) {
      if (!entry.containsKey('user_id') ||
          !entry.containsKey('exercise_id') ||
          !entry.containsKey('rating')) {
        throw AIModelException(
            'Invalid data format: Required fields missing',
            code: AIConstants.ERROR_INVALID_INPUT
        );
      }

      // Rating değeri kontrolü
      final rating = entry['rating'];
      if (rating == null ||
          rating < _modelNormalizationRanges['rating']!['min']! ||
          rating > _modelNormalizationRanges['rating']!['max']!) {
        throw AIModelException(
            'Invalid rating value: $rating',
            code: AIConstants.ERROR_INVALID_INPUT
        );
      }
    }
  }




  @override
  Future<void> setup(List<Map<String, dynamic>> trainingData) async {
    try {
      _modelState = CollabModelState.initializing;
      await validateData(trainingData);

      _userItemRatings = {};
      _userSimilarities = {};

      for (var data in trainingData) {
        final userId = data['user_id'].toString();
        final itemId = data['exercise_id'].toString();
        final rating = data['rating'].toDouble();

        if (rating.isNaN) {
          _logger.warning('Invalid rating for user $userId, item $itemId');
          continue;
        }

        _userItemRatings[userId] ??= {};
        _userItemRatings[userId]![itemId] = _normalizeRating(rating);
      }

      _modelState = CollabModelState.initialized; // Eksik durum güncellemesi eklendi
      _logger.info('Model setup completed with ${_userItemRatings.length} users');
    } catch (e) {
      _modelState = CollabModelState.error;
      _logger.severe('Setup error: $e');
      throw AIModelException('Model setup failed: $e');
    }
  }

  @override
  Future<void> fit(List<Map<String, dynamic>> trainingData) async {
    try {
      // Önce durum kontrolü yap
      if (_modelState != CollabModelState.initialized) {
        throw AIModelException('Model must be initialized before training');
      }

      _modelState = CollabModelState.training;
      final startTime = DateTime.now();

      // User similarity matrisini hesapla
      for (var user1 in _userItemRatings.keys) {
        _userSimilarities[user1] ??= {};

        int processedUsers = 0;
        for (var user2 in _userItemRatings.keys) {
          if (user1 != user2) {
            final similarity = _calculatePearsonCorrelation(
                _userItemRatings[user1]!,
                _userItemRatings[user2]!
            );
            _userSimilarities[user1]![user2] = similarity;
            processedUsers++;
          }
        }

        _logger.fine('Processed similarities for user $user1: $processedUsers users');
      }

      // Metrikleri güncelle
      final metrics = await calculateMetrics(trainingData);
      updateMetrics(metrics);

      final duration = DateTime.now().difference(startTime);
      _trackPerformance('training_time', duration.inMilliseconds.toDouble());

      _modelState = CollabModelState.trained;
      _logger.info('Model training completed in ${duration.inSeconds} seconds');

    } catch (e) {
      _modelState = CollabModelState.error;
      _logger.severe('Training error: $e');
      throw AIModelException('Model training failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> inference(Map<String, dynamic> input) async {
    try {
      // Önce durum kontrolü yap
      if (_modelState != CollabModelState.trained) {
        throw AIModelException('Model is not ready for inference');
      }

      _modelState = CollabModelState.predicting;
      final startTime = DateTime.now();

      final userId = input['user_id'].toString();
      final processedInput = await _preprocessInput(input);

      final similarUsers = await _findSimilarUsers(
          userId,
          _userItemRatings,
          AIConstants.KNN_NEIGHBORS_COUNT
      );

      final recommendations = await _generateRecommendations(
          userId,
          similarUsers,
          _userItemRatings
      );

      final result = {
        'recommendations': recommendations,
        'confidence_scores': recommendations.map((r) => r['confidence']).toList(),
        'similar_users': similarUsers.map((u) => u['userId']).toList(),
        'metadata': await getPredictionMetadata(input)
      };

      final duration = DateTime.now().difference(startTime);
      _trackPerformance('inference_time', duration.inMilliseconds.toDouble());

      _modelState = CollabModelState.trained;
      return result;

    } catch (e) {
      _modelState = CollabModelState.error;
      _logger.severe('Inference error: $e');
      throw AIModelException('Prediction failed: $e');
    }
  }


  Future<List<Map<String, dynamic>>> _generateRecommendations(
      String userId,
      List<Map<String, dynamic>> similarUsers,
      Map<String, Map<String, double>> userRatings) async {

    final recommendations = <String, double>{};
    final weights = <String, double>{};
    final userRated = userRatings[userId]?.keys.toSet() ?? {};

    // Her benzer kullanıcı için
    for (var simUser in similarUsers) {
      final simUserId = simUser['userId'] as String;
      final similarity = simUser['similarity'] as double;

      // Benzer kullanıcının değerlendirmeleri
      final simUserRatings = userRatings[simUserId] ?? {};

      for (var entry in simUserRatings.entries) {
        final itemId = entry.key;
        final rating = entry.value;

        // Kullanıcının henüz değerlendirmediği itemlar için
        if (!userRated.contains(itemId)) {
          recommendations[itemId] = (recommendations[itemId] ?? 0.0) +
              similarity * rating;
          weights[itemId] = (weights[itemId] ?? 0.0) + similarity.abs();
        }
      }
    }

    // Normalize et ve sonuçları formatla
    return recommendations.entries.map((entry) {
      final itemId = entry.key;
      final weight = weights[itemId] ?? 1.0;
      final normalizedScore = entry.value / weight;

      return {
        'exercise_id': itemId,
        'score': normalizedScore,
        'confidence': weight / similarUsers.length
      };
    }).toList()
      ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
  }

  // Private helper methods
  double _normalizeRating(double rating) {
    return _dataProcessor.normalize(
        rating,
        _modelNormalizationRanges['rating']!['min']!,
        _modelNormalizationRanges['rating']!['max']!
    );
  }

  double _calculatePearsonCorrelation(
      Map<String, double> ratings1,
      Map<String, double> ratings2) {
    final commonItems = ratings1.keys.toSet().intersection(ratings2.keys.toSet());

    if (commonItems.isEmpty) return 0.0;

    final avg1 = ratings1.values.reduce((a, b) => a + b) / ratings1.length;
    final avg2 = ratings2.values.reduce((a, b) => a + b) / ratings2.length;

    double numerator = 0.0;
    double denominator1 = 0.0;
    double denominator2 = 0.0;

    for (var item in commonItems) {
      final diff1 = ratings1[item]! - avg1;
      final diff2 = ratings2[item]! - avg2;

      numerator += diff1 * diff2;
      denominator1 += diff1 * diff1;
      denominator2 += diff2 * diff2;
    }

    if (denominator1 == 0.0 || denominator2 == 0.0) return 0.0;
    return numerator / (sqrt(denominator1) * sqrt(denominator2));
  }

  Future<List<Map<String, dynamic>>> _findSimilarUsers(
      String userId,
      Map<String, Map<String, double>> userRatings,
      int k) async {

    if (k <= 0) {
      throw AIModelException('k must be positive');
    }

    if (!userRatings.containsKey(userId)) {
      _logger.warning('User $userId not found in ratings');
      return [];
    }

    if (!_userSimilarities.containsKey(userId)) {
      _userSimilarities[userId] = {};
      final startTime = DateTime.now();

      for (var otherUser in userRatings.keys) {
        if (userId != otherUser) {
          _userSimilarities[userId]![otherUser] = _calculatePearsonCorrelation(
              userRatings[userId]!,
              userRatings[otherUser]!
          );
        }
      }

      final duration = DateTime.now().difference(startTime);
      _trackPerformance('similarity_calculation_time', duration.inMilliseconds.toDouble());
    }

    final similarities = _userSimilarities[userId]!
        .entries
        .map((e) => {
      'userId': e.key,
      'similarity': e.value
    })
        .toList();

    similarities.sort((a, b) =>
        (b['similarity'] as double).compareTo(a['similarity'] as double));

    return similarities.take(k).toList();
  }

  @override
  Future<Map<String, double>> calculateMetrics(
      List<Map<String, dynamic>> testData) async {
    double rmse = 0.0;
    double mae = 0.0;
    int count = 0;
    int totalPredictions = 0;

    for (var data in testData) {
      totalPredictions++;
      final userId = data['user_id'].toString();
      final itemId = data['exercise_id'].toString();
      final actualRating = data['rating'].toDouble();

      if (_userItemRatings.containsKey(userId)) {
        final similarUsers = await _findSimilarUsers(
            userId,
            _userItemRatings,
            AIConstants.KNN_NEIGHBORS_COUNT
        );

        final predictedRating = await _predictRating(
            userId,
            itemId,
            similarUsers,
            _userItemRatings
        );

        if (predictedRating != null) {
          rmse += pow(predictedRating - actualRating, 2);
          mae += (predictedRating - actualRating).abs();
          count++;
        }
      }
    }

    if (count == 0) {
      return {
      'rmse': 0.0,
      'mae': 0.0,
      'coverage': 0.0,
      'prediction_rate': 0.0
    };
    }

    return {
      'rmse': sqrt(rmse / count),
      'mae': mae / count,
      'coverage': count / testData.length,
      'prediction_rate': count / totalPredictions
    };
  }

  Future<double?> _predictRating(
      String userId,
      String itemId,
      List<Map<String, dynamic>> similarUsers,
      Map<String, Map<String, double>> userRatings) async {

    double weightedSum = 0.0;
    double similaritySum = 0.0;

    for (var simUser in similarUsers) {
      final simUserId = simUser['userId'] as String;
      final similarity = simUser['similarity'] as double;

      if (userRatings[simUserId]?.containsKey(itemId) ?? false) {
        final rating = userRatings[simUserId]![itemId]!;
        weightedSum += similarity * rating;
        similaritySum += similarity.abs();
      }
    }

    if (similaritySum == 0.0) return null;
    return weightedSum / similaritySum;
  }

  Future<void> clearCache() async {
    _userSimilarities.clear();
    _logger.info('Similarity cache cleared');
  }

  Future<void> clearUserCache(String userId) async {
    _userSimilarities.remove(userId);
    _logger.info('Cache cleared for user: $userId');
  }

  final Map<String, List<double>> _performanceHistory = {
    'inference_time': [],
    'similarity_calculation_time': [],
    'recommendation_generation_time': [],
  };




    Future<List<Map<String, dynamic>>> batchPredict(
        List<Map<String, dynamic>> inputs) async {
      final results = <Map<String, dynamic>>[];

      for (var input in inputs) {
        try {
          final prediction = await inference(input);
          results.add(prediction);
        } catch (e) {
          _logger.warning('Batch prediction failed for input: $input, error: $e');
          results.add({
            'error': e.toString(),
            'input': input,
          });
        }
      }

      return results;
    }

  @override
  Future<void> dispose() async {
    try {
      await super.dispose(); // Base class'ın dispose metodunu çağır
      await clearCache();
      _userItemRatings.clear();
      _performanceHistory.clear();
      _modelState = CollabModelState.uninitialized;
      _logger.info('Model resources released');
    } catch (e) {
      _logger.severe('Error during model disposal: $e');
      rethrow; // Hatayı yeniden fırlat
    }
  }



  Future<Map<String, dynamic>> _preprocessInput(Map<String, dynamic> input) async {
    try {
      final processedInput = Map<String, dynamic>.from(input);

      // Rating normalizasyonu
      if (input.containsKey('rating')) {
        processedInput['rating'] = _normalizeRating(input['rating']);
      }

      // User ID validasyonu
      if (!processedInput.containsKey('user_id')) {
        throw AIModelException(
            'Missing user_id in input',
            code: AIConstants.ERROR_INVALID_INPUT
        );
      }

      return processedInput;
    } catch (e) {
      _logger.severe('Input preprocessing failed: $e');
      throw AIModelException('Input preprocessing failed: $e');
    }
  }

  Future<void> updateModel(List<Map<String, dynamic>> newData) async {
    try {
      if (_modelState != CollabModelState.trained) {
        throw AIModelException(
            'Model must be in trained state for updates',
            code: AIConstants.ERROR_INVALID_INPUT
        );
      }

      _modelState = CollabModelState.training;
      await validateData(newData);

      final startTime = DateTime.now();

      // Yeni kullanıcı-item değerlendirmelerini ekle
      for (var data in newData) {
        final userId = data['user_id'].toString();
        final itemId = data['exercise_id'].toString();
        final rating = data['rating'].toDouble();

        if (rating.isNaN) {
          _logger.warning('Skipping invalid rating for user $userId, item $itemId');
          continue;
        }

        _userItemRatings[userId] ??= {};
        _userItemRatings[userId]![itemId] = _normalizeRating(rating);

        // İlgili kullanıcı için similarity cache'i temizle
        await clearUserCache(userId);
      }

      // Metrikleri güncelle
      final metrics = await calculateMetrics(newData);
      updateMetrics(metrics);

      final updateDuration = DateTime.now().difference(startTime);
      _trackPerformance('model_update_time', updateDuration.inMilliseconds.toDouble());

      _modelState = CollabModelState.trained;
      _logger.info('Model updated with ${newData.length} new records in ${updateDuration.inMilliseconds}ms');
    } catch (e) {
      _modelState = CollabModelState.error;
      _logger.severe('Model update failed: $e');
      throw AIModelException('Model update failed: $e');
    }
  }

}