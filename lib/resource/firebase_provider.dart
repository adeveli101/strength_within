import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../firebase_class/firebase_routines.dart';
import '../models/exercises.dart';
import '../models/routines.dart';
import '../resource/sql_provider.dart';

class FirebaseProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final SQLProvider _sqlProvider;

  FirebaseProvider(this._sqlProvider);

  /// Kullanıcıyı anonim olarak giriş yapar ve cihaz verilerine dayalı benzersiz bir ID oluşturur.
  ///
  /// Returns:
  ///   - String?: Başarılı giriş durumunda kullanıcı ID'si, başarısız olursa null.
  Future<String?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;
      if (user != null) {
        String deviceId = await _getDeviceId();
        await _firestore.collection('users').doc(user.uid).set({
          'deviceId': deviceId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return user.uid;
      }
      return null;
    } catch (e) {
      print('Anonim giriş hatası: $e');
      return null;
    }
  }

  /// Cihaza özgü benzersiz bir ID oluşturur.
  ///
  /// Returns:
  ///   - String: Cihaza özgü hash'lenmiş ID.
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

  /// Kullanıcının tüm rutinlerini Firebase'den getirir.
  ///
  /// Parameters:
  ///   - userId: Kullanıcının benzersiz ID'si.
  ///
  /// Returns:
  ///   - List<FirebaseRoutine>: Kullanıcının rutinlerinin listesi.
  Future<List<FirebaseRoutine>> getUserRoutines(String userId) async {
    try {
      final snapshot = await _firestore.collection('users').doc(userId).collection('routines').get();
      List<FirebaseRoutine> routines = [];
      for (var doc in snapshot.docs) {
        int routineId = int.parse(doc.id);
        Routine? localRoutine = await _sqlProvider.getRoutine(routineId);
        if (localRoutine != null) {
          routines.add(FirebaseRoutine.fromFirestore(doc, localRoutine));
        }
      }
      return routines;
    } catch (e) {
      print('Kullanıcı rutinlerini getirme hatası: $e');
      return [];
    }
  }

  /// Kullanıcının bir rutinini Firebase'e ekler veya günceller.
  ///
  /// Parameters:
  ///   - userId: Kullanıcının benzersiz ID'si.
  ///   - routine: Eklenecek veya güncellenecek FirebaseRoutine nesnesi.
  Future<void> addOrUpdateUserRoutine(String userId, FirebaseRoutine routine) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('users').doc(userId).collection('routines').doc(routine.id);
        transaction.set(docRef, routine.toFirebaseMap(), SetOptions(merge: true));
      });
    } catch (e) {
      print('Rutin ekleme/güncelleme hatası: $e');
    }
  }

  /// Kullanıcının bir rutinini Firebase'den siler.
  ///
  /// Parameters:
  ///   - userId: Kullanıcının benzersiz ID'si.
  ///   - routineId: Silinecek rutinin ID'si.
  Future<void> deleteUserRoutine(String userId, String routineId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routines').doc(routineId).delete();
    } catch (e) {
      print('Rutin silme hatası: $e');
    }
  }

  /// Kullanıcının rutin ilerlemesini günceller.
  ///
  /// Parameters:
  ///   - userId: Kullanıcının benzersiz ID'si.
  ///   - routineId: Güncellenecek rutinin ID'si.
  ///   - progress: Yeni ilerleme değeri.
  Future<void> updateUserRoutineProgress(String userId, String routineId, int progress) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routines').doc(routineId).update({'progress': progress});
    } catch (e) {
      print('Rutin ilerleme güncelleme hatası: $e');
    }
  }

  /// Kullanıcının son kullandığı rutin tarihini günceller.
  ///
  /// Parameters:
  ///   - userId: Kullanıcının benzersiz ID'si.
  ///   - routineId: Güncellenecek rutinin ID'si.
  Future<void> updateUserRoutineLastUsedDate(String userId, String routineId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('routines').doc(routineId).update({'lastUsedDate': Timestamp.now()});
    } catch (e) {
      print('Son kullanım tarihi güncelleme hatası: $e');
    }
  }

  /// Kullanıcının özel egzersizlerini getirir.
  ///
  /// Parameters:
  ///   - userId: Kullanıcının benzersiz ID'si.
  ///
  /// Returns:
  ///   - List<Exercise>: Kullanıcının özel egzersizlerinin listesi.
  Future<List<Exercise>> getUserCustomExercises(String userId) async {
    try {
      final snapshot = await _firestore.collection('users').doc(userId).collection('customExercises').get();
      return snapshot.docs.map((doc) => Exercise.fromMap(doc.data())).toList();
    } catch (e) {
      print('Özel egzersizleri getirme hatası: $e');
      return [];
    }
  }

  /// Kullanıcının özel bir egzersizini ekler veya günceller.
  ///
  /// Parameters:
  ///   - userId: Kullanıcının benzersiz ID'si.
  ///   - exercise: Eklenecek veya güncellenecek Exercise nesnesi.
  Future<void> addOrUpdateUserCustomExercise(String userId, Exercise exercise) async {
    try {
      await _firestore.collection('users').doc(userId).collection('customExercises').doc(exercise.id.toString()).set(exercise.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Özel egzersiz ekleme/güncelleme hatası: $e');
    }
  }

  /// Kullanıcının özel bir egzersizini siler.
  ///
  /// Parameters:
  ///   - userId: Kullanıcının benzersiz ID'si.
  ///   - exerciseId: Silinecek egzersizin ID'si.
  Future<void> deleteUserCustomExercise(String userId, String exerciseId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('customExercises').doc(exerciseId).delete();
    } catch (e) {
      print('Özel egzersiz silme hatası: $e');
    }
  }

  /// Yerel veritabanı ile Firebase arasında periyodik senkronizasyon yapar.
  ///
  /// Parameters:
  ///   - userId: Kullanıcının benzersiz ID'si.
///
///  bu kısım routines_bloc kodunda ele alınacak.
  Future<void> syncLocalAndFirebaseData(String userId) async {
    try {
      // 1. Firebase'den kullanıcının rutinlerini al
      List<FirebaseRoutine> firebaseRoutines = await getUserRoutines(userId);

      // 2. Yerel veritabanından tüm rutinleri al
      List<Routine> localRoutines = await _sqlProvider.getAllRoutines();

      // 3. Firebase'deki rutinleri yerel rutinlerle karşılaştır ve güncelle
      for (var fbRoutine in firebaseRoutines) {
        Routine? localRoutine = localRoutines.firstWhere(
              (local) => local.id == int.parse(fbRoutine.id),

        );

        if (localRoutine == null) {
          // Eğer rutin yerel veritabanında yoksa, Firebase'den gelen veriyi kullan
          await addOrUpdateUserRoutine(userId, fbRoutine);
        } else {
          // Eğer rutin varsa, Firebase'deki veriyi güncelle
          FirebaseRoutine updatedRoutine = FirebaseRoutine(
            id: fbRoutine.id,
            routine: localRoutine,
            userProgress: fbRoutine.userProgress,
            lastUsedDate: fbRoutine.lastUsedDate,
            userRecommended: fbRoutine.userRecommended,
            isCustom: fbRoutine.isCustom,
          );
          await addOrUpdateUserRoutine(userId, updatedRoutine);
        }
      }

      // 4. Yerel veritabanındaki rutinleri Firebase'e ekle (eğer yoksa)
      for (var localRoutine in localRoutines) {
        if (!firebaseRoutines.any((fbRoutine) => fbRoutine.id == localRoutine.id.toString())) {
          FirebaseRoutine newFbRoutine = FirebaseRoutine(
            id: localRoutine.id.toString(),
            routine: localRoutine,
            isCustom: false,
          );
          await addOrUpdateUserRoutine(userId, newFbRoutine);
        }
      }

      // 5. Özel egzersizler için senkronizasyon
      List<Exercise> firebaseExercises = await getUserCustomExercises(userId);
      List<Exercise> localExercises = await _sqlProvider.getAllExercises();

      for (var fbExercise in firebaseExercises) {
        if (!localExercises.any((local) => local.id == fbExercise.id)) {
          await addOrUpdateUserCustomExercise(userId, fbExercise);
        }
      }

      for (var localExercise in localExercises) {
        if (!firebaseExercises.any((fb) => fb.id == localExercise.id)) {
          await addOrUpdateUserCustomExercise(userId, localExercise);
        }
      }

    } catch (e) {
      print('Veri senkronizasyon hatası: $e');
    }
  }

}