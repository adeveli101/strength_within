import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'dart:convert';
import '../firebase_class/RoutineHistory.dart';
import '../firebase_class/RoutineWeekday.dart';
import '../firebase_class/firebase_routines.dart';
import '../firebase_class/users.dart';
import '../models/exercises.dart';
import '../models/routines.dart';
import '../resource/sql_provider.dart';


class FirebaseProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final SQLProvider _sqlProvider;

  FirebaseProvider(this._sqlProvider);

  // Anonim giriş ve cihaz ID oluşturma metodları
  Future<String?> signInAnonymously() async {
    try {
      String deviceId = await _getDeviceId();
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


  static Future<String?> getUserId(String deviceId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('deviceId', isEqualTo: deviceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      } else {
        return null;
      }
    } catch (e) {
      print('Kullanıcı ID alınırken hata oluştu: $e');
      return null;
    }
  }






  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(userId).update(userData);
    } catch (e) {
      print('Kullanıcı güncelleme hatası: $e');
    }
  }



  Future<void> updateUserRoutine(String userId, FirebaseRoutine routine) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routine.id)
          .set(routine.toFirestore(), SetOptions(merge: true));

      print('Kullanıcı rutini başarıyla güncellendi: ${routine.id}');
    } catch (e) {
      print('Kullanıcı rutini güncellenirken hata oluştu: $e');
      throw e;
    }
  }



  // FirebaseRoutine sınıfı için metodlar
  Future<List<FirebaseRoutine>> getUserRoutines(String userId) async {
    try {
      final snapshot = await _firestore.collection('users').doc(userId).collection('routines').get();
      List<FirebaseRoutine> routines = [];
      for (var doc in snapshot.docs) {
        int routineId = int.parse(doc.id);
        Routines? localRoutine = await _sqlProvider.getRoutine(routineId);
        if (localRoutine != null) {
          routines.add(FirebaseRoutine.fromFirestore(doc));
        }
      }
      return routines;
    } catch (e) {
      print('Kullanıcı rutinlerini getirme hatası: $e');
      return [];
    }
  }

  Future<FirebaseRoutine?> getUserRoutine(String userId, String routineId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).collection('routines').doc(routineId).get();
      if (doc.exists) {
        return FirebaseRoutine.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Rutin detaylarını getirme hatası: $e');
      return null;
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
      throw e; // Hatayı yukarı fırlat, böylece çağıran kod hata yönetimi yapabilir
    }
  }

  Future<List<FirebaseRoutine>>getFavoriteRoutines(String userId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .where('isFavorite', isEqualTo: true)
          .get();

      List<FirebaseRoutine> favoriteRoutines = querySnapshot.docs.map((doc) {
        return FirebaseRoutine.fromFirestore(doc);
      }).toList();

      print('Favori rutinler başarıyla getirildi. Toplam: ${favoriteRoutines.length}');
      return favoriteRoutines;
    } catch (e) {
      print('Favori rutinleri getirme hatası: $e');
      throw e; // Hatayı yukarı fırlat, böylece çağıran kod hata yönetimi yapabilir
    }
  }

  Future<void> addOrUpdateUserRoutine(String userId, FirebaseRoutine routine) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routines').doc(routine.id).set(routine.toFirestore());
    } catch (e) {
      print('Rutin ekleme/güncelleme hatası: $e');
    }
  }

  Future<void> deleteUserRoutine(String userId, String routineId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routines').doc(routineId).delete();
    } catch (e) {
      print('Rutin silme hatası: $e');
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

  Future<RoutineHistory?> getRoutineHistoryEntry(String userId, String historyId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).collection('routineHistory').doc(historyId).get();
      if (doc.exists) {
        return RoutineHistory.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Rutin geçmişi kaydını getirme hatası: $e');
      return null;
    }
  }

  Future<void> addRoutineHistoryEntry(String userId, RoutineHistory historyEntry) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routineHistory').add(historyEntry.toFirestore());
    } catch (e) {
      print('Rutin geçmişi ekleme hatası: $e');
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





  Future<RoutineWeekday?> getRoutineWeekday(String userId, String weekdayId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).collection('routineWeekdays').doc(weekdayId).get();
      if (doc.exists) {
        return RoutineWeekday.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Haftalık rutin planı kaydını getirme hatası: $e');
      return null;
    }
  }

  Future<void> addOrUpdateRoutineWeekday(String userId, RoutineWeekday weekday) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routineWeekdays').doc(weekday.id).set(weekday.toFirestore());
    } catch (e) {
      print('Haftalık rutin planı ekleme/güncelleme hatası: $e');
    }
  }

  Future<void> deleteRoutineWeekday(String userId, String weekdayId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routineWeekdays').doc(weekdayId).delete();
    } catch (e) {
      print('Haftalık rutin planı silme hatası: $e');
    }
  }

  // Diğer yardımcı metodlar
  Future<void> updateUserRoutineProgress(String userId, String routineId, int progress) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routines').doc(routineId).update({'userProgress': progress});
    } catch (e) {
      print('Rutin ilerleme güncelleme hatası: $e');
    }
  }

  Future<void> updateUserRoutineLastUsedDate(String userId, String routineId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routines').doc(routineId).update({'lastUsedDate': Timestamp.now()});
    } catch (e) {
      print('Son kullanım tarihi güncelleme hatası: $e');
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
    } catch (e) {
      print('Özel egzersiz ekleme/güncelleme hatası: $e');
    }
  }

  Future<void> deleteUserCustomExercise(String userId, String exerciseId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('customExercises').doc(exerciseId).delete();
    } catch (e) {
      print('Özel egzersiz silme hatası: $e');
    }
  }
}
