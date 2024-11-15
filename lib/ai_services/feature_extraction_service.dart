// lib/services/feature_extraction_service.dart

import 'dart:math';
import 'package:logging/logging.dart';
import '../models/Parts.dart';
import '../models/routines.dart';
import 'Feature.dart';
import 'ai_services/KNN_service.dart';

class FeatureExtractionService {
  final Logger _logger = Logger('FeatureExtractionService');
  final KNNService _knnService;
  final double threshold;
  final int k;

  FeatureExtractionService({
    required this.threshold,
    required this.k,
  }) : _knnService = KNNService(k: k);

  Future<FeatureExtractionResult> extractFeatures({
    required List<double> bestSolution,
    required List<Feature> trainFeatures,
    required List<Feature> testFeatures,
  }) async {
    try {
      if (bestSolution.isEmpty || trainFeatures.isEmpty || testFeatures.isEmpty) {
        throw ArgumentError('Empty input data');
      }

      int columnCount = bestSolution.length;
      int removedFeatureCount = 0;

      List<Feature> reducedTrainFeatures = _copyFeatures(trainFeatures);
      List<Feature> reducedTestFeatures = _copyFeatures(testFeatures);

      for (int i = columnCount - 1; i >= 0; i--) {
        if (bestSolution[i] < threshold) {
          _removeFeatureAtIndex(reducedTrainFeatures, i);
          _removeFeatureAtIndex(reducedTestFeatures, i);
          removedFeatureCount++;
        }
      }

      double performance = _knnService.calculateError(
        reducedTrainFeatures,
        reducedTestFeatures,
      );

      return FeatureExtractionResult(
        performance: performance,
        removedFeatureCount: removedFeatureCount,
        reducedTrainFeatures: reducedTrainFeatures,
        reducedTestFeatures: reducedTestFeatures,
      );
    } catch (e, stackTrace) {
      _logger.severe('Error in feature extraction: $e', stackTrace);
      rethrow;
    }
  }

  List<Feature> _copyFeatures(List<Feature> features) {
    return features.map((feature) => Feature(
      id: feature.id,
      values: List<double>.from(feature.values),
    )).toList();
  }

  void _removeFeatureAtIndex(List<Feature> features, int index) {
    for (var feature in features) {
      if (index < feature.values.length) {
        feature.values.removeAt(index);
      }
    }
  }

  List<Feature> extractRoutineFeatures(List<Routines> routines) {
    return routines.map((routine) => Feature(
      id: routine.id,
      values: [
        routine.userProgress?.toDouble() ?? 0.0,
        routine.difficulty.toDouble(),
        routine.isFavorite ? 1.0 : 0.0,
        routine.lastUsedDate?.millisecondsSinceEpoch.toDouble() ?? 0.0,
        routine.userRecommended ?? false ? 1.0 : 0.0,
      ],
    )).toList();
  }

  List<Feature> extractPartFeatures(List<Parts> parts) {
    return parts.map((part) => Feature(
      id: part.id,
      values: [
        part.userProgress?.toDouble() ?? 0.0,
        part.exerciseIds.length.toDouble(),
        part.isFavorite ? 1.0 : 0.0,
        part.lastUsedDate?.millisecondsSinceEpoch.toDouble() ?? 0.0,
        part.userRecommended ?? false ? 1.0 : 0.0,
      ],
    )).toList();
  }
}

class FeatureExtractionResult {
  final double performance;
  final int removedFeatureCount;
  final List<Feature> reducedTrainFeatures;
  final List<Feature> reducedTestFeatures;

  FeatureExtractionResult({
    required this.performance,
    required this.removedFeatureCount,
    required this.reducedTrainFeatures,
    required this.reducedTestFeatures,
  });
}
