import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:workout/data_provider/sql_provider.dart';
import 'dart:convert';
import '../firebase_class/RoutineHistory.dart';
import '../firebase_class/RoutineWeekday.dart';
import '../firebase_class/firebase_parts.dart';
import '../firebase_class/firebase_routines.dart';
import '../firebase_class/users.dart';
import 'package:logging/logging.dart';

import '../models/RoutineExercises.dart';

final _logger = Logger('FirebaseProvider');

class FirebaseProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SQLProvider sqlProvider;  // SQLProvider'ı constructor'da alacağız

  FirebaseProvider(this.sqlProvider);


  // Anonim giriş ve cihaz ID oluşturma metodları
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
        _logger.info('Existing user found: $existingUserId');
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
          _logger.info('New user created: ${user.uid}');
          return user.uid;
        }
      }
      return null;
    } catch (e) {
      _logger.severe('Anonim giriş hatası: $e');
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

  Future<String> getDeviceId() async {
    return _getDeviceId();
  }

  // Users sınıfı için metodlar
  Future<Users?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final routines = await getUserRoutines(userId);
        final routineHistory = await getUserRoutineHistory(userId);
        final routineWeekdays = await getUserRoutineWeekdays(userId);
        return Users.fromFirestore(doc,
            routines: routines,
            routineHistory: routineHistory,
            routineWeekdays: routineWeekdays);
      }
      return null;
    } catch (e) {
      _logger.severe('Kullanıcı bilgilerini getirme hatası: $e');
      return null;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(userId).update(userData);
      _logger.info('Kullanıcı başarıyla güncellendi: $userId');
    } catch (e) {
      _logger.severe('Kullanıcı güncelleme hatası: $e');
      throw e;
    }
  }

  // FirebaseRoutines sınıfı için metodlar
  Future<List<FirebaseRoutines>> getUserRoutines(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .get();
      List<FirebaseRoutines> routines =
      snapshot.docs.map((doc) => FirebaseRoutines.fromFirestore(doc)).toList();
      _logger.info('Kullanıcı rutinleri başarıyla getirildi. Toplam: ${routines.length}');
      return routines;
    } catch (e) {
      _logger.severe('Kullanıcı rutinlerini getirme hatası: $e');
      return [];
    }
  }

  Future<FirebaseRoutines?> getUserRoutine(String userId, String routineId) async {
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
      _logger.severe('Rutin detaylarını getirme hatası: $e');
      return null;
    }
  }

  Future<void> addOrUpdateUserRoutine(String userId, FirebaseRoutines routine) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routine.id)
          .set(routine.toFirestore());
      _logger.info('Rutin başarıyla eklendi/güncellendi: ${routine.id}');
    } catch (e) {
      _logger.severe('Rutin ekleme/güncelleme hatası: $e');
      throw e;
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
      _logger.info('Rutin başarıyla silindi: $routineId');
    } catch (e) {
      _logger.severe('Rutin silme hatası: $e');
      throw e;
    }
  }

  Future<void> toggleRoutineFavorite(String userId, String routineId, bool isFavorite) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routineId)
          .update({'isFavorite': isFavorite});
      _logger.info('Rutin favori durumu güncellendi: $isFavorite');
    } catch (e) {
      _logger.severe('Rutin favori durumu güncelleme hatası: $e');
      throw e;
    }
  }

  // FirebaseParts sınıfı için metodlar
  Future<List<FirebaseParts>> getUserParts(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('parts')
          .get();

      return snapshot.docs.map((doc) {
        try {
          return FirebaseParts.fromFirestore(doc);
        } catch (e) {
          debugPrint('Error parsing document ${doc.id}: $e');
          // Hatalı dökümanı atlayıp devam et
          return null;
        }
      }).whereType<FirebaseParts>().toList();
    } catch (e) {
      debugPrint('Error getting user parts: $e');
      return [];
    }
  }





  Future<FirebaseParts?> getUserPart(String userId, String partId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId)
          .get();
      return doc.exists ? FirebaseParts.fromFirestore(doc) : null;
    } catch (e) {
      _logger.severe('Kullanıcı parçasını getirme hatası: $e');
      return null;
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
      _logger.info('Parça başarıyla eklendi/güncellendi: ${part.id}');
    } catch (e) {
      _logger.severe('Parça ekleme/güncelleme hatası: $e');
      throw e;
    }
  }

  Future<void> deleteUserPart(String userId, String partId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId)
          .delete();
      _logger.info('Parça başarıyla silindi: $partId');
    } catch (e) {
      _logger.severe('Parça silme hatası: $e');
      throw e;
    }
  }

  Future<void> togglePartFavorite(String userId, String partId, bool isFavorite) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId);

      // Önce mevcut dökümanı kontrol edelim
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Sadece favori durumunu güncelle
        await docRef.update({
          'isFavorite': isFavorite,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Yeni döküman oluştur
        final part = await sqlProvider.getPartById(int.parse(partId));
        if (part != null) {
          await docRef.set({
            'name': part.name,
            'bodyPartId': part.bodyPartId,
            'setType': part.setType.index,
            'additionalNotes': part.additionalNotes,
            'isFavorite': isFavorite,
            'isCustom': false,
            'userProgress': 0,
            'lastUsedDate': null,
            'userRecommended': false,
            'exerciseIds': part.exerciseIds,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }

      debugPrint('Successfully updated favorite status for part: $partId');
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      throw Exception('Favori durumu güncellenirken bir hata oluştu');
    }
  }


  Future<void> syncRoutineExercises(String userId, int routineId, List<RoutineExercises> routineExercises) async {
    try {
      // Önce mevcut rutini al
      final routineDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routineId.toString())
          .get();

      if (!routineDoc.exists) {
        // Eğer rutin yoksa, SQLProvider'dan bilgileri al
        final routine = await sqlProvider.getRoutineById(routineId);
        if (routine == null) {
          throw Exception('Rutin bulunamadı: $routineId');
        }

        // Yeni FirebaseRoutines oluştur
        final firebaseRoutine = FirebaseRoutines(
          id: routineId.toString(),
          name: routine.name,
          description: routine.description,
          mainTargetedBodyPartId: routine.mainTargetedBodyPartId,
          workoutTypeId: routine.workoutTypeId,
          exerciseIds: routineExercises.map((e) => e.exerciseId).toList(),
        );

        // Rutini Firebase'e kaydet
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('routines')
            .doc(routineId.toString())
            .set(firebaseRoutine.toFirestore());

        _logger.info('Yeni rutin Firebase\'e eklendi: $routineId');
      } else {
        // Mevcut rutinin exerciseIds listesini güncelle
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('routines')
            .doc(routineId.toString())
            .update({
          'exerciseIds': routineExercises.map((e) => e.exerciseId).toList(),
          'lastUsedDate': Timestamp.now(),
        });

        _logger.info('Mevcut rutin güncellendi: $routineId');
      }

      _logger.info('Rutin egzersizleri başarıyla senkronize edildi');
    } catch (e) {
      _logger.severe('Rutin egzersizleri senkronizasyon hatası', e);
      throw e;
    }
  }

  Future<void> syncRoutineExercise(String userId, RoutineExercises routineExercise) async {
    try {
      final routineDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routineExercise.routineId.toString())
          .get();

      if (!routineDoc.exists) {
        // Rutin yoksa oluştur
        final routine = await sqlProvider.getRoutineById(routineExercise.routineId);
        if (routine == null) {
          throw Exception('Rutin bulunamadı: ${routineExercise.routineId}');
        }

        final firebaseRoutine = FirebaseRoutines(
          id: routineExercise.routineId.toString(),
          name: routine.name,
          description: routine.description,
          mainTargetedBodyPartId: routine.mainTargetedBodyPartId,
          workoutTypeId: routine.workoutTypeId,
          exerciseIds: [routineExercise.exerciseId],
        );

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('routines')
            .doc(routineExercise.routineId.toString())
            .set(firebaseRoutine.toFirestore());
      } else {
        // Mevcut rutinin exerciseIds listesini güncelle
        FirebaseRoutines existingRoutine = FirebaseRoutines.fromFirestore(routineDoc);
        List<dynamic> updatedExerciseIds = List.from(existingRoutine.exerciseIds);

        if (!updatedExerciseIds.contains(routineExercise.exerciseId)) {
          updatedExerciseIds.add(routineExercise.exerciseId);
        }

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('routines')
            .doc(routineExercise.routineId.toString())
            .update({
          'exerciseIds': updatedExerciseIds,
          'lastUsedDate': Timestamp.now(),
        });
      }

      _logger.info('Rutin egzersizi başarıyla senkronize edildi: ${routineExercise.id}');
    } catch (e) {
      _logger.severe('Rutin egzersizi senkronizasyon hatası', e);
      throw e;
    }
  }



  Future<void> setWeeklyChallenge({
  required String userId,
  required int routineId,
  required DateTime acceptedAt,
  }) async {
  try {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('weeklyChallenge')
      .doc(routineId.toString())
      .set({
  'routineId': routineId,
  'acceptedAt': Timestamp.fromDate(acceptedAt),
  'status': 'accepted',
  });
  } catch (e) {
  debugPrint('Error setting weekly challenge: $e');
  throw Exception('Haftalık meydan okuma kaydedilirken bir hata oluştu');
  }
  }





  Future<bool> isPartFavorite(String userId, String partId) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('userParts')
          .doc(partId)
          .get();
      return docSnapshot.exists && docSnapshot.data()?['isFavorite'] == true;
    } catch (e) {
      _logger.severe('Parçanın favori durumunu kontrol etme hatası: $e');
      return false;
    }
  }

  // RoutineHistory sınıfı için metodlar
  Future<List<RoutineHistory>> getUserRoutineHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('routineHistory')
          .get();
      return snapshot.docs.map((doc) => RoutineHistory.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.severe('Rutin geçmişini getirme hatası: $e');
      return [];
    }
  }

  Future<void> addRoutineHistoryEntry(String userId, RoutineHistory historyEntry) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('routineHistory')
          .add(historyEntry.toFirestore());
      _logger.info('Rutin geçmişi başarıyla eklendi');
    } catch (e) {
      _logger.severe('Rutin geçmişi ekleme hatası: $e');
      throw e;
    }
  }

  // RoutineWeekday sınıfı için metodlar
  Future<List<RoutineWeekday>> getUserRoutineWeekdays(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('routineWeekdays')
          .get();
      return snapshot.docs.map((doc) => RoutineWeekday.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.severe('Haftalık rutin planını getirme hatası: $e');
      return [];
    }
  }

  Future<void> addOrUpdateRoutineWeekday(String userId, RoutineWeekday weekday) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('routineWeekdays')
          .doc(weekday.id)
          .set(weekday.toFirestore());
      _logger.info('Haftalık rutin planı başarıyla eklendi/güncellendi: ${weekday.id}');
    } catch (e) {
      _logger.severe('Haftalık rutin planı ekleme/güncelleme hatası: $e');
      throw e;
    }
  }

  Future<void> deleteRoutineWeekday(String userId, String weekdayId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('routineWeekdays')
          .doc(weekdayId)
          .delete();
      _logger.info('Haftalık rutin planı başarıyla silindi: $weekdayId');
    } catch (e) {
      _logger.severe('Haftalık rutin planı silme hatası: $e');
      throw e;
    }
  }

  // Diğer yardımcı metodlar
  Future<void> updateUserRoutineProgress(String userId, String routineId, int progress) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routineId)
          .update({'userProgress': progress});
      _logger.info('Rutin ilerleme başarıyla güncellendi: $progress');
    } catch (e) {
      _logger.severe('Rutin ilerleme güncelleme hatası: $e');
      throw e;
    }
  }

  Future<void> updateUserRoutineLastUsedDate(String userId, String routineId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routineId)
          .update({'lastUsedDate': Timestamp.now()});
      _logger.info('Son kullanım tarihi başarıyla güncellendi');
    } catch (e) {
      _logger.severe('Son kullanım tarihi güncelleme hatası: $e');
      throw e;
    }
  }
  Future<void> toggleExerciseFavorite(String userId, String exerciseId, bool isFavorite) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favoriteExercises')
          .doc(exerciseId)
          .set({
        'isFavorite': isFavorite,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Favori durumu güncellenirken hata: $e');
    }
  }

  // Egzersiz tamamlanma durumunu güncelle
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
        'completionDate': completionDate.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Tamamlanma durumu güncellenirken hata: $e');
    }
  }
// TODO: Implement methods for PartFocusRoutine if needed
}
