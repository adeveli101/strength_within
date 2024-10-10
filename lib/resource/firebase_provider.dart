import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:workout/models/routine.dart';

class FirebaseProvider {
  static final FirebaseProvider _instance = FirebaseProvider._internal();

  FirebaseProvider._internal();

  factory FirebaseProvider() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  bool _isFirstRun = true;
  DateTime? _firstRunDate;
  double _weeklyAmount = 0.0;

  // Getters and setters for the properties
  bool get isFirstRun => _isFirstRun;
  set isFirstRun(bool value) => _isFirstRun = value;

  DateTime? get firstRunDate => _firstRunDate;
  set firstRunDate(DateTime? value) => _firstRunDate = value;

  double get weeklyAmount => _weeklyAmount;
  set weeklyAmount(double value) => _weeklyAmount = value;

  FirebaseFirestore get firestore => _firestore;
  Connectivity get connectivity => _connectivity;

  static String generateId() => const Uuid().v4();

  Future<void> uploadRoutines(List<Routine> routines) async {
    await checkInternetConnection();
    try {
      var routinesCollection = _firestore.collection("routines");
      for (var routine in routines) {
        await routinesCollection.add(routine.toMap());
      }
    } catch (e) {
      logError('Error uploading routines', e);
      rethrow;
    }
  }

  Future<int> getDailyData() async {
    await checkInternetConnection();
    try {
      String today = DateTime.now().toIso8601String().split('T')[0];
      var dailyDoc = _firestore.collection("dailyData").doc(today);
      var snapshot = await dailyDoc.get();
      if (snapshot.exists) {
        return snapshot.data()?["totalCount"] ?? 0;
      } else {
        await dailyDoc.set({"totalCount": 0});
        return 0;
      }
    } catch (e) {
      logError('Error getting daily data', e);
      return -1;
    }
  }

  Future<List<Routine>> restoreRoutines() async {
    await checkInternetConnection();
    try {
      var snapshot = await _firestore.collection("routines").get();
      return snapshot.docs.map((doc) => Routine.fromMap(doc.data())).toList();
    } catch (e) {
      logError('Error restoring routines', e);
      return [];
    }
  }

  Future<void> checkInternetConnection() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception("No internet connection.");
    }
  }

  void logError(String message, dynamic error) {
    if (kDebugMode) {
      print('$message: $error');
    }
  }
}

final firebaseProvider = FirebaseProvider();
