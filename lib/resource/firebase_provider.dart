import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/routine.dart';

class FirebaseProvider {
  static final FirebaseProvider _instance = FirebaseProvider._internal();

  FirebaseProvider._internal();

  factory FirebaseProvider() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Connectivity _connectivity = Connectivity();

  FirebaseFirestore get firestore => _firestore;
  Connectivity get connectivity => _connectivity;

  // Mevcut kullanıcının ID'sini alma
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }




  // Kullanıcı rutinini kaydetme veya güncelleme
  Future<void> saveUserRoutine(Routine routine) async {
    await checkInternetConnection();
    final userId = getCurrentUserId();
    if (userId == null) throw Exception("User not authenticated");

    try {
      await _firestore.collection("users").doc(userId).collection("routines")
          .doc(routine.id.toString()).set({
        'isRecommended': routine.isRecommended,
        'progress': 0,
        'lastUsedDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      logError('Error saving user routine', e);
      rethrow;
    }
  }

  // Kullanıcı rutinlerini getirme
  Future<List<Map<String, dynamic>>> getUserRoutines() async {
    await checkInternetConnection();
    final userId = getCurrentUserId();
    if (userId == null) throw Exception("User not authenticated");

    try {
      var snapshot = await _firestore.collection("users").doc(userId).collection("routines").get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      logError('Error getting user routines', e);
      return [];
    }
  }

  // Rutin ilerleme durumunu güncelleme
  Future<void> updateRoutineProgress(int routineId, int progress) async {
    await checkInternetConnection();
    final userId = getCurrentUserId();
    if (userId == null) throw Exception("User not authenticated");

    try {
      await _firestore.collection("users").doc(userId).collection("routines")
          .doc(routineId.toString()).update({
        'progress': progress,
        'lastUsedDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logError('Error updating routine progress', e);
      rethrow;
    }
  }

  // Rutin favoriye ekleme/çıkarma
  Future<void> toggleRoutineFavorite(int routineId) async {
    await checkInternetConnection();
    final userId = getCurrentUserId();
    if (userId == null) throw Exception("User not authenticated");

    try {
      var routineRef = _firestore.collection("users").doc(userId).collection("routines").doc(routineId.toString());
      await _firestore.runTransaction((transaction) async {
        var snapshot = await transaction.get(routineRef);
        if (snapshot.exists) {
          bool currentRecommended = snapshot.data()?['isRecommended'] ?? false;
          transaction.update(routineRef, {'isRecommended': !currentRecommended});
        } else {
          transaction.set(routineRef, {'isRecommended': true, 'progress': 0, 'lastUsedDate': FieldValue.serverTimestamp()});
        }
      });
    } catch (e) {
      logError('Error toggling routine favorite', e);
      rethrow;
    }
  }

  // Kullanıcı rutinini silme
  Future<void> deleteUserRoutine(int routineId) async {
    await checkInternetConnection();
    final userId = getCurrentUserId();
    if (userId == null) throw Exception("User not authenticated");

    try {
      await _firestore.collection("users").doc(userId).collection("routines")
          .doc(routineId.toString()).delete();
    } catch (e) {
      logError('Error deleting user routine', e);
      rethrow;
    }
  }

  // İnternet bağlantısı kontrolü
  Future<void> checkInternetConnection() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception("No internet connection.");
    }
  }

  // Hata loglama
  void logError(String message, dynamic error) {
    if (kDebugMode) {
      print('$message: $error');
    }
  }
}

final firebaseProvider = FirebaseProvider();
