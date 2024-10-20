import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
// ignore: unused_import
import 'package:workout/data_provider/sql_provider.dart';
import 'dart:convert';

import '../firebase_class/RoutineHistory.dart';
import '../firebase_class/RoutineWeekday.dart';
import '../firebase_class/firebase_parts.dart';
import '../firebase_class/firebase_routines.dart';
import '../firebase_class/users.dart';
import '../models/PartFocusRoutine.dart';
import '../models/exercises.dart';


class FirebaseProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseProvider();

  // Anonim giriş ve cihaz ID oluşturma metodları
  Future<String?> signInAnonymously() async {
    try {
      String deviceId = await _getDeviceId();
      print('Device ID: $deviceId');

      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('deviceId', isEqualTo: deviceId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        String existingUserId = userQuery.docs.first.id;
        print('Existing user found: $existingUserId');
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
          print('New user created: ${user.uid}');
          return user.uid;
        }
      }
      return null;
    } catch (e) {
      print('Anonim giriş hatası: $e');
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
        return Users.fromFirestore(doc, routines: routines, routineHistory: routineHistory, routineWeekdays: routineWeekdays);
      }
      return null;
    } catch (e) {
      print('Kullanıcı bilgilerini getirme hatası: $e');
      return null;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(userId).update(userData);
      print('Kullanıcı başarıyla güncellendi: $userId');
    } catch (e) {
      print('Kullanıcı güncelleme hatası: $e');
      throw e;
    }
  }

  // FirebaseRoutines sınıfı için metodlar
  Future<List<FirebaseRoutines>> getUserRoutines(String userId) async {
    try {
      final snapshot = await _firestore.collection('users').doc(userId).collection('routines').get();
      List<FirebaseRoutines> routines = snapshot.docs.map((doc) => FirebaseRoutines.fromFirestore(doc)).toList();
      print('Kullanıcı rutinleri başarıyla getirildi. Toplam: ${routines.length}');
      return routines;
    } catch (e) {
      print('Kullanıcı rutinlerini getirme hatası: $e');
      return [];
    }
  }

  Future<FirebaseRoutines?> getUserRoutine(String userId, String routineId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).collection('routines').doc(routineId).get();
      if (doc.exists) {
        return FirebaseRoutines.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Rutin detaylarını getirme hatası: $e');
      return null;
    }
  }

  Future<void> addOrUpdateUserRoutine(String userId, FirebaseRoutines routine) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routines').doc(routine.id).set(routine.toFirestore());
      print('Rutin başarıyla eklendi/güncellendi: ${routine.id}');
    } catch (e) {
      print('Rutin ekleme/güncelleme hatası: $e');
      throw e;
    }
  }

  Future<void> deleteUserRoutine(String userId, String routineId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routines').doc(routineId).delete();
      print('Rutin başarıyla silindi: $routineId');
    } catch (e) {
      print('Rutin silme hatası: $e');
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
      print('Rutin favori durumu güncellendi: $isFavorite');
    } catch (e) {
      print('Rutin favori durumu güncelleme hatası: $e');
      throw e;
    }
  }



  Future<List<FirebaseParts>> getAllParts() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('parts').get();
      return snapshot.docs.map((doc) => FirebaseParts.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting all parts: $e');
      return [];
    }
  }

  Future<FirebaseParts?> getPartById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('parts').doc(id).get();
      if (doc.exists) {
        return FirebaseParts.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting part by id: $e');
      return null;
    }
  }
  Future<FirebaseParts?> getUserPart(String userId, String partId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId)
          .get();

      if (doc.exists) {
        return FirebaseParts.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user part: $e');
      return null;
    }
  }



  Future<List<FirebaseParts>> getPartsByBodyPart(int bodyPartId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('parts')
          .where('bodyPartId', isEqualTo: bodyPartId)
          .get();
      return snapshot.docs.map((doc) => FirebaseParts.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting parts by body part: $e');
      return [];
    }
  }

  Future<List<FirebaseParts>> getPartsBySetType(SetType setType) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('parts')
          .where('setType', isEqualTo: setType.index)
          .get();
      return snapshot.docs.map((doc) => FirebaseParts.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting parts by set type: $e');
      return [];
    }
  }

  Future<List<FirebaseParts>> searchPartsByName(String name) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('parts')
          .where('name', isGreaterThanOrEqualTo: name)
          .where('name', isLessThan: name + 'z')
          .get();
      return snapshot.docs.map((doc) => FirebaseParts.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching parts by name: $e');
      return [];
    }
  }

  Future<List<FirebaseParts>> getPartsWithNotes() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('parts')
          .where('additionalNotes', isNotEqualTo: '')
          .get();
      return snapshot.docs.map((doc) => FirebaseParts.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting parts with notes: $e');
      return [];
    }
  }

  Future<List<FirebaseParts>> getPartsSortedByName({bool ascending = true}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('parts')
          .orderBy('name', descending: !ascending)
          .get();
      return snapshot.docs.map((doc) => FirebaseParts.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting parts sorted by name: $e');
      return [];
    }
  }
// Kullanıcının parçalarını getir
  Future<List<FirebaseParts>> getUserParts(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('parts')
          .get();

      return snapshot.docs
          .map((doc) => FirebaseParts.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user parts: $e');
      return []; // Hata durumunda boş liste dön
    }
  }

  // Kullanıcının parçasını ekle veya güncelle
  Future<void> addOrUpdateUserPart(String userId, FirebaseParts part) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(part.id)
          .set(part.toFirestore());

      print('Parça başarıyla eklendi/güncellendi: ${part.id}');
    } catch (e) {
      print('Parça ekleme/güncelleme hatası: $e');
      throw e;
    }
  }

  // Kullanıcının parçasını sil
  Future<void> deleteUserPart(String userId, String partId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId)
          .delete();

      print('Parça başarıyla silindi: $partId');
    } catch (e) {
      print('Parça silme hatası: $e');
      throw e;
    }
  }


  Future<bool> isPartFavorite(String userId, String partId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['isFavorite'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking if part is favorite: $e');
      return false;
    }
  }

  Future<void> togglePartFavorite(String userId, String partId, bool isFavorite) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('parts')
          .doc(partId)
          .update({'isFavorite': isFavorite});
    } catch (e) {
      print('Error toggling part favorite: $e');
      throw e;
    }
  }



  // RoutineHistory sınıfı için metodlar
  Future<List<RoutineHistory>> getUserRoutineHistory(String userId) async {
    try {
      final snapshot = await _firestore.collection('users').doc(userId).collection('routineHistory').get();
      return snapshot.docs.map((doc) => RoutineHistory.fromFirestore(doc)).toList();
    } catch (e) {
      print('Rutin geçmişini getirme hatası: $e');
      return [];
    }
  }

  Future<void> addRoutineHistoryEntry(String userId, RoutineHistory historyEntry) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routineHistory').add(historyEntry.toFirestore());
      print('Rutin geçmişi başarıyla eklendi');
    } catch (e) {
      print('Rutin geçmişi ekleme hatası: $e');
      throw e;
    }
  }

  // RoutineWeekday sınıfı için metodlar
  Future<List<RoutineWeekday>> getUserRoutineWeekdays(String userId) async {
    try {
      final snapshot = await _firestore.collection('users').doc(userId).collection('routineWeekdays').get();
      return snapshot.docs.map((doc) => RoutineWeekday.fromFirestore(doc)).toList();
    } catch (e) {
      print('Haftalık rutin planını getirme hatası: $e');
      return [];
    }
  }

  Future<void> addOrUpdateRoutineWeekday(String userId, RoutineWeekday weekday) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routineWeekdays').doc(weekday.id).set(weekday.toFirestore());
      print('Haftalık rutin planı başarıyla eklendi/güncellendi: ${weekday.id}');
    } catch (e) {
      print('Haftalık rutin planı ekleme/güncelleme hatası: $e');
      throw e;
    }
  }

  Future<void> deleteRoutineWeekday(String userId, String weekdayId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routineWeekdays').doc(weekdayId).delete();
      print('Haftalık rutin planı başarıyla silindi: $weekdayId');
    } catch (e) {
      print('Haftalık rutin planı silme hatası: $e');
      throw e;
    }
  }

  // Diğer yardımcı metodlar
  Future<void> updateUserRoutineProgress(String userId, String routineId, int progress) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routines').doc(routineId).update({'userProgress': progress});
      print('Rutin ilerleme başarıyla güncellendi: $progress');
    } catch (e) {
      print('Rutin ilerleme güncelleme hatası: $e');
      throw e;
    }
  }

  Future<void> updateUserRoutineLastUsedDate(String userId, String routineId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routines').doc(routineId).update({'lastUsedDate': Timestamp.now()});
      print('Son kullanım tarihi başarıyla güncellendi');
    } catch (e) {
      print('Son kullanım tarihi güncelleme hatası: $e');
      throw e;
    }
  }

  // Özel egzersizler için metodlar
  Future<List<Exercises>> getUserCustomExercises(String userId) async {
    try {
      final snapshot = await _firestore.collection('users').doc(userId).collection('customExercises').get();
      return snapshot.docs.map((doc) => Exercises.fromMap(doc.data())).toList();
    } catch (e) {
      print('Özel egzersizleri getirme hatası: $e');
      return [];
    }
  }




  Future<void> addOrUpdateUserCustomExercise(String userId, Exercises exercise) async {
    try {
      await _firestore.collection('users').doc(userId).collection('customExercises').doc(exercise.id.toString()).set(exercise.toMap());
      print('Özel egzersiz başarıyla eklendi/güncellendi: ${exercise.id}');
    } catch (e) {
      print('Özel egzersiz ekleme/güncelleme hatası: $e');
      throw e;
    }
  }

  Future<void> deleteUserCustomExercise(String userId, String exerciseId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('customExercises').doc(exerciseId).delete();
      print('Özel egzersiz başarıyla silindi: $exerciseId');
    } catch (e) {
      print('Özel egzersiz silme hatası: $e');
      throw e;
    }
  }
}
