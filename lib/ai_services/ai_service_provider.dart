// lib/providers/ai_service_provider.dart

import 'package:logging/logging.dart';
import '../models/Parts.dart';
import '../models/routines.dart';
import 'Feature.dart';
import 'ai_services/AGDE_service.dart';
import 'ai_services/KNN_service.dart';
import 'feature_extraction_service.dart';

class AIServiceProvider {
  static final Logger _logger = Logger('AIServiceProvider');

  static final KNNService _knnService = KNNService(k: 3);
  static final AGDEService _agdeService = AGDEService();
  static final FeatureExtractionService _featureService = FeatureExtractionService(
    threshold: 0.5,
    k: 3,
  );

  static final AIServiceProvider _instance = AIServiceProvider._internal();

  factory AIServiceProvider() => _instance;

  AIServiceProvider._internal();

  static Future<List<double>> getOptimizedWeights(List<Feature> features) async {
    try {
      return await _agdeService.calculateWeights(features);
    } catch (e, stackTrace) {
      _logger.severe('Error getting optimized weights: $e', stackTrace);
      return List.filled(features.first.values.length, 1.0);
    }
  }

  static double getKNNError(List<Feature> trainFeatures, List<Feature> testFeatures) {
    try {
      return _knnService.calculateError(trainFeatures, testFeatures);
    } catch (e, stackTrace) {
      _logger.severe('Error calculating KNN error: $e', stackTrace);
      return 100.0;
    }
  }

  static Future<FeatureExtractionResult> extractFeatures({
    required List<double> bestSolution,
    required List<Feature> trainFeatures,
    required List<Feature> testFeatures,
  }) async {
    try {
      return await _featureService.extractFeatures(
        bestSolution: bestSolution,
        trainFeatures: trainFeatures,
        testFeatures: testFeatures,
      );
    } catch (e, stackTrace) {
      _logger.severe('Error extracting features: $e', stackTrace);
      throw Exception('Feature extraction failed: $e');
    }
  }

  static Future<List<Routines>> getOptimizedRoutineRecommendations(
      List<Routines> routines,
      ) async {
    try {
      final features = _featureService.extractRoutineFeatures(routines);
      final weights = await getOptimizedWeights(features);
      final result = await extractFeatures(
        bestSolution: weights,
        trainFeatures: features,
        testFeatures: features,
      );
      return _getTopRecommendations(
        routines,
        result.reducedTrainFeatures,
        weights,
      );
    } catch (e, stackTrace) {
      _logger.severe('Error getting routine recommendations: $e', stackTrace);
      return routines.take(5).toList();
    }
  }

  static Future<List<Parts>> getOptimizedPartRecommendations(
      List<Parts> parts,
      ) async {
    try {
      final features = _featureService.extractPartFeatures(parts);
      final weights = await getOptimizedWeights(features);
      final result = await extractFeatures(
        bestSolution: weights,
        trainFeatures: features,
        testFeatures: features,
      );
      return _getTopRecommendations(
        parts,
        result.reducedTrainFeatures,
        weights,
      );
    } catch (e, stackTrace) {
      _logger.severe('Error getting part recommendations: $e', stackTrace);
      return parts.take(5).toList();
    }
  }

  static List<T> _getTopRecommendations<T>(
      List<T> items,
      List<Feature> features,
      List<double> weights,
      ) {
    final scoredItems = items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final score = _calculateScore(features[index].values, weights);
      return _ScoredItem<T>(item: item, score: score);
    }).toList();

    scoredItems.sort((a, b) => b.score.compareTo(a.score));
    return scoredItems.take(5).map((scored) => scored.item).toList();
  }

  static double _calculateScore(List<double> featureValues, List<double> weights) {
    return featureValues.asMap().entries.fold(0.0, (score, entry) => score + entry.value * weights[entry.key]);
  }
}

class _ScoredItem<T> {
  final T item;
  final double score;

  _ScoredItem({required this.item, required this.score});
}
