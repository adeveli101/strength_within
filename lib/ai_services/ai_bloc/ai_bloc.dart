// lib/ai_module/bloc/ai_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import '../../models/Parts.dart';
import '../../models/routines.dart';
import '../Feature.dart';
import '../ai_services/AGDE_service.dart';
import '../ai_services/KNN_service.dart';
import '../feature_extraction_service.dart';
import 'ai_event.dart';
import 'ai_state.dart';

class AIBloc extends Bloc<AIEvent, AIState> {
  final AGDEService _agdeService;
  final KNNService _knnService;
  final FeatureExtractionService _featureService;
  final _logger = Logger('AIBloc');

  // Önbellek için değişkenler
  DateTime? _lastRoutineOptimizationTime;
  DateTime? _lastPartOptimizationTime;
  AIRoutineRecommendationsOptimized? _cachedRoutineRecommendations;
  AIPartRecommendationsOptimized? _cachedPartRecommendations;
  static const Duration _cacheDuration = Duration(minutes: 30);

  AIBloc()
      : _agdeService = AGDEService(),
        _knnService = KNNService(k: 3),
        _featureService = FeatureExtractionService(threshold: 0.5, k: 3),
        super(AIInitial()) {
    on<OptimizeRoutineRecommendations>(_onOptimizeRoutineRecommendations);
    on<OptimizePartRecommendations>(_onOptimizePartRecommendations);
  }

  Future<void> _onOptimizeRoutineRecommendations(
      OptimizeRoutineRecommendations event,
      Emitter<AIState> emit,
      ) async {
    try {
      // Önbellek kontrolü
      if (_cachedRoutineRecommendations != null &&
          _lastRoutineOptimizationTime != null &&
          DateTime.now().difference(_lastRoutineOptimizationTime!) < _cacheDuration) {
        emit(_cachedRoutineRecommendations!);
        return;
      }

      emit(AILoading());
      final features = _featureService.extractRoutineFeatures(event.routines);
      final weights = await _agdeService.calculateWeights(features);
      final extractionResult = await _featureService.extractFeatures(
        bestSolution: weights,
        trainFeatures: features,
        testFeatures: features,
      );
      final classifiedFeatures = _knnService.classifyFeatures(
        extractionResult.reducedTrainFeatures,
        extractionResult.reducedTestFeatures,
      );
      final recommendations = _getTopRecommendations<Routines>(
        event.routines,
        classifiedFeatures,
        weights,
      );
      final optimizedState = AIRoutineRecommendationsOptimized(
        recommendations: recommendations,
        userId: event.userId,
      );

      // Önbelleğe alma
      _cachedRoutineRecommendations = optimizedState;
      _lastRoutineOptimizationTime = DateTime.now();

      emit(optimizedState);
    } catch (e, stackTrace) {
      _logger.severe('Error optimizing routine recommendations', e, stackTrace);
      emit(AIError(
        message: 'Öneriler optimize edilirken bir hata oluştu: ${e.toString()}',
        userId: event.userId,
      ));
    }
  }

  Future<void> _onOptimizePartRecommendations(
      OptimizePartRecommendations event,
      Emitter<AIState> emit,
      ) async {
    try {
      // Önbellek kontrolü
      if (_cachedPartRecommendations != null &&
          _lastPartOptimizationTime != null &&
          DateTime.now().difference(_lastPartOptimizationTime!) < _cacheDuration) {
        emit(_cachedPartRecommendations!);
        return;
      }

      emit(AILoading());
      final features = _featureService.extractPartFeatures(event.parts);
      final weights = await _agdeService.calculateWeights(features);
      final extractionResult = await _featureService.extractFeatures(
        bestSolution: weights,
        trainFeatures: features,
        testFeatures: features,
      );
      final classifiedFeatures = _knnService.classifyFeatures(
        extractionResult.reducedTrainFeatures,
        extractionResult.reducedTestFeatures,
      );
      final recommendations = _getTopRecommendations<Parts>(
        event.parts,
        classifiedFeatures,
        weights,
      );
      final optimizedState = AIPartRecommendationsOptimized(
        recommendations: recommendations,
        userId: event.userId,
      );

      // Önbelleğe alma
      _cachedPartRecommendations = optimizedState;
      _lastPartOptimizationTime = DateTime.now();

      emit(optimizedState);
    } catch (e, stackTrace) {
      _logger.severe('Error optimizing part recommendations', e, stackTrace);
      emit(AIError(
        message: 'Öneriler optimize edilirken bir hata oluştu: ${e.toString()}',
        userId: event.userId,
      ));
    }
  }

  List<T> _getTopRecommendations<T>(
      List<T> items,
      List<Feature> features,
      List<double> weights,
      ) {
    final scoredItems = items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final score = _calculateScore(features[index].values, weights);
      return ScoredItem<T>(item: item, score: score);
    }).toList();
    scoredItems.sort((a, b) => b.score.compareTo(a.score));
    return scoredItems.take(5).map((scored) => scored.item).toList();
  }

  double _calculateScore(List<double> featureValues, List<double> weights) {
    double score = 0.0;
    for (int i = 0; i < featureValues.length; i++) {
      score += featureValues[i] * weights[i];
    }
    return score;
  }
}

class ScoredItem<T> {
  final T item;
  final double score;
  ScoredItem({required this.item, required this.score});
}
