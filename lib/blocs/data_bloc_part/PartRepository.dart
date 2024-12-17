import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import '../../models/firebase_models/firebase_parts.dart';
import '../../models/sql_models/BodyPart.dart';
import '../../models/sql_models/PartExercises.dart';
import '../../models/sql_models/PartTargetedBodyParts.dart';
import '../../models/sql_models/Parts.dart';
import '../../models/sql_models/WorkoutType.dart';
import '../../models/sql_models/exercises.dart';
import '../../models/sql_models/part_frequency.dart';
import '../../utils/routine_helpers.dart';
import '../data_provider/sql_provider.dart';
import '../data_provider/firebase_provider.dart';
import '../data_provider_cache/app_cache.dart';


final _logger = Logger('PartRepository');

class PartRepository {
  final SQLProvider _sqlProvider;
  final FirebaseProvider _firebaseProvider;

  PartRepository(this._sqlProvider, this._firebaseProvider);


  final _bodyPartNamesCache = <int, String>{};
  final AppCache _cache = AppCache();

  //cache key'ler (ana listeler için)
  static const String PARTS_CACHE_KEY = 'all_parts';
  static const String EXERCISES_CACHE_KEY = 'all_exercises';
  static const String BODYPARTS_CACHE_KEY = 'all_bodyparts';
  static const String WORKOUTTYPE_CACHE_KEY = 'workout_types';
  static const String MAIN_BODYPARTS_KEY = 'main_bodyparts';

  // yardımcı
  static const String GROUPED_PARTS_CACHE_KEY = 'grouped_parts';
  static const String EXERCISE_LIST_CACHE_KEY = 'exercise_list';

  static const String PART_FREQUENCY_CACHE_KEY = 'part_frequency';
  static const String PART_DIFFICULTY_CACHE_KEY = 'part_difficulty';

  // İlişkisel sorgular için cache key
  static String partExercises(int partId) => 'part_exercises_$partId';
  static String partTargets(int partId) => 'part_targets_$partId';
  static String partsByBodyPart(int bodyPartId) => 'parts_by_bodypart_$bodyPartId';
  static String partFrequency(int partId) => 'part_frequency_$partId';
  static String bodyPartsByParent(int? parentId) => 'bodyparts_parent_$parentId';


// Exercise ilişkili sorgular
  static String exercisesByPart(int partId) => 'exercises_by_part_$partId';
  static String exerciseListForPart(int partId) => 'exercise_list_part_$partId';

// Arama ve filtreleme
  static String searchParts(String query) => 'search_parts_$query';
  static String partsWithExerciseRange(int min, int max) => 'parts_exercise_count_${min}_$max';

  Future<List<String>> getBodyPartNames(List<int> ids) async {
    final cacheKey = 'bodypart_names_${ids.join('_')}';

    // Cache kontrolü
    final cachedNames = _cache.get<List<String>>(cacheKey);
    if (cachedNames != null) {
      return cachedNames;
    }

    // Cache'de yoksa veritabanından al
    final names = await _sqlProvider.getBodyPartNamesByIds(ids);
    _cache.set(cacheKey, names, expiry: AppCache.BODY_PARTS_EXPIRY);

    return names;
  }

  Future<List<BodyParts>> getMainBodyParts() async {
    try {
      final cachedData = _cache.get<List<BodyParts>>(MAIN_BODYPARTS_KEY);
      if (cachedData != null) {
        _logger.info('Returning ${cachedData.length} main body parts from cache');
        return cachedData;
      }

      final result = await _sqlProvider.getMainBodyParts();
      _cache.set(MAIN_BODYPARTS_KEY, result, expiry: AppCache.BODY_PARTS_EXPIRY);
      _logger.info('Ana vücut bölümleri getirildi: ${result.length} adet');
      return result;
    } catch (e) {
      _logger.severe('Ana vücut bölümleri getirilirken hata oluştu', e);
      return [];
    }
  }

  Future<Map<int, List<Parts>>> getPartsGroupedByBodyPart() async {
    try {
      final cachedData = _cache.get<Map<int, List<Parts>>>(GROUPED_PARTS_CACHE_KEY);
      if (cachedData != null) {
        _logger.info('Returning grouped parts from cache');
        return cachedData;
      }

      final mainBodyParts = await getMainBodyParts();
      final result = <int, List<Parts>>{};

      await Future.wait(
          mainBodyParts.map((bodyPart) async {
            try {
              final parts = await getPartsByBodyPart(bodyPart.id);
              if (parts.isNotEmpty) {
                result[bodyPart.id] = parts;
              }
            } catch (e) {
              _logger.warning('Vücut bölümü ${bodyPart.id} için programlar alınırken hata: $e');
            }
          })
      );

      _cache.set(GROUPED_PARTS_CACHE_KEY, result, expiry: AppCache.JOIN_QUERY_EXPIRY);
      return result;
    } catch (e, stackTrace) {
      _logger.severe('Programlar gruplandırılırken hata', e, stackTrace);
      throw Exception('Programlar yüklenirken bir hata oluştu: $e');
    }
  }

  Future<List<PartTargetedBodyParts>> getPartTargetedBodyParts(int partId) async {
    try {
      final cacheKey = partTargets(partId);
      final cachedData = _cache.get<List<PartTargetedBodyParts>>(cacheKey);
      if (cachedData != null) {
        _logger.info('Returning ${cachedData.length} targeted body parts for part $partId from cache');
        return cachedData;
      }

      final targets = await _sqlProvider.getPartTargetedBodyParts(partId);
      _cache.set(cacheKey, targets, expiry: AppCache.JOIN_QUERY_EXPIRY);
      _logger.info('Fetched ${targets.length} targeted body parts for part: $partId');
      return targets;
    } catch (e, stackTrace) {
      _logger.severe('Error getting part targeted body parts', e, stackTrace);
      rethrow;
    }
  }

  Future<PartFrequency?> getPartFrequency(int partId) async {
    try {
      final cacheKey = partFrequency(partId);
      final cachedData = _cache.get<PartFrequency>(cacheKey);
      if (cachedData != null) {
        _logger.info('Returning frequency for part $partId from cache');
        return cachedData;
      }

      final frequency = await _sqlProvider.getPartFrequency(partId);
      if (frequency != null) {
        _cache.set(cacheKey, frequency, expiry: AppCache.PARTS_EXPIRY);
        _logger.info('Part frequency fetched for ID: $partId');
      }
      return frequency;
    } catch (e, stackTrace) {
      _logger.severe('Error getting part frequency', e, stackTrace);
      return null;
    }
  }

  Future<List<PartExercise>> getPartExercisesByPartId(int partId) async {
    try {
      final cacheKey = partExercises(partId);
      final cachedData = _cache.get<List<PartExercise>>(cacheKey);
      if (cachedData != null) {
        _logger.info('Returning ${cachedData.length} exercises for part $partId from cache');
        return cachedData;
      }

      final exercises = await _sqlProvider.getPartExercisesByPartId(partId);
      _cache.set(cacheKey, exercises, expiry: AppCache.JOIN_QUERY_EXPIRY);
      _logger.info('Fetched ${exercises.length} exercises for part: $partId');
      return exercises;
    } catch (e, stackTrace) {
      _logger.severe('Error in getPartExercisesByPartId', e, stackTrace);
      rethrow;
    }
  }
  //*
  Future<List<Parts>> getAllParts() async {
    try {
      // Cache kontrolü
      final cachedData = _cache.get<List<Parts>>(PARTS_CACHE_KEY);
      if (cachedData != null) {
        _logger.info('Returning ${cachedData.length} parts from cache');
        return cachedData;
      }

      // Cache'de yoksa veritabanından al
      final parts = await _sqlProvider.getAllParts();

      // Cache'e kaydet
      _cache.set(PARTS_CACHE_KEY, parts, expiry: AppCache.PARTS_EXPIRY);

      _logger.info('Fetched ${parts.length} parts from database');
      return parts;
    } catch (e, stackTrace) {
      _logger.severe('Error in getAllParts', e, stackTrace);
      rethrow;
    }
  }

  Future<List<BodyParts>> getAllBodyParts() async {
    try {
      final cachedData = _cache.get<List<BodyParts>>(BODYPARTS_CACHE_KEY);
      if (cachedData != null) {
        _logger.info('Returning ${cachedData.length} body parts from cache');
        return cachedData;
      }

      final bodyParts = await _sqlProvider.getAllBodyParts();
      _cache.set(BODYPARTS_CACHE_KEY, bodyParts, expiry: AppCache.BODY_PARTS_EXPIRY);

      _logger.info('Fetched ${bodyParts.length} body parts from database');
      return bodyParts;
    } catch (e, stackTrace) {
      _logger.severe('Error in getAllBodyParts', e, stackTrace);
      rethrow;
    }
  }

  Future<List<WorkoutTypes>> getAllWorkoutTypes() async {
    try {
      final cachedData = _cache.get<List<WorkoutTypes>>(WORKOUTTYPE_CACHE_KEY);
      if (cachedData != null) {
        _logger.info('Returning ${cachedData.length} workout types from cache');
        return cachedData;
      }

      final workoutTypes = await _sqlProvider.getAllWorkoutTypes();
      _cache.set(WORKOUTTYPE_CACHE_KEY, workoutTypes, expiry: AppCache.WORKOUT_TYPES_EXPIRY);

      _logger.info('Fetched ${workoutTypes.length} workout types from database');
      return workoutTypes;
    } catch (e, stackTrace) {
      _logger.severe('Error in getAllWorkoutTypes', e, stackTrace);
      rethrow;
    }
  }

  Future<Parts?> getPartById(int id) async {
    try {
      _logger.info('Fetching part with ID: $id');
      final part = await _sqlProvider.getPartById(id);

      if (part == null) {
        _logger.warning('No part found with ID: $id');
        return null;
      }

      _logger.info('Successfully fetched part: ${part.name}');
      return part;
    } catch (e, stackTrace) {
      _logger.severe('Error in getPartById', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Parts>> getPartsSortedByName({bool ascending = true}) async {
    try {
      final parts = await _sqlProvider.getPartsSortedByName(ascending: ascending);
      _logger.info('Fetched ${parts.length} parts sorted by name (${ascending ? 'ascending' : 'descending'})');
      return parts;
    } catch (e, stackTrace) {
      _logger.severe('Error in getPartsSortedByName', e, stackTrace);
      rethrow;
    }
  }

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
      final parts = await _sqlProvider.getPartsByBodyPart(bodyPartId);
      _logger.info('Fetched ${parts.length} parts for body part: $bodyPartId');
      return parts;
    } catch (e, stackTrace) {
      _logger.severe('Error in getPartsByBodyPart', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Parts>> getPartsByDifficulty(int difficulty) async {
    try {
      final parts = await _sqlProvider.getPartsByDifficulty(difficulty);
      _logger.info('Fetched ${parts.length} parts with difficulty: $difficulty');
      return parts;
    } catch (e, stackTrace) {
      _logger.severe('Error in getPartsByDifficulty', e, stackTrace);
      rethrow;
    }
  }



  Future<Exercises?> getExerciseById(int id) async {
    try {
      final exercise = await _sqlProvider.getExerciseById(id);
      if (exercise != null) {
        _logger.info('Exercise fetched successfully: ${exercise.name}');
      } else {
        _logger.warning('No exercise found with ID: $id');
      }
      return exercise;
    } catch (e, stackTrace) {
      _logger.severe('Error in getExerciseById', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> isPartFavorite(String userId, String partId) async {
    try {
      final isFavorite = await _firebaseProvider.isPartFavorite(userId, partId);
      _logger.info('Part favorite status checked: $partId, result: $isFavorite');
      return isFavorite;
    } catch (e, stackTrace) {
      _logger.severe('Error checking part favorite status', e, stackTrace);
      return false;
    }
  }

  Future<void> togglePartFavorite(String userId, String partId, bool isFavorite) async {
    try {
      await _firebaseProvider.togglePartFavorite(userId, partId, isFavorite);
      _logger.info('Part favorite status updated: $partId to $isFavorite');
    } catch (e, stackTrace) {
      _logger.severe('Error updating part favorite status', e, stackTrace);
      throw Exception('Favori durumu güncellenirken bir hata oluştu');
    }
  }

  Future<List<Parts>> getPartsWithUserData(String userId) async {
    try {
      final localParts = await getAllParts();
      final userParts = await _firebaseProvider.getUserParts(userId);

      final updatedParts = localParts.map((localPart) {
        final userPart = userParts.firstWhere(
              (up) => up.id == localPart.id.toString(),
          orElse: () => FirebaseParts(
            id: localPart.id.toString(),
            name: localPart.name,
            targetedBodyPartIds: localPart.targetedBodyPartIds,
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
          targetedBodyPartIds: userPart.targetedBodyPartIds,
        );
      }).toList();

      _logger.info('Fetched ${updatedParts.length} parts with user data');
      return updatedParts;
    } catch (e) {
      _logger.severe('Error in getPartsWithUserData', e);
      return getAllParts();
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> buildExerciseListForPart(Parts part) async {
    try {
      final db = await _sqlProvider.database;
      return await db.transaction((txn) async {
        final exerciseListByBodyPart = <String, List<Map<String, dynamic>>>{};

        // Tek sorguda tüm ilişkili verileri al
        final List<Map<String, dynamic>> maps = await txn.rawQuery('''
        SELECT 
          e.*,
          b.name as bodyPartName,
          etb.targetPercentage,
          etb.isPrimary
        FROM PartExercises pe
        INNER JOIN Exercises e ON pe.exerciseId = e.id
        INNER JOIN ExerciseTargetedBodyParts etb ON e.id = etb.exerciseId
        INNER JOIN BodyParts b ON etb.bodyPartId = b.id
        WHERE pe.partId = ?
        ORDER BY pe.orderIndex ASC, etb.targetPercentage DESC
      ''', [part.id]);

        // Sonuçları grupla
        for (var map in maps) {
          final bodyPartName = map['bodyPartName'] as String;

          if (!exerciseListByBodyPart.containsKey(bodyPartName)) {
            exerciseListByBodyPart[bodyPartName] = [];
          }

          exerciseListByBodyPart[bodyPartName]!.add({
            'id': map['id'] as int,
            'name': map['name'] as String,
            'description': map['description'] as String?,
            'defaultWeight': map['defaultWeight'] as double,
            'defaultSets': map['defaultSets'] as int,
            'defaultReps': map['defaultReps'] as int,
            'workoutTypeId': map['workoutTypeId'] as int,
            'gifUrl': map['gifUrl'] as String?,
            'targetPercentage': map['targetPercentage'] as int,
            'isPrimary': map['isPrimary'] == 1,
          });
        }

        _logger.info('Built exercise list for part ${part.id} with ${maps.length} exercises');
        return exerciseListByBodyPart;
      });
    } catch (e, stackTrace) {
      _logger.severe('Error in buildExerciseListForPart', e, stackTrace);
      rethrow;
    }
  }


  Future<String> getBodyPartName(int bodyPartId) async {
    if (_bodyPartNamesCache.containsKey(bodyPartId)) {
      return _bodyPartNamesCache[bodyPartId]!;
    }

    final name = await _sqlProvider.getBodyPartName(bodyPartId);
    _bodyPartNamesCache[bodyPartId] = name;
    return name;
  }

  Future<BodyParts?> getBodyPartById(int id) async {
    try {
      final bodyPart = await _sqlProvider.getBodyPartById(id);
      if (bodyPart != null) {
        _logger.info('Body part fetched: ${bodyPart.name}');
      } else {
        _logger.warning('No body part found with ID: $id');
      }
      return bodyPart;
    } catch (e, stackTrace) {
      _logger.severe('Error getting body part', e, stackTrace);
      rethrow;
    }
  }

  Future<WorkoutTypes?> getWorkoutTypeById(int id) async {
    try {
      final workoutType = await _sqlProvider.getWorkoutTypeById(id);
      if (workoutType != null) {
        _logger.info('Workout type fetched: ${workoutType.name}');
      } else {
        _logger.warning('No workout type found with ID: $id');
      }
      return workoutType;
    } catch (e, stackTrace) {
      _logger.severe('Error getting workout type', e, stackTrace);
      rethrow;
    }
  }


  Future<List<String>> getPartTargetedBodyPartsName(int partId) async {
    try {
      final names = await _sqlProvider.getPartTargetedBodyPartsName(partId);
      _logger.info(' getPartTargetedBodyPartsName, Fetched ${names.length} body part names for part: $partId');
      return names;
    } catch (e, stackTrace) {
      _logger.severe('Error getting part targeted body part names, getPartTargetedBodyPartsName', e, stackTrace);
      rethrow;
    }
  }

  Future<List<PartTargetedBodyParts>> getPrimaryTargetedParts(int bodyPartId) async {
    try {
      final targets = await _sqlProvider.getPrimaryTargetedPartsForBodyPart(bodyPartId);
      _logger.info('Fetched ${targets.length} primary targets for body part: $bodyPartId');
      return targets;
    } catch (e, stackTrace) {
      _logger.severe('Error getting primary targeted parts', e, stackTrace);
      rethrow;
    }
  }

  Future<List<PartTargetedBodyParts>> getSecondaryTargetedParts(int bodyPartId) async {
    try {
      final targets = await _sqlProvider.getSecondaryTargetedPartsForBodyPart(bodyPartId);
      _logger.info('Fetched ${targets.length} secondary targets for body part: $bodyPartId');
      return targets;
    } catch (e, stackTrace) {
      _logger.severe('Error getting secondary targeted parts', e, stackTrace);
      rethrow;
    }
  }

  Future<List<String>> getBodyPartNamesByIds(List<int> bodyPartIds) async {
    try {
      final names = await _sqlProvider.getBodyPartNamesByIds(bodyPartIds);
      _logger.info('Fetched ${names.length} body part names by getBodyPartNamesByIds ');
      return names;
    } catch (e, stackTrace) {
      _logger.severe('Error getting body part names by getBodyPartNamesByIds', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Parts>> getPartsWithExerciseCount(int minCount, int maxCount) async {
    try {
      final parts = await _sqlProvider.getPartsWithExerciseCount(minCount, maxCount);
      _logger.info('Fetched ${parts.length} parts with exercise count between $minCount and $maxCount');
      return parts;
    } catch (e, stackTrace) {
      _logger.severe('Error getting parts with exercise count', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Parts>> getRelatedParts(int partId) async {
    try {
      final parts = await _sqlProvider.getRelatedParts(partId);
      _logger.info('Fetched ${parts.length} related parts for part: $partId');
      return parts;
    } catch (e, stackTrace) {
      _logger.severe('Error getting related parts', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Parts>> getPartsWithMultipleTargets() async {
    try {
      final parts = await _sqlProvider.getPartsWithMultipleTargets();
      _logger.info('Fetched ${parts.length} parts with multiple targets');
      return parts;
    } catch (e, stackTrace) {
      _logger.severe('Error getting parts with multiple targets', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Parts>> getPartsBySetType(SetType setType) async {
    try {
      final parts = await _sqlProvider.getPartsBySetType(setType);
      _logger.info('Fetched ${parts.length} parts with set type: ${setType.name}');
      return parts;
    } catch (e, stackTrace) {
      _logger.severe('Error getting parts by set type', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Parts>> searchPartsByName(String name) async {
    try {
      return await _sqlProvider.searchPartsByName(name);
    } catch (e, stackTrace) {
      _logger.severe('Error in searchPartsByName', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Parts>> getPartsWithTargetedBodyParts(int bodyPartId, {bool isPrimary = true}) async {
    try {
      final parts = await _sqlProvider.getPartsWithTargetedBodyParts(bodyPartId, isPrimary: isPrimary);
      _logger.info('Fetched ${parts.length} parts targeting body part: $bodyPartId (isPrimary: $isPrimary)');
      return parts;
    } catch (e, stackTrace) {
      _logger.severe('Error in getPartsWithTargetedBodyParts', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Parts>> getPartsWithTargetPercentage(int bodyPartId, int minPercentage) async {
    try {
      if (minPercentage < 0 || minPercentage > 100) {
        throw ArgumentError('Target percentage must be between 0 and 100');
      }

      final parts = await _sqlProvider.getPartsWithTargetPercentage(bodyPartId, minPercentage);
      _logger.info('Fetched ${parts.length} parts with min target percentage $minPercentage% for body part: $bodyPartId');
      return parts;
    } catch (e, stackTrace) {
      _logger.severe('Error in getPartsWithTargetPercentage', e, stackTrace);
      rethrow;
    }
  }

  Future<List<PartTargetedBodyParts>> getPrimaryTargetedPartsForBodyPart(int bodyPartId) async {
    try {
      final result = await _sqlProvider.getPrimaryTargetedPartsForBodyPart(bodyPartId);
      _logger.info('Primary hedef parçalar getirildi: ${result.length} adet');
      return result;
    } catch (e) {
      _logger.severe('Primary hedef parçalar getirilirken hata oluştu', e);
      return [];
    }
  }

  Future<List<PartTargetedBodyParts>> getSecondaryTargetedPartsForBodyPart(int bodyPartId) async {
    try {
      final result = await _sqlProvider.getSecondaryTargetedPartsForBodyPart(bodyPartId);
      _logger.info('Secondary hedef parçalar getirildi: ${result.length} adet');
      return result;
    } catch (e) {
      _logger.severe('Secondary hedef parçalar getirilirken hata oluştu', e);
      return [];
    }
  }

  Future<List<BodyParts>> getBodyPartsByParentId(int? parentId) async {
    try {
      final result = await _sqlProvider.getBodyPartsByParentId(parentId);
      _logger.info('${parentId ?? "Ana"} ID\'li vücut bölümünün alt grupları getirildi: ${result.length} adet');
      return result;
    } catch (e) {
      _logger.severe('Alt vücut bölümleri getirilirken hata oluştu', e);
      return [];
    }
  }

  Future<int> getPartExercisesCount() async {
    try {
      final count = await _sqlProvider.getPartExercisesCount();
      _logger.info('Total part exercises count: $count');
      return count;
    } catch (e, stackTrace) {
      _logger.severe('Error getting part exercises count', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updatePartExercisesOrder(int partId, List<PartExercise> newOrder) async {
    try {
      await _sqlProvider.updatePartExercisesOrder(partId, newOrder);
      _logger.info('Updated exercise order for part: $partId with ${newOrder.length} exercises');
    } catch (e, stackTrace) {
      _logger.severe('Error updating part exercises order', e, stackTrace);
      rethrow;
    }
  }

  Future<int?> getDifficultyForPart(int partId) async {
    try {
      final difficulty = await _sqlProvider.getDifficultyForPart(partId);
      if (difficulty != null) {
        _logger.info('Fetched difficulty for part $partId: $difficulty');
      } else {
        _logger.warning('No difficulty found for part: $partId');
      }
      return difficulty;
    } catch (e, stackTrace) {
      _logger.severe('Error getting difficulty for part', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updatePartTargets({
    required String userId,
    required int partId,
    required List<Map<String, dynamic>> targetedBodyParts,
  }) async {
    try {
      await _firebaseProvider.updatePartTargets(
        userId: userId,
        partId: partId.toString(),
        targetedBodyParts: targetedBodyParts,
      );
      _logger.info('Updated targets for part: $partId with ${targetedBodyParts.length} targets');
    } catch (e, stackTrace) {
      _logger.severe('Error updating part targets', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deletePartTarget({
    required String userId,
    required int partId,
    required int bodyPartId,
  }) async {
    try {
      await _firebaseProvider.deletePartTarget(
        userId: userId,
        partId: partId.toString(),
        bodyPartId: bodyPartId,
      );
      _logger.info('Deleted target bodyPartId: $bodyPartId from part: $partId');
    } catch (e, stackTrace) {
      _logger.severe('Error deleting part target', e, stackTrace);
      rethrow;
    }
  }

  }
