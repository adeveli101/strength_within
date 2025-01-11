import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/firebase_models/RoutineHistory.dart';
import '../../models/firebase_models/firebase_parts.dart';
import '../../models/firebase_models/firebase_routines.dart';
import '../../models/firebase_models/user_ai_profile.dart';
import '../../models/firebase_models/user_schedule.dart';
import '../data_provider/firebase_provider.dart';
import '../data_provider/sql_provider.dart';



class FirebaseProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('FirebaseProvider');

  // MARK: - Auth Operations
  Future<String?> signInAnonymously() async {
    try {
      // 1. Önce anonim giriş yap
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        // 2. Firestore'da kullanıcı dokümanını kontrol et
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          // Kullanıcı varsa sadece son giriş tarihini güncelle
          await userDoc.reference.update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Yeni kullanıcı oluştur
          await userDoc.reference.set({
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }
        return user.uid;
      }
    } catch (e) {
      _logger.severe('Auth error', e);
    }
    return null;
  }



  Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceData = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceData = '${androidInfo.model}-${androidInfo.id}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceData = '${iosInfo.model}-${iosInfo.identifierForVendor ?? ''}';
    }

    return sha256.convert(utf8.encode(deviceData)).toString();
  }

  Future<bool> validateDeviceId(String userId, String deviceId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .get();
    return doc.data()?['deviceId'] == deviceId;
  }



  ///latest ai update.
  ///


  Future<void> addUserPrediction(String userId, Map<String, dynamic> prediction) async {
    try {
      final batch = _firestore.batch();

      final userPredictions = _firestore
          .collection('users')
          .doc(userId)
          .collection('predictions');

      batch.set(
        userPredictions.doc('latest'),
        prediction,
      );

      batch.set(
        userPredictions.doc('history'),
        {
          'predictions': FieldValue.arrayUnion([prediction])
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      _logger.info('AI prediction saved for user: $userId');
    } catch (e) {
      _logger.severe('Error saving prediction', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserPredictionHistory(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('predictions')
          .doc('history')
          .get();

      if (!doc.exists) return [];

      final data = doc.data();
      return List<Map<String, dynamic>>.from(data?['predictions'] ?? []);
    } catch (e) {
      _logger.severe('Error getting prediction history', e);
      rethrow;
    }
  }

  Future<UserAIProfile?> getLatestUserPrediction(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('predictions')
          .doc('latest')
          .get();

      if (!doc.exists) return null;

      // Dönüşüm işlemi
      return UserAIProfile.fromFirestore(doc);
    } catch (e) {
      _logger.severe('Error getting latest prediction', e);
      rethrow;
    }
  }


///






  // MARK: - Schedule Operations
  Future<void> addUserSchedule(UserSchedule schedule) async {
    try {
      final batch = _firestore.batch();

      // Schedule dokümanını ekle
      final scheduleRef = _firestore
          .collection('users')
          .doc(schedule.userId)
          .collection('schedules')
          .doc(schedule.id);

      batch.set(scheduleRef, {
        ...schedule.toFirestore(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Kullanıcı metadata'sını güncelle
      final userRef = _firestore.collection('users').doc(schedule.userId);
      batch.update(userRef, {
        'lastScheduleUpdate': FieldValue.serverTimestamp(),
        'scheduleCount': FieldValue.increment(1)
      });

      await batch.commit();
      _logger.info('Schedule added with ID: ${schedule.id}');
    } catch (e) {
      _logger.severe('Error adding schedule', e);
      rethrow;
    }
  }

  Future<void> updateUserSchedule(UserSchedule schedule) async {
    try {
      final batch = _firestore.batch();

      final scheduleRef = _firestore
          .collection('users')
          .doc(schedule.userId)
          .collection('schedules')
          .doc(schedule.id);

      batch.update(scheduleRef, {
        ...schedule.toFirestore(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      _logger.info('Schedule updated: ${schedule.id}');
    } catch (e) {
      _logger.severe('Error updating schedule', e);
      rethrow;
    }
  }

  Future<void> deleteUserSchedule(String userId, String scheduleId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId)
          .delete();

      _logger.info('Schedule deleted: $scheduleId');
    } catch (e) {
      _logger.severe('Error deleting schedule', e);
      rethrow;
    }
  }

  Future<List<UserSchedule>> getUserSchedules(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .where('isActive', isEqualTo: true)
          .orderBy('lastUpdated', descending: true)
          .get();

      List<UserSchedule> schedules = snapshot.docs
          .map((doc) => UserSchedule.fromFirestore(doc))
          .toList();

      _logger.info('Fetched ${schedules.length} active schedules for user: $userId');
      return schedules;
    } catch (e) {
      _logger.severe('Error getting user schedules', e);
      return [];
    }
  }

  Future<void> updateUserProgress(
      String userId,
      String itemId,
      String type,
      int progress,
      ) async {
    try {
      final batch = _firestore.batch();
      final collectionName = type == 'part' ? 'parts' : 'routines';

      // İlgili dokümanı güncelle
      final itemRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(collectionName)
          .doc(itemId);

      batch.update(itemRef, {
        'userProgress': progress,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Kullanıcı metadata'sını güncelle
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'lastProgressUpdate': FieldValue.serverTimestamp(),
        'totalProgress': FieldValue.increment(progress),
      });

      await batch.commit();
      _logger.info('Progress updated for $type: $itemId to $progress%');
    } catch (e) {
      _logger.severe('Error updating progress', e);
      rethrow;
    }
  }

  Future<void> updateLastUsedDate(
      String userId,
      String itemId,
      String type,
      ) async {
    try {
      final collectionName = type == 'part' ? 'parts' : 'routines';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(collectionName)
          .doc(itemId)
          .update({
        'lastUsedDate': FieldValue.serverTimestamp(),
      });

      _logger.info('Last used date updated for $type: $itemId');
    } catch (e) {
      _logger.severe('Error updating last used date', e);
      rethrow;
    }
  }

  Future<void> toggleFavorite(
      String userId,
      String itemId,
      String type,
      bool isFavorite,
      ) async {
    try {
      final collectionName = type == 'part' ? 'parts' : 'routines';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(collectionName)
          .doc(itemId)
          .update({
        'isFavorite': isFavorite,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _logger.info('Favorite status updated for $type: $itemId');
    } catch (e) {
      _logger.severe('Error updating favorite status', e);
      rethrow;
    }
  }

  Future<bool> isFavorite(
      String userId,
      String itemId,
      String type,
      ) async {
    try {
      final collectionName = type == 'part' ? 'parts' : 'routines';
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection(collectionName)
          .doc(itemId)
          .get();

      return doc.exists && doc.data()?['isFavorite'] == true;
    } catch (e) {
      _logger.severe('Error checking favorite status', e);
      return false;
    }
  }

  Future<void> setWeeklyChallenge({
    required String userId,
    required int routineId,
    required DateTime acceptedAt,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('weeklyChallenge')
          .doc(routineId.toString())
          .set({
        'routineId': routineId,
        'acceptedAt': Timestamp.fromDate(acceptedAt),
        'status': 'accepted',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _logger.info('Weekly challenge set for routine: $routineId');
    } catch (e) {
      _logger.severe('Error setting weekly challenge', e);
      rethrow;
    }
  }

  Future<void> updateExerciseCompletion(
      String userId,
      String exerciseId,
      bool isCompleted,
      DateTime completionDate,
      {Map<String, dynamic>? additionalData}
      ) async {
    try {
      final data = {
        'isCompleted': isCompleted,
        'completionDate': Timestamp.fromDate(completionDate),
        'lastUpdated': FieldValue.serverTimestamp(),
        if (additionalData != null) ...additionalData,
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('exerciseProgress')
          .doc(exerciseId)
          .set(data, SetOptions(merge: true));

      _logger.info('Exercise completion updated: $exerciseId');
    } catch (e) {
      _logger.severe('Error updating exercise completion', e);
      rethrow;
    }
  }

  Future<List<FirebaseParts>> getUserParts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .orderBy('lastUpdated', descending: true)
          .get();

      List<FirebaseParts> parts = snapshot.docs
          .map((doc) => FirebaseParts.fromFirestore(doc))
          .toList();

      _logger.info('Fetched ${parts.length} parts for user: $userId');
      return parts;
    } catch (e) {
      _logger.severe('Error getting user parts', e);
      return [];
    }
  }

  Future<void> updatePartTargets({
    required String userId,
    required String partId,
    required List<Map<String, dynamic>> targetedBodyParts,
  }) async {
    try {
      final batch = _firestore.batch();

      // Part dokümanını güncelle
      final partRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId);

      batch.update(partRef, {
        'targetedBodyPartIds': targetedBodyParts.map((t) => t['bodyPartId']).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Metadata güncelle
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'lastPartUpdate': FieldValue.serverTimestamp(),
        'totalTargetedMuscles': FieldValue.increment(targetedBodyParts.length),
      });

      await batch.commit();
      _logger.info('Part targets updated: $partId with ${targetedBodyParts.length} targets');
    } catch (e) {
      _logger.severe('Error updating part targets', e);
      rethrow;
    }
  }

  Future<void> deletePartTarget({
    required String userId,
    required String partId,
    required int bodyPartId,
  }) async {
    try {
      final batch = _firestore.batch();

      final partRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId);

      final doc = await partRef.get();
      if (!doc.exists) throw Exception('Part not found');

      final currentTargets = List<dynamic>.from(doc.data()?['targetedBodyPartIds'] ?? []);
      currentTargets.remove(bodyPartId);

      batch.update(partRef, {
        'targetedBodyPartIds': currentTargets,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'lastPartUpdate': FieldValue.serverTimestamp(),
        'totalTargetedMuscles': FieldValue.increment(-1),
      });

      await batch.commit();
      _logger.info('Part target deleted: $partId, bodyPartId: $bodyPartId');
    } catch (e) {
      _logger.severe('Error deleting part target', e);
      rethrow;
    }
  }

  Future<void> addOrUpdateUserPart(String userId, FirebaseParts part) async {
    try {
      final batch = _firestore.batch();

      // Part dokümanını ekle/güncelle
      final partRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(part.id);

      batch.set(partRef, {
        ...part.toFirestore(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Kullanıcı metadata'sını güncelle
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'lastPartUpdate': FieldValue.serverTimestamp(),
        'partCount': FieldValue.increment(1)
      });

      await batch.commit();
      _logger.info('Part added/updated with ID: ${part.id}');
    } catch (e) {
      _logger.severe('Error adding/updating part', e);
      rethrow;
    }
  }

  Future<bool> isPartFavorite(String userId, String partId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId)
          .get();

      final result = doc.exists && doc.data()?['isFavorite'] == true;
      _logger.info('Part favorite status checked: $partId, result: $result');
      return result;
    } catch (e) {
      _logger.severe('Error checking part favorite status', e);
      return false;
    }
  }

  Future<void> togglePartFavorite(
      String userId,
      String partId,
      bool isFavorite,
      ) async {
    try {
      final batch = _firestore.batch();

      // Part dokümanını güncelle
      final partRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId);

      batch.update(partRef, {
        'isFavorite': isFavorite,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Kullanıcı metadata'sını güncelle
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'lastFavoriteUpdate': FieldValue.serverTimestamp(),
        'favoritesCount': FieldValue.increment(isFavorite ? 1 : -1),
      });

      await batch.commit();
      _logger.info('Part favorite status updated: $partId to $isFavorite');
    } catch (e) {
      _logger.severe('Error updating part favorite', e);
      rethrow;
    }
  }

  Future<void> updatePartProgress(
      String userId,
      String partId,
      int progress,
      ) async {
    try {
      final batch = _firestore.batch();

      // Part dokümanını güncelle
      final partRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId);

      batch.update(partRef, {
        'userProgress': progress,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Kullanıcı metadata'sını güncelle
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'lastProgressUpdate': FieldValue.serverTimestamp(),
        'totalPartsProgress': FieldValue.increment(progress),
      });

      await batch.commit();
      _logger.info('Part progress updated: $partId to $progress%');
    } catch (e) {
      _logger.severe('Error updating part progress', e);
      rethrow;
    }
  }

  Future<List<UserSchedule>> getSchedulesForDay(
      String userId,
      int weekday,
      ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .where('selectedDays', arrayContains: weekday)
          .where('isActive', isEqualTo: true)
          .orderBy('lastUpdated', descending: true)
          .get();

      List<UserSchedule> schedules = snapshot.docs
          .map((doc) => UserSchedule.fromFirestore(doc))
          .toList();

      _logger.info('Fetched ${schedules.length} schedules for weekday: $weekday');
      return schedules;
    } catch (e) {
      _logger.severe('Error getting schedules for day', e);
      return [];
    }
  }

  Future<void> updateScheduleStatus(
      String userId,
      String scheduleId,
      bool isActive,
      ) async {
    try {
      final batch = _firestore.batch();

      // Program dokümanını güncelle
      final scheduleRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId);

      batch.update(scheduleRef, {
        'isActive': isActive,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Kullanıcı metadata'sını güncelle
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'lastScheduleUpdate': FieldValue.serverTimestamp(),
        'activeScheduleCount': FieldValue.increment(isActive ? 1 : -1),
      });

      await batch.commit();
      _logger.info('Schedule status updated: $scheduleId to $isActive');
    } catch (e) {
      _logger.severe('Error updating schedule status', e);
      rethrow;
    }
  }

// MARK: - Routine Operations
  Future<void> addRoutineHistory(RoutineHistory history) async {
    try {
      final batch = _firestore.batch();

      // Antrenman geçmişi ekle
      final historyRef = _firestore
          .collection('users')
          .doc(history.userId)
          .collection('routineHistory')
          .doc();

      batch.set(historyRef, history.toFirestore());

      // Son kullanma tarihini güncelle
      final routineRef = _firestore
          .collection('users')
          .doc(history.userId)
          .collection('routines')
          .doc(history.routineId.toString());

      batch.update(routineRef, {
        'lastUsedDate': FieldValue.serverTimestamp()
      });

      await batch.commit();
      _logger.info('Routine history added with ID: ${historyRef.id}');
    } catch (e) {
      _logger.severe('Error adding routine history', e);
      rethrow;
    }
  }

  Future<List<FirebaseRoutines>> getUserRoutines(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .orderBy('lastUpdated', descending: true)
          .get();

      List<FirebaseRoutines> routines = snapshot.docs
          .map((doc) => FirebaseRoutines.fromFirestore(doc))
          .toList();

      _logger.info('User routines fetched successfully. Total: ${routines.length}');
      return routines;
    } catch (e) {
      _logger.severe('Error getting user routines', e);
      return [];
    }
  }

  Future<void> addOrUpdateUserRoutine(
      String userId,
      FirebaseRoutines routine,
      ) async {
    try {
      final batch = _firestore.batch();
      final routineRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routine.id);

      batch.set(routineRef, {
        ...routine.toFirestore(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      _logger.info('Routine added/updated successfully: ${routine.id}');
    } catch (e) {
      _logger.severe('Error adding/updating routine', e);
      rethrow;
    }
  }

  Future<FirebaseRoutines?> getUserRoutine(
      String userId,
      String routineId,
      ) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routineId)
          .get();

      if (!doc.exists) {
        _logger.info('Routine not found: $routineId');
        return null;
      }

      final routine = FirebaseRoutines.fromFirestore(doc);
      _logger.info('Routine fetched successfully: $routineId');
      return routine;
    } catch (e) {
      _logger.severe('Error getting user routine', e);
      return null;
    }
  }

  Future<void> deleteUserRoutine(String userId, String routineId) async {
    try {
      final batch = _firestore.batch();

      // Rutin dokümanını sil
      final routineRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routineId);

      batch.delete(routineRef);

      await batch.commit();
      _logger.info('Routine and related data deleted successfully: $routineId');
    } catch (e) {
      _logger.severe('Error deleting routine', e);
      rethrow;
    }
  }


  // Günlük egzersizlerle birlikte schedule oluşturma
  Future<void> createScheduleWithExercises({
    required String userId,
    required UserSchedule schedule,
    required Map<String, List<Map<String, dynamic>>> dailyExercises,
  }) async {
    try {
      final batch = _firestore.batch();

      // Program dokümanını ekle
      final scheduleRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(schedule.id);

      batch.set(scheduleRef, {
        ...schedule.copyWith(
          dailyExercises: dailyExercises,
        ).toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'exerciseCount': dailyExercises.values
            .fold(0, (sum, list) => sum + list.length),
      });

      // Kullanıcı metadata'sını güncelle
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'lastScheduleUpdate': FieldValue.serverTimestamp(),
        'scheduleCount': FieldValue.increment(1),
        'totalExerciseCount': FieldValue.increment(
            dailyExercises.values.fold(0, (sum, list) => sum + list.length)
        ),
      });

      await batch.commit();
      _logger.info('Schedule created: ${schedule.id} with ${dailyExercises.length} days');
    } catch (e) {
      _logger.severe('Error creating schedule with exercises', e);
      rethrow;
    }
  }

  Future<void> updateScheduleExercises({
    required String userId,
    required String scheduleId,
    required Map<String, List<Map<String, dynamic>>> dailyExercises,
  }) async {
    try {
      final batch = _firestore.batch();

      // Program dokümanını güncelle
      final scheduleRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId);

      final exerciseCount = dailyExercises.values
          .fold(0, (sum, list) => sum + list.length);

      batch.update(scheduleRef, {
        'dailyExercises': dailyExercises,
        'lastUpdated': FieldValue.serverTimestamp(),
        'exerciseCount': exerciseCount,
      });

      // Kullanıcı metadata'sını güncelle
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'lastScheduleUpdate': FieldValue.serverTimestamp(),
        'totalExerciseCount': FieldValue.increment(exerciseCount),
      });

      await batch.commit();
      _logger.info('Schedule updated: $scheduleId with $exerciseCount exercises');
    } catch (e) {
      _logger.severe('Error updating schedule exercises', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDayExercises({
    required String userId,
    required String scheduleId,
    required String day,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId)
          .get();

      if (!doc.exists) {
        _logger.warning('Schedule not found: $scheduleId for day: $day');
        return [];
      }

      final schedule = UserSchedule.fromFirestore(doc);
      final exercises = schedule.dailyExercises?[day] ?? [];
      _logger.info('Fetched ${exercises.length} exercises for $day');
      return exercises;
    } catch (e) {
      _logger.severe('Error getting exercises for day: $day', e);
      return [];
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getAllScheduleExercises({
    required String userId,
    required String scheduleId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId)
          .get();

      if (!doc.exists) {
        _logger.warning('Schedule not found: $scheduleId');
        return {};
      }

      final schedule = UserSchedule.fromFirestore(doc);
      final exercises = schedule.dailyExercises ?? {};
      _logger.info('Fetched exercises for schedule: $scheduleId, days: ${exercises.keys.length}');
      return exercises;
    } catch (e) {
      _logger.severe('Error getting all schedule exercises', e);
      return {};
    }
  }

  Future<void> updateExerciseDetails({
    required String userId,
    required String scheduleId,
    required String day,
    required int exerciseIndex,
    required Map<String, dynamic> newDetails,
  }) async {
    try {
      final batch = _firestore.batch();

      final scheduleRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId);

      final doc = await scheduleRef.get();
      if (!doc.exists) throw Exception('Schedule not found');

      final schedule = UserSchedule.fromFirestore(doc);
      final dailyExercises = Map<String, List<Map<String, dynamic>>>.from(schedule.dailyExercises ?? {});

      if (!dailyExercises.containsKey(day)) {
        throw Exception('Day not found in schedule');
      }

      final exercises = List<Map<String, dynamic>>.from(dailyExercises[day] ?? []);
      if (exerciseIndex >= exercises.length) {
        throw Exception('Exercise index out of range');
      }

      exercises[exerciseIndex] = {
        ...exercises[exerciseIndex],
        ...newDetails,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      dailyExercises[day] = exercises;

      batch.update(scheduleRef, {
        'dailyExercises': dailyExercises,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      _logger.info('Exercise details updated: $scheduleId, day: $day, index: $exerciseIndex');
    } catch (e) {
      _logger.severe('Error updating exercise details', e);
      rethrow;
    }
  }

  Future<UserSchedule?> getUserScheduleById(String userId, String scheduleId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId)
          .get();

      if (!doc.exists) {
        _logger.warning('Schedule not found: $scheduleId');
        return null;
      }

      final schedule = UserSchedule.fromFirestore(doc);
      _logger.info('Schedule fetched: $scheduleId with ${schedule.dailyExercises?.length ?? 0} days');
      return schedule;
    } catch (e) {
      _logger.severe('Error getting schedule by id', e);
      rethrow;
    }
  }

  Future<List<UserSchedule>> getAllUserSchedules(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .orderBy('lastUpdated', descending: true)
          .get();

      List<UserSchedule> schedules = snapshot.docs
          .map((doc) => UserSchedule.fromFirestore(doc))
          .toList();

      _logger.info('Fetched ${schedules.length} schedules for user: $userId');
      return schedules;
    } catch (e) {
      _logger.severe('Error getting all user schedules', e);
      return [];
    }
  }


}
