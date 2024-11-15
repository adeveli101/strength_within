import 'package:cloud_firestore/cloud_firestore.dart';

class RoutineHistory {
  final String id;
  final String userId; // Kullanıcıya referans
  final String routineId; // Firebase'deki rutin ID'si
  final DateTime completedDate;
  final Map<String, dynamic>? additionalData;
  final bool isCustom;

  RoutineHistory({
    required this.id,
    required this.userId,
    required this.routineId,
    required this.completedDate,
    this.additionalData,
    this.isCustom = false,
  });

  factory RoutineHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoutineHistory(
      id: doc.id,
      userId: data['userId'] as String,
      routineId: data['routineId'] as String,
      completedDate: (data['completedDate'] as Timestamp).toDate(),
      additionalData: data['additionalData'] as Map<String, dynamic>?,
      isCustom: data['isCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'routineId': routineId,
      'completedDate': Timestamp.fromDate(completedDate),
      if (additionalData != null) 'additionalData': additionalData,
      'isCustom': isCustom,
    };
  }


  RoutineHistory copyWith({
    String? id,
    String? userId,
    String? routineId,
    DateTime? completedDate,
    Map<String, dynamic>? additionalData,
    bool? isCustom,
  }) {
    return RoutineHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      routineId: routineId ?? this.routineId,
      completedDate: completedDate ?? this.completedDate,
      additionalData: additionalData ?? this.additionalData,
      isCustom: isCustom ?? this.isCustom,
    );
  }

}
