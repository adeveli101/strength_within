import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import '../../models/firebase_models/RoutineHistory.dart';
import '../../models/firebase_models/firebase_routines.dart';
import '../../models/sql_models/BodyPart.dart';
import '../../models/sql_models/RoutineExercises.dart';
import '../../models/sql_models/RoutinetargetedBodyParts.dart';
import '../../models/sql_models/WorkoutType.dart';
import '../../models/sql_models/exercises.dart';
import '../../models/sql_models/routine_frequency.dart';
import '../../models/sql_models/routines.dart';
import '../../models/sql_models/workoutGoals.dart';
import '../data_provider/sql_provider.dart';
import '../data_provider/firebase_provider.dart';


final _logger = Logger('RoutineRepository');

class RoutineRepository {
  final SQLProvider _sqlProvider;
  final FirebaseProvider _firebaseProvider;

  RoutineRepository(this._sqlProvider, this._firebaseProvider);

  SQLProvider get sqlProvider => _sqlProvider;

  void _initializeBlocs() {
    // Providers
    final sqlProvider = Get.put(SQLProvider());
    final firebaseProvider = Get.put(FirebaseProvider());

    // Repositories
    final routineRepository = Get.put(RoutineRepository(
        sqlProvider,
        firebaseProvider
    ));
  }

  final _routineCache = <int, Routines>{}; // Yerel rutinler
  final _userRoutineCache = <int, FirebaseRoutines>{}; // Kullanıcıya özel rutinler

  /// Tüm cache'i güncelle (hem SQL hem Firebase)
  Future<void> refreshRoutineCache(String userId) async {
    final routines = await _sqlProvider.getAllRoutines();
    _routineCache
      ..clear()
      ..addAll({for (var r in routines) r.id: r});

    final userRoutines = await _firebaseProvider.getUserRoutines(userId);
    _userRoutineCache
      ..clear()
      ..addAll({for (var ur in userRoutines) int.tryParse(ur.id) ?? -1: ur});
  }

  /// Cache'i temizle
  void clearCache() {
    _routineCache.clear();
    _userRoutineCache.clear();
  }

  /// Birleştirilmiş rutin listesi (cache'den)
  List<Routines> getCombinedRoutines() {
    return _routineCache.values.map((routine) {
      final userRoutine = _userRoutineCache[routine.id];
      return routine.copyWith(
        isFavorite: userRoutine?.isFavorite ?? false,
        isCustom: userRoutine?.isCustom ?? false,
        userProgress: userRoutine?.userProgress,
        lastUsedDate: userRoutine?.lastUsedDate,
        userRecommended: userRoutine?.userRecommended ?? false,
      );
    }).toList();
  }

  /// Favori güncelle (hem Firebase hem cache)
  Future<void> updateFavorite(String userId, int routineId, bool isFavorite) async {
    await _firebaseProvider.toggleFavorite(userId, routineId.toString(), 'routine', isFavorite);
    final old = _userRoutineCache[routineId];
    _userRoutineCache[routineId] = (old ?? FirebaseRoutines.fromRoutine(_routineCache[routineId]!))
        .copyWith(isFavorite: isFavorite);
  }

  /// İlerleme güncelle (hem Firebase hem cache)
  Future<void> updateProgress(String userId, int routineId, int progress) async {
    await _firebaseProvider.updateUserProgress(userId, routineId.toString(), 'routine', progress);
    final old = _userRoutineCache[routineId];
    _userRoutineCache[routineId] = (old ?? FirebaseRoutines.fromRoutine(_routineCache[routineId]!))
        .copyWith(userProgress: progress);
  }

  Future<List<Routines>> getRoutines() async {
    if (_routineCache.isNotEmpty) return _routineCache.values.toList();
    final routines = await _sqlProvider.getAllRoutines();
    _routineCache.addAll({for (var r in routines) r.id: r});
    return routines;
  }


  Future<List<Routines>> getAllRoutines() async {
    try {
      List<Routines> routines = await _sqlProvider.getAllRoutines();
      _logger.info("Yerel veritabanından alınan rutin sayısı: ${routines.length}");
      return routines;
    } catch (e, stackTrace) {
      _logger.severe('Error in getAllRoutines', e, stackTrace);
      rethrow;
    }
  }



  Future<Routines?> getRoutineById(int id) async {
    try {
      return await _sqlProvider.getRoutineById(id);
    } catch (e, stackTrace) {
      _logger.severe('Error in getRoutineById', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Routines>> getRoutinesByName(String name) async {
    try {
      return await _sqlProvider.getRoutinesByName(name);
    } catch (e, stackTrace) {
      _logger.severe('Error in getRoutinesByName', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Routines>> getRoutinesByPartialName(String partialName) async {
    try {
      return await _sqlProvider.getRoutinesByPartialName(partialName);
    } catch (e, stackTrace) {
      _logger.severe('Error in getRoutinesByPartialName', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Routines>> getRoutinesByMainTargetedBodyPart(int mainTargetedBodyPartId) async {
    try {
      return await _sqlProvider.getRoutinesByBodyPart(mainTargetedBodyPartId);
    } catch (e, stackTrace) {
      _logger.severe('Error in getRoutinesByMainTargetedBodyPart', e, stackTrace);
      rethrow;
    }
  }

  Future<List<RoutineExercises>> getOrderedExercisesForRoutine(int routineId) async {
    try {
      return await _sqlProvider.getRoutineExercisesByRoutineId(routineId);
    } catch (e, stackTrace) {
      _logger.severe('Error getting ordered exercises', e, stackTrace);
      rethrow;
    }
  }

  Future<List<RoutineTargetedBodyParts>> getRoutineTargets(int routineId) async {
    try {
      return await _sqlProvider.getRoutineTargetedBodyParts(routineId);
    } catch (e, stackTrace) {
      _logger.severe('Error getting routine targets', e, stackTrace);
      rethrow;
    }
  }

  Future<BodyParts?> getBodyPartById(int id) async {
    try {
      return await _sqlProvider.getBodyPartById(id);
    } catch (e, stackTrace) {
      _logger.severe('Error getting body part by id', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<int, int>> getTargetPercentagesForRoutine(int routineId) async {
    try {
      return await _sqlProvider.getTargetPercentagesForRoutine(routineId);
    } catch (e, stackTrace) {
      _logger.severe('Error getting target percentages', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Routines>> getRoutinesByWorkoutType(int workoutTypeId) async {
    try {
      return await _sqlProvider.getRoutinesByWorkoutType(workoutTypeId);
    } catch (e, stackTrace) {
      _logger.severe('Error in getRoutinesByWorkoutType', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Routines>> getRoutinesByBodyPartAndWorkoutType(
      int mainTargetedBodyPartId,
      int workoutTypeId,
      ) async {
    try {
      return await _sqlProvider.getRoutinesByBodyPartAndWorkoutType(
        mainTargetedBodyPartId,
        workoutTypeId,
      );
    } catch (e, stackTrace) {
      _logger.severe('Error in getRoutinesByBodyPartAndWorkoutType', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Routines>> getRoutinesAlphabetically() async {
    try {
      return await _sqlProvider.getRoutinesAlphabetically();
    } catch (e, stackTrace) {
      _logger.severe('Error in getRoutinesAlphabetically', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Routines>> getRandomRoutines(int count) async {
    try {
      return await _sqlProvider.getRandomRoutines(count);
    } catch (e, stackTrace) {
      _logger.severe('Error in getRandomRoutines', e, stackTrace);
      rethrow;
    }
  }

  Future<WorkoutTypes?> getWorkoutTypeById(int id) async {
    try {
      final workoutType = await _sqlProvider.getWorkoutTypeById(id);
      _logger.info("Fetched workout type with ID $id: $workoutType");
      return workoutType;
    } catch (e, stackTrace) {
      _logger.severe('Error in getWorkoutTypeById', e, stackTrace);
      rethrow;
    }
  }

  Future<int> getWorkoutTypesCount() async {
    try {
      return await _sqlProvider.getWorkoutTypesCount();
    } catch (e, stackTrace) {
      _logger.severe('Error in getWorkoutTypesCount', e, stackTrace);
      rethrow;
    }
  }

  Future<List<WorkoutTypes>> getWorkoutTypesByName(String name) async {
    try {
      return await _sqlProvider.getWorkoutTypesByName(name);
    } catch (e, stackTrace) {
      _logger.severe('Error in getWorkoutTypesByName', e, stackTrace);
      rethrow;
    }
  }

  Future<List<RoutineExercises>> getRoutineExercisesByRoutineId(int routineId) async {
    try {
      return await _sqlProvider.getRoutineExercisesByRoutineId(routineId);
    } catch (e, stackTrace) {
      _logger.severe('Error in getRoutineExercisesByRoutineId', e, stackTrace);
      rethrow;
    }
  }

  Future<Exercises?> getExerciseById(int id) async {
    try {
      final exercise = await _sqlProvider.getExerciseById(id);
      _logger.info("Fetched exercise with ID $id: $exercise");
      return exercise;
    } catch (e, stackTrace) {
      _logger.severe('Error in getExerciseById', e, stackTrace);
      rethrow;
    }
  }

  Future<List<FirebaseRoutines>> getUserRoutines(String userId) async {
    try {
      return await _firebaseProvider.getUserRoutines(userId);
    } catch (e, stackTrace) {
      _logger.severe('Error in getUserRoutines', e, stackTrace);
      rethrow;
    }
  }

  Future<void> addOrUpdateUserRoutine(String userId, FirebaseRoutines routine) async {
    try {
      await _firebaseProvider.addOrUpdateUserRoutine(userId, routine);
    } catch (e, stackTrace) {
      _logger.severe('Error in addOrUpdateUserRoutine', e, stackTrace);
      rethrow;
    }
  }

  Future<void> toggleRoutineFavorite(String userId, String routineId, bool isFavorite) async {
    try {
      await _firebaseProvider.toggleFavorite(userId, routineId, 'routine', isFavorite);
    } catch (e, stackTrace) {
      _logger.severe('Error in toggleRoutineFavorite', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateUserRoutineProgress(String userId, String routineId, int progress) async {
    try {
      await _firebaseProvider.updateUserProgress(userId, routineId, 'routine', progress);
    } catch (e, stackTrace) {
      _logger.severe('Error in updateUserRoutineProgress', e, stackTrace);
      rethrow;
    }
  }

  Future<void> addRoutineHistory(RoutineHistory history) async {
    try {
      await _firebaseProvider.addRoutineHistory(history);
    } catch (e, stackTrace) {
      _logger.severe('Error adding routine history', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Routines>> getRoutinesWithUserData(String userId) async {
    // Eğer cache boşsa veya güncel değilse, cache'i tazele
    if (_routineCache.isEmpty || _userRoutineCache.isEmpty) {
      await refreshRoutineCache(userId);
    }
    return getCombinedRoutines();
  }

  Future<Routines?> getRoutineWithUserData(String userId, int routineId) async {
    try {
      // Yerel rutini al
      Routines? localRoutine = await getRoutineById(routineId);
      if (localRoutine == null) return null;

      // Rutin egzersizlerini al
      final routineExercises = await getRoutineExercisesByRoutineId(routineId);

      // Hedef vücut bölümlerini al
      final targetedBodyParts = await _sqlProvider.getRoutineTargetedBodyParts(routineId);

      // Firebase'den kullanıcı verilerini al
      final userRoutines = await getUserRoutines(userId);
      final userRoutine = userRoutines.firstWhere(
            (routine) => routine.id == routineId.toString(),
        orElse: () => FirebaseRoutines(
          id: routineId.toString(),
          name: localRoutine.name,
          description: localRoutine.description,
          targetedBodyPartIds: targetedBodyParts.map((t) => t.bodyPartId).toList(),
          workoutTypeId: localRoutine.workoutTypeId,
          exerciseIds: routineExercises.map((re) => re.exerciseId).toList(),
        ),
      );

      _logger.info('Routine with user data fetched: ${localRoutine.id}');

      return localRoutine.copyWith(
        isFavorite: userRoutine.isFavorite,
        isCustom: userRoutine.isCustom,
        userProgress: userRoutine.userProgress,
        lastUsedDate: userRoutine.lastUsedDate,
        userRecommended: userRoutine.userRecommended ?? false,
        targetedBodyParts: targetedBodyParts,
        routineExercises: routineExercises,
      );
    } catch (e, stackTrace) {
      _logger.severe('Error in getRoutineWithUserData', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> buildExerciseListForRoutine(
      Routines routine,
      ) async {
    try {
      Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart = {};

      // Rutin egzersizlerini sıralı şekilde al
      List<RoutineExercises> routineExercises =
      await getRoutineExercisesByRoutineId(routine.id);

      // Hedef kas gruplarını ve yüzdelerini al
      final targetedBodyParts = await _sqlProvider.getRoutineTargetedBodyParts(routine.id);
      Map<int, int> targetPercentages = Map.fromEntries(
          targetedBodyParts.map((t) => MapEntry(t.bodyPartId, t.targetPercentage))
      );

      for (var routineExercise in routineExercises) {
        Exercises? exercise = await getExerciseById(routineExercise.exerciseId);
        if (exercise != null) {
          // Egzersizin hedef kas gruplarını al
          final exerciseTargets = await _sqlProvider.getExerciseTargetedBodyParts(exercise.id);

          for (var target in exerciseTargets) {
            BodyParts? bodyPart = await _sqlProvider.getBodyPartById(target.bodyPartId);
            WorkoutTypes? workoutType = await _sqlProvider.getWorkoutTypeById(exercise.workoutTypeId);

            if (bodyPart != null) {
              Map<String, dynamic> exerciseDetails = {
                'id': exercise.id,
                'name': exercise.name,
                'description': exercise.description,
                'defaultWeight': exercise.defaultWeight,
                'defaultSets': exercise.defaultSets,
                'defaultReps': exercise.defaultReps,
                'workoutType': workoutType?.name ?? 'Unknown',
                'bodyPartName': bodyPart.name,
                'orderIndex': routineExercise.orderIndex,
                'targetPercentage': targetPercentages[bodyPart.id] ?? 0,
                'isPrimaryTarget': target.isPrimary,
                'exerciseTargetPercentage': target.targetPercentage
              };

              if (!exerciseListByBodyPart.containsKey(bodyPart.name)) {
                exerciseListByBodyPart[bodyPart.name] = [];
              }
              exerciseListByBodyPart[bodyPart.name]!.add(exerciseDetails);
            }
          }
        }
      }

      // Her vücut bölümü için egzersizleri sırala
      exerciseListByBodyPart.forEach((key, exercises) {
        exercises.sort((a, b) => a['orderIndex'].compareTo(b['orderIndex']));
      });

      return exerciseListByBodyPart;
    } catch (e, stackTrace) {
      _logger.severe('Error in buildExerciseListForRoutine', e, stackTrace);
      rethrow;
    }
  }

  Future<void> acceptWeeklyChallenge(String userId, int routineId) async {
    try {
      await _firebaseProvider.setWeeklyChallenge(
        userId: userId,
        routineId: routineId,
        acceptedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.severe('Error accepting weekly challenge', e);
      throw Exception('Haftalık meydan okuma kabul edilirken bir hata oluştu');
    }
  }

  /// Kullanıcıdan gelen frequency ve difficulty'ye göre önerilen rutinleri döndürür
  Future<List<Routines>> getRecommendedRoutines({
    required int frequency,
    required int difficulty,
    int? startDay,
  }) async {
    final allRoutines = await getAllRoutines();
    final List<Routines> filtered = [];
    for (final routine in allRoutines) {
      final freq = await _sqlProvider.getRoutineFrequency(routine.id);
      if (freq == null) continue;
      // Zorluk ve önerilen gün sayısı eşleşmeli
      if (routine.difficulty == difficulty && freq.recommendedFrequency == frequency) {
        filtered.add(routine);
      }
    }
    // Eğer tam eşleşme yoksa, zorluk eşleşen ve frequency yakın olanları da ekle
    if (filtered.isEmpty) {
      for (final routine in allRoutines) {
        final freq = await _sqlProvider.getRoutineFrequency(routine.id);
        if (freq == null) continue;
        if (routine.difficulty == difficulty && (freq.recommendedFrequency - frequency).abs() <= 1) {
          filtered.add(routine);
        }
      }
    }
    // Eğer hala yoksa, sadece zorluk eşleşenleri ekle
    if (filtered.isEmpty) {
      filtered.addAll(allRoutines.where((r) => r.difficulty == difficulty));
    }
    return filtered;
  }

  /// Belirli bir rutin listesini sadece workoutgoal (goalId) ile filtreler. İsteğe bağlı olarak frequency ve difficulty de filtreye dahil edilebilir.
  Future<List<Routines>> filterRoutinesByGoal({
    required List<Routines> routines,
    required List<int> goalIds,
    int? frequency,
    int? difficulty,
  }) async {
    final List<Routines> filtered = [];
    for (final routine in routines) {
      if (!goalIds.contains(routine.goalId)) continue;
      if (difficulty != null && routine.difficulty != difficulty) continue;
      if (frequency != null) {
        RoutineFrequency? freq;
        try {
          freq = await _sqlProvider.getRoutineFrequency(routine.id);
        } catch (e) {
          _logger.warning('Rutin [33m${routine.id}[0m için frekans verisi hatalı: $e');
          continue;
        }
        if (freq == null || freq.recommendedFrequency != frequency) continue;
      }
      filtered.add(routine);
    }
    return filtered;
  }

  /// Tüm WorkoutGoals kayıtlarını getirir
  Future<List<WorkoutGoals>> getAllWorkoutGoals() async {
    return await _sqlProvider.getAllWorkoutGoals();
  }

  Future<RoutineFrequency?> getRoutineFrequency(int routineId) async {
    return await _sqlProvider.getRoutineFrequency(routineId);
  }

  /// Bir WorkoutGoal için, ilişkili tüm rutinleri uyumluluk yüzdesine göre getirir.
  Future<List<Routines>> getRoutinesByGoalWithCompatibility(int goalId, {int minRecommendedPercentage = 0}) async {
    // 1. O goal ile ilişkili WorkoutTypeGoals kayıtlarını al
    final typeGoals = await _sqlProvider.getWorkoutTypeGoalPercentages(goalId);
    final compatibleTypeIds = typeGoals
        .map((tg) => tg['id'] as int)
        .toList();

    // 2. O goal ve bu workoutTypeId'ler için rutinleri getir
    final allRoutines = await _sqlProvider.getAllRoutines();
    final filtered = allRoutines.where((r) =>
      r.goalId == goalId && compatibleTypeIds.contains(r.workoutTypeId)
    ).toList();

    // 3. recommendedPercentage'a göre sıralama
    filtered.sort((a, b) {
      final aPercent = typeGoals.firstWhere((tg) => tg['id'] == a.workoutTypeId, orElse: () => {'recommendedPercentage': 0})['recommendedPercentage'] ?? 0;
      final bPercent = typeGoals.firstWhere((tg) => tg['id'] == b.workoutTypeId, orElse: () => {'recommendedPercentage': 0})['recommendedPercentage'] ?? 0;
      return bPercent.compareTo(aPercent);
    });

    return filtered;
  }
}