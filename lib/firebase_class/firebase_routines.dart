import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/routines.dart';

mixin FirebaseRoutineValidation {
  static const int MIN_NAME_LENGTH = 2;
  static const int MAX_NAME_LENGTH = 100;
  static const int MAX_DESCRIPTION_LENGTH = 500;
  static const int MAX_EXERCISES = 50;

  static ValidationResult validateFirebaseRoutine({
    required String name,
    required String description,
    required List<dynamic> targetedBodyPartIds,
    required int workoutTypeId,
    required List<dynamic> exerciseIds,
  }) {
    if (name.isEmpty || name.length < MIN_NAME_LENGTH || name.length > MAX_NAME_LENGTH) {
      return ValidationResult(
        isValid: false,
        message: 'İsim $MIN_NAME_LENGTH-$MAX_NAME_LENGTH karakter arasında olmalıdır',
      );
    }

    if (description.length > MAX_DESCRIPTION_LENGTH) {
      return ValidationResult(
        isValid: false,
        message: 'Açıklama $MAX_DESCRIPTION_LENGTH karakterden uzun olamaz',
      );
    }

    if (targetedBodyPartIds.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'En az bir hedef bölge seçilmelidir',
      );
    }

    if (workoutTypeId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz antrenman tipi',
      );
    }

    if (exerciseIds.isEmpty || exerciseIds.length > MAX_EXERCISES) {
      return ValidationResult(
        isValid: false,
        message: 'Egzersiz sayısı 1-$MAX_EXERCISES arasında olmalıdır',
      );
    }

    return ValidationResult(isValid: true);
  }
}

class FirebaseRoutines with FirebaseRoutineValidation {
  final String id;
  final String name;
  final String description;
  final List<dynamic> targetedBodyPartIds;
  final int workoutTypeId;
  final bool isFavorite;
  final bool isCustom;
  final int? userProgress;
  final DateTime? lastUsedDate;
  final bool? userRecommended;
  final List<dynamic> exerciseIds;

  const FirebaseRoutines._({
    required this.id,
    required this.name,
    required this.description,
    required this.targetedBodyPartIds,
    required this.workoutTypeId,
    required this.isFavorite,
    required this.isCustom,
    this.userProgress,
    this.lastUsedDate,
    this.userRecommended,
    required this.exerciseIds,
  });

  factory FirebaseRoutines({
    required String id,
    required String name,
    required String description,
    required List<dynamic> targetedBodyPartIds,
    required int workoutTypeId,
    bool isFavorite = false,
    bool isCustom = false,
    int? userProgress,
    DateTime? lastUsedDate,
    bool? userRecommended,
    required List<dynamic> exerciseIds,
  }) {
    final validation = FirebaseRoutineValidation.validateFirebaseRoutine(
      name: name,
      description: description,
      targetedBodyPartIds: targetedBodyPartIds,
      workoutTypeId: workoutTypeId,
      exerciseIds: exerciseIds,
    );

    if (!validation.isValid) {
      throw FirebaseRoutineException(validation.message);
    }

    return FirebaseRoutines._(
      id: id,
      name: name,
      description: description,
      targetedBodyPartIds: targetedBodyPartIds,
      workoutTypeId: workoutTypeId,
      isFavorite: isFavorite,
      isCustom: isCustom,
      userProgress: userProgress,
      lastUsedDate: lastUsedDate,
      userRecommended: userRecommended,
      exerciseIds: exerciseIds,
    );
  }

  factory FirebaseRoutines.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return FirebaseRoutines(
        id: doc.id,
        name: data['name'] as String? ?? '',
        description: data['description'] as String? ?? '',
        targetedBodyPartIds: (data['targetedBodyPartIds'] as List<dynamic>?)?.cast<int>() ?? [],
        workoutTypeId: data['workoutTypeId'] as int? ?? 0,
        isFavorite: data['isFavorite'] as bool? ?? false,
        isCustom: data['isCustom'] as bool? ?? false,
        userProgress: data['userProgress'] as int?,
        lastUsedDate: (data['lastUsedDate'] as Timestamp?)?.toDate(),
        userRecommended: data['userRecommended'] as bool?,
        exerciseIds: (data['exerciseIds'] as List<dynamic>?)?.cast<int>() ?? [],
      );
    } catch (e) {
      throw FirebaseRoutineException('Veri dönüştürme hatası: $e');
    }
  }

  factory FirebaseRoutines.fromRoutine(Routines routine) {
    try {
      return FirebaseRoutines(
        id: routine.id.toString(),
        name: routine.name,
        description: routine.description,
        targetedBodyPartIds: routine.targetedBodyPartIds,
        workoutTypeId: routine.workoutTypeId,
        exerciseIds: routine.exerciseIds,
        isFavorite: routine.isFavorite,
        isCustom: routine.isCustom,
        userProgress: routine.userProgress,
        lastUsedDate: routine.lastUsedDate,
        userRecommended: routine.userRecommended,
      );
    } catch (e) {
      throw FirebaseRoutineException('Routine dönüştürme hatası: $e');
    }
  }

  Map<String, dynamic> toFirestore() {
    try {
      return {
        'name': name,
        'description': description,
        'targetedBodyPartIds': targetedBodyPartIds,
        'workoutTypeId': workoutTypeId,
        'isFavorite': isFavorite,
        'isCustom': isCustom,
        'userProgress': userProgress,
        'lastUsedDate': lastUsedDate != null ? Timestamp.fromDate(lastUsedDate!) : null,
        'userRecommended': userRecommended,
        'exerciseIds': exerciseIds,
      };
    } catch (e) {
      throw FirebaseRoutineException('Veri kaydetme hatası: $e');
    }
  }

  FirebaseRoutines copyWith({
    String? id,
    String? name,
    String? description,
    List<dynamic>? targetedBodyPartIds,
    int? workoutTypeId,
    bool? isFavorite,
    bool? isCustom,
    int? userProgress,
    DateTime? lastUsedDate,
    bool? userRecommended,
    List<dynamic>? exerciseIds,
  }) {
    return FirebaseRoutines(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetedBodyPartIds: targetedBodyPartIds ?? this.targetedBodyPartIds,
      workoutTypeId: workoutTypeId ?? this.workoutTypeId,
      isFavorite: isFavorite ?? this.isFavorite,
      isCustom: isCustom ?? this.isCustom,
      userProgress: userProgress ?? this.userProgress,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
      userRecommended: userRecommended ?? this.userRecommended,
      exerciseIds: exerciseIds ?? this.exerciseIds,
    );
  }

  @override
  String toString() {
    return 'FirebaseRoutine(id: $id, name: $name, description: $description, '
        'targetedBodyPartIds: $targetedBodyPartIds, workoutTypeId: $workoutTypeId, '
        'isFavorite: $isFavorite, isCustom: $isCustom, '
        'userProgress: $userProgress, lastUsedDate: $lastUsedDate, '
        'userRecommended: $userRecommended, exerciseIds: $exerciseIds)';
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

class FirebaseRoutineException implements Exception {
  final String message;
  FirebaseRoutineException(this.message);

  @override
  String toString() => message;
}