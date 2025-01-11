import '../../blocs/data_bloc_routine/RoutineRepository.dart';

class ExerciseTypeClassifier {
  final RoutineRepository _routineRepository;

  ExerciseTypeClassifier(this._routineRepository);

  // WorkoutGoal-WorkoutType uyumluluk matrisi (0-100 arası)
  final Map<int, Map<int, int>> goalTypeCompatibility = {
    1: {3: 90, 1: 70, 5: 60}, // Kilo Verme
    2: {5: 90, 3: 70, 1: 50}, // Rehabilitasyon
    3: {2: 90, 1: 80, 4: 60}, // Kas Kazanımı
    4: {3: 80, 1: 70, 5: 70}, // Genel Fitness
    5: {1: 90, 4: 80, 2: 70}, // Güç Artırma
    6: {4: 90, 1: 80, 3: 70} // Atletik Performans
  };

  final Map<int, Map<int, double>> exerciseTypeGoalWeights = {
    // Çok Zayıf
    1: {3: 0.9, 5: 0.7, 4: 0.4},
    // Zayıf
    2: {3: 0.8, 4: 0.6, 5: 0.5},
    // Normal
    3: {4: 0.9, 6: 0.7, 5: 0.6},
    // Hafif Kilolu
    4: {1: 0.8, 4: 0.7, 3: 0.4},
    // Kilolu
    5: {1: 0.9, 2: 0.7, 4: 0.3}
    // Şişman için özel durumlar eklenebilir.
  };

  Map<int, double> _calculateWorkoutTypeScores(Map<int, double> goalWeights) {
    Map<int, double> workoutTypeScores = {};

    goalWeights.forEach((goalId, goalWeight) {
      final typeCompatibility = goalTypeCompatibility[goalId] ?? {};

      typeCompatibility.forEach((workoutTypeId, compatibility) {
        final currentScore = workoutTypeScores[workoutTypeId] ?? 0.0;
        final weightedScore = (compatibility / 100) * goalWeight;

        workoutTypeScores[workoutTypeId] = currentScore + weightedScore;
      });
    });

    return workoutTypeScores;
  }

  Map<int, double> _adjustScoresByConfidence(Map<int, double> typeScores, double confidence) {
    final normalizedConfidence = (confidence - 60) / (40);
    return typeScores.map((typeId, score) => MapEntry(typeId, score * normalizedConfidence));
  }

  double _calculateDifficultyMatchScore(int difficulty) {
    switch (difficulty) {
      case 1:
        return .6;
      case 2:
        return .7;
      case 3:
        return .9;
      case 4:
        return .7;
      case 5:
        return .6;
      default:
        return .5;
    }
  }

  Future<List<int>> getOptimalRoutineIds({
    required int exerciseType,
    required double confidence,
    int limit = 5,
    required int bmiCategory,
    required int bfpCategory,
  }) async {
    final goalWeights = determineMainWorkoutGoal(exerciseType);

    // Hedef ağırlıklarını kontrol et
    if (goalWeights.isEmpty) {
      throw Exception('Hedef ağırlıkları boş!');
    }

    final typeScores = _calculateWorkoutTypeScores(goalWeights);
    final adjustedScores = _adjustScoresByConfidence(typeScores, confidence);

    return await _getTopRoutines(adjustedScores, limit, bmiCategory);
  }

  Future<List<int>> _getTopRoutines(Map<int,double> adjustedScores, int limit, int bmiCategory) async {
    try {
      if (adjustedScores.isEmpty) {
        throw Exception('Ayarlanmış skorlar boş!');
      }

      final sortedTypes = adjustedScores.entries.toList()
        ..sort((a,b) => b.value.compareTo(a.value));

      Map<int,double> routineScores = {};

      for (var entry in sortedTypes.take(3)) {
        final workoutTypeId = entry.key;
        final typeScore = entry.value;

        final routines = await _routineRepository.getRoutinesByWorkoutType(workoutTypeId);

        if (routines.isEmpty) {
          throw Exception('Rutinler bulunamadı! Workout Type ID: $workoutTypeId');
        }

        for (var routine in routines) {
          if (_isRoutineSuitableForBmi(routine.difficulty, bmiCategory)) {
            final currentScore = routineScores[routine.id] ??= .0;
            final difficultyMatch = _calculateDifficultyMatchScore(routine.difficulty);
            routineScores[routine.id] = currentScore + (typeScore * difficultyMatch);
          }
        }
      }

      final sortedRoutines = routineScores.entries.toList()
        ..sort((a,b) => b.value.compareTo(a.value));

      return sortedRoutines.take(limit).map((e) => e.key).toList();
    } catch (e) {
      throw Exception('Rutin filtreleme hatası: $e');
    }
  }


  bool _isRoutineSuitableForBmi(int routineDifficulty,int bmiCategory) {
    switch(bmiCategory) {
    case 1:
    return routineDifficulty <=2;
    case 2:
    return routineDifficulty <=3;
    case 3:
    return routineDifficulty <=4;
    case 4:
    return routineDifficulty <=5;
    case 5:
    return routineDifficulty ==5;
    case 6:
    return routineDifficulty ==4 || routineDifficulty ==5;
    default:
    return true;
    }
  }


  Map<int,double> determineMainWorkoutGoal(int exerciseType) {
    final goalWeights = exerciseTypeGoalWeights[exerciseType];

    if (goalWeights == null) {
      throw Exception('Geçersiz egzersiz türü : $exerciseType');
    }

    int mainGoal = -1;
    double maxWeight = -1;

    goalWeights.forEach((goalId, weight) {
      if (weight > maxWeight) {
        maxWeight = weight;
        mainGoal = goalId;
      }
    });

    if (mainGoal == -1) {
      throw Exception('Hedef belirlenemedi');
    }

    return {mainGoal : maxWeight}; // Ana hedef ve ağırlığını döndür
  }

}
