import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import '../data_provider/sql_provider.dart';
import '../data_provider/firebase_provider.dart';
import '../models/routines.dart';
import '../models/exercises.dart';
import '../models/BodyPart.dart';
import '../models/WorkoutType.dart';
import '../models/RoutineExercises.dart';
import '../firebase_class/firebase_routines.dart';
import '../firebase_class/RoutineHistory.dart';

final _logger = Logger('RoutineRepository');

class RoutineRepository {
  final SQLProvider _sqlProvider;
  final FirebaseProvider _firebaseProvider;

  RoutineRepository(this._sqlProvider, this._firebaseProvider);

  // MARK: - Temel Rutin İşlemleri
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

  // MARK: - Filtreleme İşlemleri
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
      return await _sqlProvider.getRoutinesByMainTargetedBodyPart(mainTargetedBodyPartId);
    } catch (e, stackTrace) {
      _logger.severe('Error in getRoutinesByMainTargetedBodyPart', e, stackTrace);
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

  // MARK: - WorkoutType İşlemleri
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

  // MARK: - Egzersiz İşlemleri
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

  // MARK: - Firebase İşlemleri
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

  // MARK: - Rutin Geçmişi
  Future<void> addRoutineHistory(RoutineHistory history) async {
    try {
      await _firebaseProvider.addRoutineHistory(history);
    } catch (e, stackTrace) {
      _logger.severe('Error adding routine history', e, stackTrace);
      rethrow;
    }
  }

  // MARK: - Veri Birleştirme
  Future<List<Routines>> getRoutinesWithUserData(String userId) async {
    try {
      List<Routines> localRoutines = await getAllRoutines();
      _logger.info("Yerel rutinler yüklendi: ${localRoutines.length}");

      List<FirebaseRoutines> userRoutines = await getUserRoutines(userId);
      _logger.info("Kullanıcı rutinleri yüklendi: ${userRoutines.length}");

      List<Routines> combinedRoutines = localRoutines.map((localRoutine) {
        try {
          FirebaseRoutines? matchingUserRoutine = userRoutines.firstWhere(
                (userRoutine) => userRoutine.id == localRoutine.id.toString(),
            orElse: () => FirebaseRoutines(
              id: localRoutine.id.toString(),
              name: localRoutine.name,
              description: localRoutine.description,
              mainTargetedBodyPartId: localRoutine.mainTargetedBodyPartId,
              workoutTypeId: localRoutine.workoutTypeId,
              exerciseIds: [],
            ),
          );

          return localRoutine.copyWith(
            isFavorite: matchingUserRoutine.isFavorite,
            isCustom: matchingUserRoutine.isCustom,
            userProgress: matchingUserRoutine.userProgress,
            lastUsedDate: matchingUserRoutine.lastUsedDate,
            userRecommended: matchingUserRoutine.userRecommended ?? false,
          );
        } catch (e, stackTrace) {
          _logger.warning(
            'Rutin birleştirme hatası: ${localRoutine.id}',
            e,
            stackTrace,
          );
          return localRoutine;
        }
      }).toList();

      _logger.info("Toplam birleştirilmiş rutin: ${combinedRoutines.length}");
      return combinedRoutines;
    } catch (e, stackTrace) {
      _logger.severe('Error in getRoutinesWithUserData', e, stackTrace);
      rethrow;
    }
  }


  // RoutineRepository sınıfı içine eklenecek metod

  Future<Routines?> getRoutineWithUserData(String userId, int routineId) async {
    try {
      // Yerel rutini al
      Routines? localRoutine = await getRoutineById(routineId);
      if (localRoutine == null) return null;

      // Rutin egzersizlerini al
      final routineExercises = await getRoutineExercisesByRoutineId(routineId);

      // Firebase'den kullanıcı verilerini al
      final userRoutines = await getUserRoutines(userId);
      final userRoutine = userRoutines.firstWhere(
            (routine) => routine.id == routineId.toString(),
        orElse: () => FirebaseRoutines(
          id: routineId.toString(),
          name: localRoutine.name,
          description: localRoutine.description,
          mainTargetedBodyPartId: localRoutine.mainTargetedBodyPartId,
          workoutTypeId: localRoutine.workoutTypeId,
          exerciseIds: routineExercises.map((re) => re.exerciseId.toString()).toList(),
        ),
      );

      _logger.info('Routine with user data fetched: ${localRoutine.id}');

      // Yerel ve kullanıcı verilerini birleştir
      return localRoutine.copyWith(
        isFavorite: userRoutine.isFavorite,
        isCustom: userRoutine.isCustom,
        userProgress: userRoutine.userProgress,
        lastUsedDate: userRoutine.lastUsedDate,
        userRecommended: userRoutine.userRecommended ?? false,
      );
    } catch (e, stackTrace) {
      _logger.severe('Error in getRoutineWithUserData', e, stackTrace);
      rethrow;
    }
  }

  // MARK: - Egzersiz Listesi Oluşturma
  Future<Map<String, List<Map<String, dynamic>>>> buildExerciseListForRoutine(
      Routines routine,
      ) async {
    try {
      Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart = {};
      List<RoutineExercises> routineExercises =
      await getRoutineExercisesByRoutineId(routine.id);

      for (var routineExercise in routineExercises) {
        Exercises? exercise = await getExerciseById(routineExercise.exerciseId);
        if (exercise != null) {
          BodyParts? bodyPart =
          await _sqlProvider.getBodyPartById(exercise.mainTargetedBodyPartId);
          WorkoutTypes? workoutType =
          await _sqlProvider.getWorkoutTypeById(exercise.workoutTypeId);

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
            };

            if (!exerciseListByBodyPart.containsKey(bodyPart.name)) {
              exerciseListByBodyPart[bodyPart.name] = [];
            }
            exerciseListByBodyPart[bodyPart.name]!.add(exerciseDetails);
          }
        }
      }
      return exerciseListByBodyPart;
    } catch (e, stackTrace) {
      _logger.severe('Error in buildExerciseListForRoutine', e, stackTrace);
      rethrow;
    }
  }

  // MARK: - Haftalık Challenge
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
}