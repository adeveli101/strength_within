import 'package:cloud_firestore/cloud_firestore.dart';

mixin RoutineHistoryValidation {
  static const int MAX_ADDITIONAL_DATA_SIZE = 1000;

  static ValidationResult validateRoutineHistory({
    required String userId,
    required String routineId,
    required DateTime completedDate,
    Map<String, dynamic>? additionalData,
  }) {
    if (userId.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'Kullanıcı ID boş olamaz',
      );
    }

    if (routineId.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'Rutin ID boş olamaz',
      );
    }

    if (completedDate.isAfter(DateTime.now())) {
      return ValidationResult(
        isValid: false,
        message: 'Tamamlanma tarihi gelecekte olamaz',
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

class RoutineHistory with RoutineHistoryValidation {
  final String id;
  final String userId;
  final String routineId;
  final DateTime completedDate;
  final Map<String, dynamic>? additionalData;
  final bool isCustom;

  const RoutineHistory._({
    required this.id,
    required this.userId,
    required this.routineId,
    required this.completedDate,
    this.additionalData,
    required this.isCustom,
  });

  factory RoutineHistory({
    required String id,
    required String userId,
    required String routineId,
    required DateTime completedDate,
    Map<String, dynamic>? additionalData,
    bool isCustom = false,
  }) {
    final validation = RoutineHistoryValidation.validateRoutineHistory(
      userId: userId,
      routineId: routineId,
      completedDate: completedDate,
      additionalData: additionalData,
    );

    if (!validation.isValid) {
      throw RoutineHistoryException(validation.message);
    }

    return RoutineHistory._(
      id: id,
      userId: userId,
      routineId: routineId,
      completedDate: completedDate,
      additionalData: additionalData,
      isCustom: isCustom,
    );
  }

  factory RoutineHistory.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return RoutineHistory(
        id: doc.id,
        userId: data['userId'] as String,
        routineId: data['routineId'] as String,
        completedDate: (data['completedDate'] as Timestamp).toDate(),
        additionalData: data['additionalData'] as Map<String, dynamic>?,
        isCustom: data['isCustom'] as bool? ?? false,
      );
    } catch (e) {
      throw RoutineHistoryException('Veri dönüştürme hatası: $e');
    }
  }

  Map<String, dynamic> toFirestore() {
    try {
      return {
        'userId': userId,
        'routineId': routineId,
        'completedDate': Timestamp.fromDate(completedDate),
        if (additionalData != null) 'additionalData': additionalData,
        'isCustom': isCustom,
      };
    } catch (e) {
      throw RoutineHistoryException('Veri kaydetme hatası: $e');
    }
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

  @override
  String toString() {
    return 'RoutineHistory(id: $id, userId: $userId, routineId: $routineId, '
        'completedDate: $completedDate, additionalData: $additionalData, '
        'isCustom: $isCustom)';
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

class RoutineHistoryException implements Exception {
  final String message;
  RoutineHistoryException(this.message);

  @override
  String toString() => message;
}