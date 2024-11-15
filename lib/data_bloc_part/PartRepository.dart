import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import '../data_provider/sql_provider.dart';
import '../data_provider/firebase_provider.dart';
import '../models/exercises.dart';
import '../models/BodyPart.dart';
import '../models/Parts.dart';
import '../models/PartExercises.dart';
import '../models/WorkoutType.dart';
import '../models/part_frequency.dart';
import '../firebase_class/firebase_parts.dart';

final _logger = Logger('PartRepository');

class PartRepository {
  final SQLProvider _sqlProvider;
  final FirebaseProvider _firebaseProvider;

  PartRepository(this._sqlProvider, this._firebaseProvider);

  // MARK: - Temel Part İşlemleri
  Future<List<Parts>> getAllParts() async {
    try {
      return await _sqlProvider.getAllParts();
    } catch (e, stackTrace) {
      _logger.severe('Error in getAllParts', e, stackTrace);
      rethrow;
    }
  }

  Future<Parts?> getPartById(int id) async {
    try {
      _logger.info("Fetching part with ID: $id");
      return await _sqlProvider.getPartById(id);
    } catch (e, stackTrace) {
      _logger.severe('Error in getPartById', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Parts>> getPartsSortedByName({bool ascending = true}) async {
    try {
      return await _sqlProvider.getPartsSortedByName(ascending: ascending);
    } catch (e, stackTrace) {
      _logger.severe('Error in getPartsSortedByName', e, stackTrace);
      rethrow;
    }
  }

  // MARK: - WorkoutType ve BodyPart İşlemleri
  Future<List<WorkoutTypes>> getAllWorkoutTypes() async {
    try {
      return await _sqlProvider.getAllWorkoutTypes();
    } catch (e, stackTrace) {
      _logger.severe('Error in getAllWorkoutTypes', e, stackTrace);
      rethrow;
    }
  }

  Future<List<BodyParts>> getAllBodyParts() async {
    try {
      return await _sqlProvider.getAllBodyParts();
    } catch (e, stackTrace) {
      _logger.severe('Error in getAllBodyParts', e, stackTrace);
      rethrow;
    }
  }

  // MARK: - Filtreleme İşlemleri
  Future<List<Parts>> getPartsByWorkoutType(int workoutTypeId) async {
    try {
      final allParts = await getAllParts();
      final filteredParts = <Parts>[];

      for (var part in allParts) {
        final exercises = await getPartExercisesByPartId(part.id);
        bool hasWorkoutType = false;

        for (var exercise in exercises) {
          final exerciseDetails = await getExerciseById(exercise.exerciseId);
          if (exerciseDetails?.workoutTypeId == workoutTypeId) {
            hasWorkoutType = true;
            break;
          }
        }

        if (hasWorkoutType) {
          filteredParts.add(part);
        }
      }

      return filteredParts;
    } catch (e, stackTrace) {
      _logger.severe('Error in getPartsByWorkoutType', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Parts>> getPartsByBodyPart(int bodyPartId) async {
    try {
      return await _sqlProvider.getPartsByBodyPart(bodyPartId);
    } catch (e, stackTrace) {
      _logger.severe('Error in getPartsByBodyPart', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Parts>> getPartsByDifficulty(int difficulty) async {
    try {
      return await _sqlProvider.getPartsByDifficulty(difficulty);
    } catch (e, stackTrace) {
      _logger.severe('Error in getPartsByDifficulty', e, stackTrace);
      rethrow;
    }
  }

  // MARK: - Egzersiz İşlemleri
  Future<List<PartExercise>> getAllPartExercises() async {
    try {
      return await _sqlProvider.getAllPartExercises();
    } catch (e, stackTrace) {
      _logger.severe('Error in getAllPartExercises', e, stackTrace);
      rethrow;
    }
  }

  Future<List<PartExercise>> getPartExercisesByPartId(int partId) async {
    try {
      return await _sqlProvider.getPartExercisesByPartId(partId);
    } catch (e, stackTrace) {
      _logger.severe('Error in getPartExercisesByPartId', e, stackTrace);
      rethrow;
    }
  }

  Future<Exercises?> getExerciseById(int id) async {
    try {
      return await _sqlProvider.getExerciseById(id);
    } catch (e, stackTrace) {
      _logger.severe('Error in getExerciseById', e, stackTrace);
      rethrow;
    }
  }

  // MARK: - Favori İşlemleri
  Future<bool> isPartFavorite(String userId, String partId) async {
    try {
      return await _firebaseProvider.isPartFavorite(userId, partId);
    } catch (e) {
      _logger.severe('Error checking part favorite status', e);
      return false;
    }
  }

  Future<void> togglePartFavorite(String userId, String partId, bool isFavorite) async {
    try {
      await _firebaseProvider.togglePartFavorite(userId, partId, isFavorite);
      _logger.info('Part favorite status updated successfully');
    } catch (e) {
      _logger.severe('Error updating part favorite status', e);
      throw Exception('Favori durumu güncellenirken bir hata oluştu: $e');
    }
  }

  // MARK: - Firebase İşlemleri
  Future<List<Parts>> getPartsWithUserData(String userId) async {
    try {
      final localParts = await getAllParts();
      final userParts = await _firebaseProvider.getUserParts(userId);

      return localParts.map((localPart) {
        final userPart = userParts.firstWhere(
              (up) => up.id == localPart.id.toString(),
          orElse: () => FirebaseParts(
            id: localPart.id.toString(),
            name: localPart.name,
            bodyPartId: localPart.bodyPartId,
            setType: localPart.setType,
            exerciseIds: localPart.exerciseIds.map((id) => id.toString()).toList(),
            additionalNotes: localPart.additionalNotes,
          ),
        );

        return localPart.copyWith(
          isFavorite: userPart.isFavorite,
          isCustom: userPart.isCustom,
          userProgress: userPart.userProgress,
          lastUsedDate: userPart.lastUsedDate,
          userRecommended: userPart.userRecommended,
          exerciseIds: userPart.exerciseIds.map(int.parse).toList(),
        );
      }).toList();
    } catch (e) {
      _logger.severe('Error in getPartsWithUserData', e);
      return getAllParts();
    }
  }

  // MARK: - Egzersiz Listesi Oluşturma
  Future<Map<String, List<Map<String, dynamic>>>> buildExerciseListForPart(Parts part) async {
    try {
      final exerciseListByBodyPart = <String, List<Map<String, dynamic>>>{};
      final partExercises = await getPartExercisesByPartId(part.id);

      for (var partExercise in partExercises) {
        final exercise = await getExerciseById(partExercise.exerciseId);
        if (exercise != null) {
          final bodyPart = await getBodyPartById(exercise.mainTargetedBodyPartId);
          final workoutType = await getWorkoutTypeById(exercise.workoutTypeId);

          if (bodyPart != null) {
            final exerciseDetails = {
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
      _logger.severe('Error in buildExerciseListForPart', e, stackTrace);
      rethrow;
    }
  }

  // MARK: - Body Part ve Workout Type İşlemleri
  Future<BodyParts?> getBodyPartById(int id) async {
    try {
      return await _sqlProvider.getBodyPartById(id);
    } catch (e, stackTrace) {
      _logger.severe('Error in getBodyPartById', e, stackTrace);
      rethrow;
    }
  }

  Future<WorkoutTypes?> getWorkoutTypeById(int id) async {
    try {
      return await _sqlProvider.getWorkoutTypeById(id);
    } catch (e, stackTrace) {
      _logger.severe('Error in getWorkoutTypeById', e, stackTrace);
      rethrow;
    }
  }

  // MARK: - Frequency İşlemleri
  Future<PartFrequency?> getPartFrequency(int partId) async {
    try {
      return await _sqlProvider.getPartFrequency(partId);
    } catch (e, stackTrace) {
      _logger.severe('Error getting part frequency', e, stackTrace);
      return null;
    }
  }
}