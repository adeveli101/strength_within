import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:workout/models/routine.dart';
import 'package:workout/resource/shared_prefs_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FirebaseProvider {
  static final FirebaseProvider _instance = FirebaseProvider._internal();
  bool _isFirstRun = true;
  DateTime? _firstRunDate;
  double _weeklyAmount = 0;

  bool get isFirstRun => _isFirstRun;
  DateTime? get firstRunDate => _firstRunDate;
  double get weeklyAmount => _weeklyAmount;
  set isFirstRun(bool value) => _isFirstRun = value;
  set firstRunDate(DateTime? value) => _firstRunDate = value;
  set weeklyAmount(double value) => _weeklyAmount = value;


  factory FirebaseProvider() {
    return _instance;
  }

  FirebaseProvider._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  User? _firebaseUser;
  User? get firebaseUser => _firebaseUser;
  FirebaseAuth get auth => _firebaseAuth;
  FirebaseFirestore get firestore => _firestore;
  GoogleSignIn get googleSignIn => _googleSignIn;
  Connectivity get connectivity => _connectivity;

  set firebaseUser(User? user) {
    _firebaseUser = user;
  }

  static const String firstRunDateKey = "firstRunDate";
  static const String emailKey = "email";
  static const String passwordKey = "password";

  String get getFirstRunDateKey => firstRunDateKey;
  String get getEmailKey => emailKey;
  String get getPasswordKey => passwordKey;

  static String generateId() => const Uuid().v4();

  Future uploadRoutines(List routines) async {
    await checkInternetConnection();
    await checkAuthentication();
    try {
      var userDoc = _firestore.collection("users").doc(_firebaseUser!.uid);
      var snapshot = await userDoc.get();
      if (snapshot.exists) {
        await userDoc.update({
          "routines": routines.map((routine) => routine.toMap()).toList()
        });
      } else {
        String? firstRunDate = await _secureStorage.read(key: firstRunDateKey);
        await userDoc.set({
          "registerDate": firstRunDate,
          "email": _firebaseUser!.email,
          "routines": routines.map((routine) => routine.toMap()).toList()
        });
      }
    } catch (e) {
      logError('Error uploading routines', e);
      rethrow;
    }
  }

  Future getDailyData() async {
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

  Future handleRestore() async {
    await checkAuthentication();
    try {
      var snapshot = await _firestore.collection("users").doc(_firebaseUser!.uid).get();
      if (snapshot.exists) {
        await _secureStorage.write(key: firstRunDateKey, value: snapshot.data()?["registerDate"]);
        return snapshot;
      }
      return null;
    } catch (e) {
      logError('Error handling restore', e);
      return null;
    }
  }

  Future checkUserExists() async {
    await checkAuthentication();
    try {
      var snapshot = await _firestore.collection('users').doc(_firebaseUser!.uid).get();
      return snapshot.exists;
    } catch (e) {
      logError('Error checking user existence', e);
      return false;
    }
  }

  Future<List<Routine>> restoreRoutines() async {
    await checkAuthentication();
    try {
      var snapshot = await _firestore.collection("users").doc(_firebaseUser!.uid).get();
      var routinesData = snapshot.data()?["routines"];
      if (routinesData == null) return [];
      return (routinesData as List).map((json) => Routine.fromMap(json)).toList();
    } catch (e) {
      logError('Error restoring routines', e);
      return [];
    }
  }

  Future signInSilently() async {
    try {
      var signInMethod = await sharedPrefsProvider.getSignInMethod();
      String? email = await _secureStorage.read(key: emailKey);
      String? password = await _secureStorage.read(key: passwordKey);
      if (email != null && password != null) {
        var userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
        _firebaseUser = userCredential.user;
        return _firebaseUser;
      }
    } catch (e) {
      logError('Silent sign-in failed', e);
    }
    return null;
  }

  Future signInApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      _firebaseUser = userCredential.user;
      if (_firebaseUser != null) {
        await sharedPrefsProvider.setSignInMethod(SignInMethod.apple);
        await _secureStorage.write(key: emailKey, value: _firebaseUser!.email);
        await _secureStorage.write(key: passwordKey, value: credential.userIdentifier);
        String displayName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
        if (displayName.isNotEmpty) {
          await _firebaseUser?.updateDisplayName(displayName);
          await _firebaseUser?.reload();
        }
      }
      return _firebaseUser;
    } catch (e) {
      logError('Apple sign-in failed', e);
      return null;
    }
  }

  Future signInGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      _firebaseUser = userCredential.user;
      if (_firebaseUser != null) {
        await sharedPrefsProvider.setSignInMethod(SignInMethod.google);
        await _secureStorage.write(key: emailKey, value: _firebaseUser!.email);
        await _secureStorage.write(key: passwordKey, value: googleUser.id);
        if (googleUser.displayName != null) {
          await _firebaseUser!.updateDisplayName(googleUser.displayName);
          await _firebaseUser!.reload();
        }
      }
      return _firebaseUser;
    } catch (e) {
      logError('Google sign-in failed', e);
      return null;
    }
  }

  Future signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
      _secureStorage.deleteAll(),
      sharedPrefsProvider.signOut(),
    ]);
    _firebaseUser = null;
  }

  Future checkInternetConnection() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception("No internet connection.");
    }
  }

  Future checkAuthentication() async {
    if (_firebaseUser == null) {
      throw Exception("User not authenticated.");
    }
  }

  void logError(String message, dynamic error) {
    if (kDebugMode) {
      print('$message: $error');
    }
    // Implement secure logging here
  }
}

final firebaseProvider = FirebaseProvider();
