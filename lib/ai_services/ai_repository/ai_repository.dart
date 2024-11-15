// lib/ai_module/repository/ai_repository.dart

import 'package:logging/logging.dart';
import '../../models/Parts.dart';
import '../../models/routines.dart';
import '../Feature.dart';
import '../ai_services/AGDE_service.dart';
import '../ai_services/KNN_service.dart';
import '../feature_extraction_service.dart';

class AIRepository {
  final AGDEService _agdeService;
  final KNNService _knnService;
  final FeatureExtractionService _featureService;
  final Logger _logger = Logger('AIRepository');
  final Map<String, AIRecommendationResult> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 30);

  AIRepository({
    required int k,
    required double threshold,
  }) : _agdeService = AGDEService(),
        _knnService = KNNService(k: k),
        _featureService = FeatureExtractionService(
          threshold: threshold,
          k: k,
        );

  Future<AIRecommendationResult<T>> getOptimizedRecommendations<T>({
    required List<T> items,
    required List<Feature> features,
  }) async {
    final cacheKey = '${T.toString()}_${items.length}_${features.length}';

    if (_cache.containsKey(cacheKey) &&
        DateTime.now().difference(_cache[cacheKey]!.timestamp) < _cacheDuration) {
      return _cache[cacheKey]! as AIRecommendationResult<T>;
    }

    try {
      final List<List<double>> featureValues = features.map((f) => f.values).toList();
      final weights = await _agdeService.calculateWeights(featureValues.cast<Feature>());
      _logger.info('Weights optimized: ${weights.length} features');

      final extractionResult = await _featureService.extractFeatures(
        bestSolution: weights,
        trainFeatures: features,
        testFeatures: features,
      );
      _logger.info('Features extracted: ${extractionResult.removedFeatureCount} features removed');

      final classifiedFeatures = _knnService.classifyFeatures(
        extractionResult.reducedTrainFeatures,
        extractionResult.reducedTestFeatures,
      );
      _logger.info('Features classified: ${classifiedFeatures.length} items');

      final recommendations = _getTopRecommendations(
        items,
        classifiedFeatures.cast<List<double>>(),
        weights,
      );

      final result = AIRecommendationResult<T>(
        recommendations: recommendations,
        performance: extractionResult.performance,
        removedFeatureCount: extractionResult.removedFeatureCount,
        timestamp: DateTime.now(),
      );

      _cache[cacheKey] = result;
      return result;
    } catch (e, stackTrace) {
      _logger.severe('Error in optimization: ${e.toString()}', e, stackTrace);
      return AIRecommendationResult<T>(
        recommendations: items.take(5).toList(),
        performance: 0.0,
        removedFeatureCount: 0,
        timestamp: DateTime.now(),
        errorMessage: 'Optimization failed: ${e.toString()}',
      );
    }
  }


  Future<List<Routines>> getOptimizedRoutineRecommendations(
      List<Routines> routines,
      ) async {
    try {
      final features = _featureService.extractRoutineFeatures(routines);
      final result = await getOptimizedRecommendations(
        items: routines,
        features: features,
      );
      return result.recommendations;
    } catch (e, stackTrace) {
      _logger.severe('Error getting routine recommendations: ${e.toString()}', e, stackTrace);
      return routines.take(5).toList();
    }
  }

  Future<List<Parts>> getOptimizedPartRecommendations(
      List<Parts> parts,
      ) async {
    try {
      final features = _featureService.extractPartFeatures(parts);
      final result = await getOptimizedRecommendations(
        items: parts,
        features: features,
      );
      return result.recommendations;
    } catch (e, stackTrace) {
      _logger.severe('Error getting part recommendations: ${e.toString()}', e, stackTrace);
      return parts.take(5).toList();
    }
  }

  List<T> _getTopRecommendations<T>(
      List<T> items,
      List<List<double>> features,
      List<double> weights,
      ) {
    try {
      final scoredItems = items.asMap().entries
          .map((entry) {
        final index = entry.key;
        final item = entry.value;
        final score = _calculateScore(features[index], weights);
        return _ScoredItem(item: item, score: score);
      })
          .toList();

      scoredItems.sort((a, b) => b.score.compareTo(a.score));
      return scoredItems
          .take(5)
          .map((scored) => scored.item)
          .toList();
    } catch (e, stackTrace) {
      _logger.severe('Error getting top recommendations: ${e.toString()}', e, stackTrace);
      return items.take(5).toList();
    }
  }

  double _calculateScore(List<double> featureValues, List<double> weights) {
    return featureValues.asMap().entries.fold(0.0, (score, entry) => score + entry.value * weights[entry.key]);
  }
}

class AIRecommendationResult<T> {
  final List<T> recommendations;
  final double performance;
  final int removedFeatureCount;
  final DateTime timestamp;
  final String? errorMessage;

  AIRecommendationResult({
    required this.recommendations,
    required this.performance,
    required this.removedFeatureCount,
    required this.timestamp,
    this.errorMessage,
  });
}

class _ScoredItem<T> {
  final T item;
  final double score;
  _ScoredItem({required this.item, required this.score});
}
