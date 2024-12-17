import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/routine_helpers.dart';


mixin FirebasePartsValidation {
  static const int MIN_NAME_LENGTH = 2;
  static const int MAX_NAME_LENGTH = 100;
  static const int MAX_NOTE_LENGTH = 500;
  static const int MAX_EXERCISES = 50;

  static ValidationResult validateFirebaseParts({
    required String name,
    required List<int> targetedBodyPartIds,
    required SetType setType,
    required String additionalNotes,
    required List<String> exerciseIds,
  }) {
    if (name.isEmpty || name.length < MIN_NAME_LENGTH || name.length > MAX_NAME_LENGTH) {
      return ValidationResult(
        isValid: false,
        message: 'İsim $MIN_NAME_LENGTH-$MAX_NAME_LENGTH karakter arasında olmalıdır',
      );
    }

    if (additionalNotes.length > MAX_NOTE_LENGTH) {
      return ValidationResult(
        isValid: false,
        message: 'Notlar $MAX_NOTE_LENGTH karakterden uzun olamaz',
      );
    }

    if (targetedBodyPartIds.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'En az bir hedef bölge seçilmelidir',
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

class FirebaseParts with FirebasePartsValidation {
  final String id;
  final String name;
  final List<int> targetedBodyPartIds;
  final SetType setType;
  final String additionalNotes;
  final bool isFavorite;
  final bool isCustom;
  final int? userProgress;
  final DateTime? lastUsedDate;
  final bool? userRecommended;
  final List<String> exerciseIds;

  FirebaseParts._({
    required this.id,
    required this.name,
    required this.targetedBodyPartIds,
    required this.setType,
    required this.additionalNotes,
    required this.isFavorite,
    required this.isCustom,
    this.userProgress,
    this.lastUsedDate,
    this.userRecommended,
    required this.exerciseIds,
  });

  factory FirebaseParts({
    required String id,
    required String name,
    required List<int> targetedBodyPartIds,
    required SetType setType,
    String additionalNotes = '',
    bool isFavorite = false,
    bool isCustom = false,
    int? userProgress,
    DateTime? lastUsedDate,
    bool? userRecommended,
    required List<String> exerciseIds,
  }) {
    final validation = FirebasePartsValidation.validateFirebaseParts(
      name: name,
      targetedBodyPartIds: targetedBodyPartIds,
      setType: setType,
      additionalNotes: additionalNotes,
      exerciseIds: exerciseIds,
    );

    if (!validation.isValid) {
      throw FirebasePartsException(validation.message);
    }

    return FirebaseParts._(
      id: id,
      name: name,
      targetedBodyPartIds: targetedBodyPartIds,
      setType: setType,
      additionalNotes: additionalNotes,
      isFavorite: isFavorite,
      isCustom: isCustom,
      userProgress: userProgress,
      lastUsedDate: lastUsedDate,
      userRecommended: userRecommended,
      exerciseIds: exerciseIds,
    );
  }

  factory FirebaseParts.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return FirebaseParts(
        id: doc.id,
        name: data['name'] as String? ?? '',
        targetedBodyPartIds: List<int>.from(data['targetedBodyPartIds'] ?? []),
        setType: SetType.values[(data['setType'] as num?)?.toInt() ?? 0],
        additionalNotes: data['additionalNotes'] as String? ?? '',
        isFavorite: data['isFavorite'] as bool? ?? false,
        isCustom: data['isCustom'] as bool? ?? false,
        userProgress: (data['userProgress'] as num?)?.toInt(),
        lastUsedDate: data['lastUsedDate'] != null
            ? (data['lastUsedDate'] as Timestamp).toDate()
            : null,
        userRecommended: data['userRecommended'] as bool? ?? false,
        exerciseIds: List<String>.from(data['exerciseIds'] ?? []),
      );
    } catch (e) {
      throw FirebasePartsException('Veri dönüştürme hatası: $e');
    }
  }

  Map<String, dynamic> toFirestore() {
    try {
      return {
        'name': name,
        'targetedBodyPartIds': targetedBodyPartIds,
        'setType': setType.index,
        'additionalNotes': additionalNotes,
        'isFavorite': isFavorite,
        'isCustom': isCustom,
        'userProgress': userProgress,
        'lastUsedDate': lastUsedDate != null ? Timestamp.fromDate(lastUsedDate!) : null,
        'userRecommended': userRecommended,
        'exerciseIds': exerciseIds,
      };
    } catch (e) {
      throw FirebasePartsException('Veri kaydetme hatası: $e');
    }
  }}


class FirebasePartsException implements Exception {
  final String message;
  FirebasePartsException(this.message);

  @override
  String toString() => message;
}

class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult({
    required this.isValid,
    this.message = '',
  });
}