import 'package:cloud_firestore/cloud_firestore.dart';

import 'RoutineHistory.dart';
import 'firebase_routines.dart';

mixin UserValidation {
  static const int MIN_DEVICE_ID_LENGTH = 8;
  static const int MAX_DEVICE_ID_LENGTH = 64;
  static const int MAX_ADDITIONAL_DATA_SIZE = 1000;

  static ValidationResult validateUser({
    required String deviceId,
    required DateTime createdAt,
    required DateTime lastLoginAt,
    Map<String, dynamic>? additionalData,
  }) {
    if (deviceId.isEmpty ||
        deviceId.length < MIN_DEVICE_ID_LENGTH ||
        deviceId.length > MAX_DEVICE_ID_LENGTH) {
      return ValidationResult(
        isValid: false,
        message: 'Device ID $MIN_DEVICE_ID_LENGTH-$MAX_DEVICE_ID_LENGTH karakter arasında olmalıdır',
      );
    }

    if (createdAt.isAfter(DateTime.now())) {
      return ValidationResult(
        isValid: false,
        message: 'Oluşturma tarihi gelecekte olamaz',
      );
    }

    if (lastLoginAt.isBefore(createdAt)) {
      return ValidationResult(
        isValid: false,
        message: 'Son giriş tarihi oluşturma tarihinden önce olamaz',
      );
    }

    if (additionalData != null &&
        additionalData.toString().length > MAX_ADDITIONAL_DATA_SIZE) {
      return ValidationResult(
        isValid: false,
        message: 'Ek veri boyutu çok büyük',
      );
    }

    return ValidationResult(isValid: true);
  }
}

class Users with UserValidation {
  final String id;
  final String deviceId;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final List<FirebaseRoutines> routines;
  final List<RoutineHistory> routineHistory;
  final Map<String, dynamic>? additionalData;

  const Users._({
    required this.id,
    required this.deviceId,
    required this.createdAt,
    required this.lastLoginAt,
    this.routines = const [],
    this.routineHistory = const [],
    this.additionalData,
  });

  factory Users({
    required String id,
    required String deviceId,
    required DateTime createdAt,
    required DateTime lastLoginAt,
    List<FirebaseRoutines> routines = const [],
    List<RoutineHistory> routineHistory = const [],
    Map<String, dynamic>? additionalData,
  }) {
    final validation = UserValidation.validateUser(
      deviceId: deviceId,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      additionalData: additionalData,
    );

    if (!validation.isValid) {
      throw UserException(validation.message);
    }

    return Users._(
      id: id,
      deviceId: deviceId,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      routines: routines,
      routineHistory: routineHistory,
      additionalData: additionalData,
    );
  }

  factory Users.fromFirestore(
      DocumentSnapshot doc, {
        List<FirebaseRoutines>? routines,
        List<RoutineHistory>? routineHistory,
      }) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return Users(
        id: doc.id,
        deviceId: data['deviceId'] as String,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
        routines: routines ?? [],
        routineHistory: routineHistory ?? [],
        additionalData: data['additionalData'] as Map<String, dynamic>?,
      );
    } catch (e) {
      throw UserException('Veri dönüştürme hatası: $e');
    }
  }

  Map<String, dynamic> toFirestore() {
    try {
      return {
        'deviceId': deviceId,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLoginAt': Timestamp.fromDate(lastLoginAt),
        if (additionalData != null) 'additionalData': additionalData,
      };
    } catch (e) {
      throw UserException('Veri kaydetme hatası: $e');
    }
  }
}

class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult({
    required this.isValid,
    this.message = '',
  });
}

class UserException implements Exception {
  final String message;
  UserException(this.message);

  @override
  String toString() => message;
}