import '../../blocs/data_provider/sql_provider.dart';
import '../../models/firebase_models/user_ai_profile.dart';
import '../../models/sql_models/routines.dart';
import 'ai_repository.dart';

class RecommendationService {
  final AIRepository _aiRepository;
  final SQLProvider _sqlProvider;
  bool _isInitialized = false;

  RecommendationService(this._aiRepository, this._sqlProvider);

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _aiRepository.initialize();
    _isInitialized = true;
  }

  Future<List<Routines>> getRecommendedRoutines({
    required String userId,
    required UserAIProfile userProfile,
    int limit = 5,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Hedef belirleme
      final goalIds = await _mapAIPredictionToGoals(
        aiPrediction: userProfile.modelScores!['exercise_plan']?.toInt() ?? 50,
        bmiCase: _aiRepository.getBMICase(userProfile.bmi ?? 0),
        bfpCase: userProfile.modelScores!['bfp_case']?.toInt() ?? 49,
      );

      // WorkoutType ağırlıkları
      final typeWeights = await _getWorkoutTypeWeights(
        goalIds: goalIds,
        confidence: userProfile.modelScores!['confidence']!.toDouble(),
        metrics: userProfile.metrics,
      );

      // Rutinleri filtrele
      return await _filterRoutines(
          goalIds: goalIds,
          typeWeights: typeWeights,
          fitnessLevel: userProfile.fitnessLevel,
          limit: limit
      );

    } catch (e) {
      throw Exception('Rutin önerisi başarısız: $e');
    }
  }

  Future<List<int>> _mapAIPredictionToGoals({
    required int aiPrediction,
    required int bmiCase,
    required int bfpCase,
  }) async {
    final List<int> goalIds = [];

    switch(aiPrediction) {
      case 1:
        goalIds.add(2); // Rehabilitation
        break;
      case 2:
        goalIds.add(3); // Muscle Gain
        break;
      case 3:
        if (bfpCase <= 2) {
          goalIds.addAll([4, 5]); // Get Fit, Get Stronger
        } else {
          goalIds.add(4); // Get Fit
        }
        break;
      case 4:
        if (bfpCase <= 3) {
          goalIds.addAll([4, 6]); // Get Fit, Athletic Performance
        } else {
          goalIds.add(4); // Get Fit
        }
        break;
      case 5: case 6: case 7:
      goalIds.add(1); // Weight Loss
      break;
    }
    return goalIds;
  }

  Future<Map<int, double>> _getWorkoutTypeWeights({
    required List<int> goalIds,
    required double confidence,
    required AIMetrics metrics,
  }) async {
    final weights = <int, double>{};
    final typeGoals = await _sqlProvider.getWorkoutTypeGoalsForGoals(goalIds);

    // Kullanıcı metriklerinden ağırlık faktörleri
    final dropoutFactor = 1 - metrics.programDropoutRate;
    final experienceFactor = metrics.completedProgramCount / 10.0;
    final consistencyFactor = metrics.averageTrainingMinutes / 60.0;

    for (var typeGoal in typeGoals) {
      weights[typeGoal.workoutTypeId] =
          (weights[typeGoal.workoutTypeId] ?? 0) +
              (typeGoal.recommendedPercentage / 100) *
                  confidence *
                  dropoutFactor *
                  (1 + experienceFactor.clamp(0.0, 1.0)) *
                  (1 + consistencyFactor.clamp(0.0, 1.0));
    }

    return weights;
  }

  Future<List<Routines>> _filterRoutines({
    required List<int> goalIds,
    required Map<int, double> typeWeights,
    required int fitnessLevel,
    required int limit
  }) async {
    final minDifficulty = fitnessLevel;
    final maxDifficulty = (fitnessLevel + 2).clamp(1, 5);

    final routines = await _sqlProvider.getRoutinesByGoalsAndDifficulty(
        goalIds: goalIds,
        minDifficulty: minDifficulty,
        maxDifficulty: maxDifficulty
    );

    final scoredRoutines = routines.map((routine) {
      final typeWeight = typeWeights[routine.workoutTypeId] ?? 0;
      final difficultyScore = 1 - ((maxDifficulty - routine.difficulty).abs() / maxDifficulty);

      return (
      routine: routine,
      score: typeWeight * difficultyScore
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scoredRoutines
        .take(limit)
        .map((sr) => sr.routine)
        .toList();
  }

  void dispose() {
    _isInitialized = false;
  }
}
