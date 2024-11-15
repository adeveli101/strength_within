import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import '../firebase_class/firebase_routines.dart';
import '../firebase_class/firebase_parts.dart';
import '../firebase_class/RoutineHistory.dart';
import '../firebase_class/user_schedule.dart';

class FirebaseProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('FirebaseProvider');

  // MARK: - Auth Operations
  Future<String?> signInAnonymously() async {
    try {
      String deviceId = await _getDeviceId();
      _logger.info('Device ID: $deviceId');

      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('deviceId', isEqualTo: deviceId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        String existingUserId = userQuery.docs.first.id;
        await _auth.signInAnonymously();
        await _firestore.collection('users').doc(existingUserId).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        return existingUserId;
      } else {
        final userCredential = await _auth.signInAnonymously();
        final user = userCredential.user;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'deviceId': deviceId,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
          return user.uid;
        }
      }
      return null;
    } catch (e) {
      _logger.severe('Auth error', e);
      return null;
    }
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

  // MARK: - Schedule Operations
  Future<void> addUserSchedule(UserSchedule schedule) async {
    try {
      await _firestore
          .collection('users')
          .doc(schedule.userId)
          .collection('schedules')
          .doc(schedule.id)
          .set(schedule.toFirestore());

      _logger.info('Schedule added: ${schedule.id}');
    } catch (e) {
      _logger.severe('Error adding schedule', e);
      rethrow;
    }
  }

  Future<void> updateUserSchedule(UserSchedule schedule) async {
    try {
      await _firestore
          .collection('users')
          .doc(schedule.userId)
          .collection('schedules')
          .doc(schedule.id)
          .update(schedule.toFirestore());

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
  // MARK: - Schedule Operations
  Future<List<UserSchedule>> getUserSchedules(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserSchedule.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error getting user schedules', e);
      return [];
    }
  }

  // MARK: - Progress Operations
  Future<void> updateUserProgress(
      String userId,
      String itemId,
      String type,
      int progress,
      ) async {
    try {
      final collectionName = type == 'part' ? 'parts' : 'routines';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(collectionName)
          .doc(itemId)
          .update({
        'userProgress': progress,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _logger.info('Progress updated for $type: $itemId');
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

  // MARK: - Favorite Operations
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

  // MARK: - Challenge Operations
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

  // MARK: - Exercise Operations
  Future<void> updateExerciseCompletion(
      String userId,
      String exerciseId,
      bool isCompleted,
      DateTime completionDate,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('exerciseProgress')
          .doc(exerciseId)
          .set({
        'isCompleted': isCompleted,
        'completionDate': Timestamp.fromDate(completionDate),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _logger.info('Exercise completion updated: $exerciseId');
    } catch (e) {
      _logger.severe('Error updating exercise completion', e);
      rethrow;
    }
  }

  // MARK: - History Operations
  Future<void> addRoutineHistory(RoutineHistory history) async {
    try {
      await _firestore
          .collection('users')
          .doc(history.userId)
          .collection('routineHistory')
          .add(history.toFirestore());

      _logger.info('Routine history added');
    } catch (e) {
      _logger.severe('Error adding routine history', e);
      rethrow;
    }
  }

  // MARK: - Parts Operations
  Future<List<FirebaseParts>> getUserParts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .get();

      return snapshot.docs
          .map((doc) => FirebaseParts.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error getting user parts', e);
      return [];
    }
  }

  Future<void> addOrUpdateUserPart(String userId, FirebaseParts part) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(part.id)
          .set(part.toFirestore());

      _logger.info('Part added/updated successfully: ${part.id}');
    } catch (e) {
      _logger.severe('Error adding/updating part', e);
      rethrow;
    }
  }

  // MARK: - Favorite Operations
  Future<bool> isPartFavorite(String userId, String partId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId)
          .get();

      return doc.exists && doc.data()?['isFavorite'] == true;
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
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId)
          .update({
        'isFavorite': isFavorite,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _logger.info('Part favorite status updated: $partId');
    } catch (e) {
      _logger.severe('Error updating part favorite', e);
      rethrow;
    }
  }

  // MARK: - Progress Operations
  Future<void> updatePartProgress(
      String userId,
      String partId,
      int progress,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId)
          .update({
        'userProgress': progress,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _logger.info('Part progress updated: $partId');
    } catch (e) {
      _logger.severe('Error updating part progress', e);
      rethrow;
    }
  }

  // MARK: - Schedule Operations
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
          .get();

      return snapshot.docs
          .map((doc) => UserSchedule.fromFirestore(doc))
          .toList();
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
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId)
          .update({
        'isActive': isActive,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _logger.info('Schedule status updated: $scheduleId');
    } catch (e) {
      _logger.severe('Error updating schedule status', e);
      rethrow;
    }
  }

// FirebaseProvider sınıfı içine eklenecek metodlar

// MARK: - Routine Operations
  Future<List<FirebaseRoutines>> getUserRoutines(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
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
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routine.id)
          .set(routine.toFirestore());

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

      if (doc.exists) {
        return FirebaseRoutines.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logger.severe('Error getting user routine', e);
      return null;
    }
  }

  Future<void> deleteUserRoutine(String userId, String routineId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routineId)
          .delete();

      _logger.info('Routine deleted successfully: $routineId');
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
      final scheduleData = schedule.copyWith(
        dailyExercises: dailyExercises,
      ).toFirestore();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(schedule.id)
          .set(scheduleData);

      _logger.info('Schedule created with exercises: ${schedule.id}');
    } catch (e) {
      _logger.severe('Error creating schedule with exercises', e);
      rethrow;
    }
  }

  // Schedule'ın günlük egzersizlerini güncelleme
  Future<void> updateScheduleExercises({
    required String userId,
    required String scheduleId,
    required Map<String, List<Map<String, dynamic>>> dailyExercises,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId)
          .update({
        'dailyExercises': dailyExercises,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _logger.info('Schedule exercises updated: $scheduleId');
    } catch (e) {
      _logger.severe('Error updating schedule exercises', e);
      rethrow;
    }
  }

  // Belirli bir günün egzersizlerini getirme
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
        _logger.warning('Schedule not found: $scheduleId');
        return [];
      }

      final schedule = UserSchedule.fromFirestore(doc);
      return schedule.dailyExercises?[day] ?? [];
    } catch (e) {
      _logger.severe('Error getting day exercises', e);
      return [];
    }
  }

  // Schedule'ın tüm egzersizlerini getirme
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
      return schedule.dailyExercises ?? {};
    } catch (e) {
      _logger.severe('Error getting all schedule exercises', e);
      return {};
    }
  }

  // Egzersiz detaylarını güncelleme (set, tekrar, ağırlık)
  Future<void> updateExerciseDetails({
    required String userId,
    required String scheduleId,
    required String day,
    required int exerciseIndex,
    required Map<String, dynamic> newDetails,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId)
          .get();

      if (!doc.exists) {
        throw Exception('Schedule not found');
      }

      final schedule = UserSchedule.fromFirestore(doc);
      final dailyExercises = schedule.dailyExercises ?? {};

      if (!dailyExercises.containsKey(day)) {
        throw Exception('Day not found in schedule');
      }

      final exercises = dailyExercises[day] ?? [];
      if (exerciseIndex >= exercises.length) {
        throw Exception('Exercise index out of range');
      }

      exercises[exerciseIndex] = {
        ...exercises[exerciseIndex],
        ...newDetails,
      };

      dailyExercises[day] = exercises;

      await updateScheduleExercises(
        userId: userId,
        scheduleId: scheduleId,
        dailyExercises: dailyExercises,
      );

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
        _logger.info('Schedule not found: $scheduleId');
        return null;
      }

      final schedule = UserSchedule.fromFirestore(doc);
      _logger.info('Schedule fetched successfully: $scheduleId');
      return schedule;
    } catch (e) {
      _logger.severe('Error getting schedule by id', e);
      rethrow;
    }
  }

// Ayrıca bu metodları da ekleyelim (schedule işlemleri için)





  Future<List<UserSchedule>> getAllUserSchedules(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .orderBy('lastUpdated', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserSchedule.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error getting all user schedules', e);
      return [];
    }
  }


}
