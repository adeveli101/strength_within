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

const String firstRunDateKey = "firstRunDate";

class FirebaseProvider {
  AuthorizationCredentialAppleID? appleIdCredential;
  User? firebaseUser;
  GoogleSignInAccount? googleSignInAccount;
  String? firstRunDate;
  bool isFirstRun = false;
  String? dailyRankInfo;
  int? dailyRank;
  int? weeklyAmount;

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  static String generateId() => const Uuid().v4();

  Future<void> uploadRoutines(List<Routine> routines) async {
    List<ConnectivityResult> connectivityResults = await _connectivity.checkConnectivity();
    if (connectivityResults.isEmpty || connectivityResults.contains(ConnectivityResult.none)) {
      throw Exception("No internet connection.");
    }

    if (firebaseUser == null) return;

    var userDoc = _firestore.collection("users").doc(firebaseUser!.uid);
    var snapshot = await userDoc.get();

    if (snapshot.exists) {
      await userDoc.update({
        "routines": routines.map((routine) => jsonEncode(routine.toMap())).toList()
      });
    } else {
      await userDoc.set({
        "registerDate": firstRunDate,
        "email": firebaseUser!.email,
        "routines": routines.map((routine) => jsonEncode(routine.toMap())).toList()
      });
    }
  }

  Future<int> getDailyData() async {
    List<ConnectivityResult> connectivityResults = await _connectivity.checkConnectivity();

    if (connectivityResults.isEmpty || connectivityResults.contains(ConnectivityResult.none)) {
      return -1;
    }

    String today = DateTime.now().toIso8601String().split('T')[0];
    var dailyDoc = _firestore.collection("dailyData").doc(today);
    var snapshot = await dailyDoc.get();

    if (snapshot.exists) {
      return snapshot.data()?["totalCount"] ?? 0;
    } else {
      await dailyDoc.set({"totalCount": 0});
      return 0;
    }
  }

  Future<DocumentSnapshot?> handleRestore() async {
    if (firebaseUser == null) return null;
    var snapshot = await _firestore.collection("users").doc(firebaseUser!.uid).get();
    if (snapshot.exists) {
      firstRunDate = snapshot.data()?["registerDate"];
      return snapshot;
    }
    return null;
  }

  Future<bool> checkUserExists() async {
    if (firebaseUser == null) return false;
    var snapshot = await _firestore.collection('users').doc(firebaseUser!.uid).get();
    return snapshot.exists;
  }

  Future<List<Routine>> restoreRoutines() async {
    if (firebaseUser == null) return [];
    var snapshot = await _firestore.collection("users").doc(firebaseUser!.uid).get();
    var routinesData = snapshot.data()?["routines"];
    if (routinesData == null) return [];
    return (routinesData as List).map((json) => Routine.fromMap(jsonDecode(json))).toList();
  }

  Future<User?> signInSilently() async {
    var signInMethod = await sharedPrefsProvider.getSignInMethod();
    String? email, password;

    switch (signInMethod) {
      case SignInMethod.apple:
        email = await sharedPrefsProvider.getString(emailKey);
        password = await sharedPrefsProvider.getString(passwordKey);
        break;
      case SignInMethod.google:
        email = await sharedPrefsProvider.getString(gmailKey);
        password = await sharedPrefsProvider.getString(gmailPasswordKey);
        break;
      case SignInMethod.none:
        return null;
    }

    if (email != null && password != null) {
      try {
        var userCredential = await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
        firebaseUser = userCredential.user;
        return firebaseUser;
      } catch (e) {
        if (kDebugMode) {
          if (kDebugMode) {
            print("Silent sign-in failed: $e");
          }
        }
        return null;
      }
    }

    return null;
  }

  Future<User?> signInApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final userCredential = await firebaseAuth.signInWithCredential(oauthCredential);
      firebaseUser = userCredential.user;

      if (firebaseUser != null) {
         sharedPrefsProvider.setSignInMethod(SignInMethod.apple);
        await sharedPrefsProvider.saveEmailAndPassword(firebaseUser!.email!, credential.userIdentifier!);

        String displayName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
        if (displayName.isNotEmpty) {
          await firebaseUser?.updateProfile(displayName: displayName);
          await firebaseUser?.reload();
        }
      }

      return firebaseUser;
    } catch (e) {
      if (kDebugMode) {
        print("Apple sign-in failed: $e");
      }
      return null;
    }
  }

  Future<User?> signInGoogle() async {
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await firebaseAuth.signInWithCredential(credential);
      firebaseUser = userCredential.user;

      if (firebaseUser != null) {
         sharedPrefsProvider.setSignInMethod(SignInMethod.google);
        await sharedPrefsProvider.saveGmailAndPassword(firebaseUser!.email!, googleUser.id);

        if (googleUser.displayName != null) {
          await firebaseUser!.updateDisplayName(googleUser.displayName);
          await firebaseUser!.reload();
        }
      }

      return firebaseUser;
    } catch (e) {
      if (kDebugMode) {
        print("Google sign-in failed: $e");
      }
      return null;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await googleSignIn.signOut();
    firebaseUser = null;
    appleIdCredential = null;
    sharedPrefsProvider.signOut();
  }
}

final firebaseProvider = FirebaseProvider();