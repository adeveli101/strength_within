import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_routines.dart';
import 'RoutineHistory.dart';

class Users {
  final String id;
  final String deviceId;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final List<FirebaseRoutines> routines;
  final List<RoutineHistory> routineHistory;
  final Map<String, dynamic>? additionalData;

  Users({
    required this.id,
    required this.deviceId,
    required this.createdAt,
    required this.lastLoginAt,
    this.routines = const [],
    this.routineHistory = const [],
    this.additionalData,
  });

  factory Users.fromFirestore(
      DocumentSnapshot doc, {
        List<FirebaseRoutines>? routines,
        List<RoutineHistory>? routineHistory,
      }) {
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
  }

  Map toFirestore() {
    return {
      'deviceId': deviceId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      if (additionalData != null) 'additionalData': additionalData,
    };
  }

  static String getIdFromFirestore(DocumentSnapshot doc) {
    return doc.id;
  }


  Users copyWith({
    String? id,
    String? deviceId,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<FirebaseRoutines>? routines,
    List<RoutineHistory>? routineHistory,
    Map<String, dynamic>? additionalData,
  }) {
    return Users(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      routines: routines ?? this.routines,
      routineHistory: routineHistory ?? this.routineHistory,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'Users(id: $id, deviceId: $deviceId, createdAt: $createdAt, lastLoginAt: $lastLoginAt, routines: ${routines.length}, routineHistory: ${routineHistory.length},  additionalData: $additionalData)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Users &&
        other.id == id &&
        other.deviceId == deviceId &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    deviceId.hashCode ^
    createdAt.hashCode ^
    lastLoginAt.hashCode;
  }
}
