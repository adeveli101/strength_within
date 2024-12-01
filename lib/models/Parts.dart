import 'dart:ui';

import '../ai_services/Feature.dart';
import '../utils/routine_helpers.dart';

mixin PartsValidation {
  static const int MIN_NAME_LENGTH = 2;
  static const int MAX_NAME_LENGTH = 100;
  static const int MIN_DIFFICULTY = 1;
  static const int MAX_DIFFICULTY = 5;
  static const int MAX_NOTE_LENGTH = 500;

  static ValidationResult validateParts({
    required String name,
    required List<int> targetedBodyPartIds,
    required SetType setType,
    required String additionalNotes,
    required int difficulty,
    required List<int> exerciseIds,
  }) {
    if (name.length < MIN_NAME_LENGTH || name.length > MAX_NAME_LENGTH) {
      return ValidationResult(
        isValid: false,
        message: 'İsim $MIN_NAME_LENGTH-$MAX_NAME_LENGTH karakter arasında olmalıdır',
      );
    }

    if (targetedBodyPartIds.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'En az bir hedef bölge seçilmelidir',
      );
    }

    if (difficulty < MIN_DIFFICULTY || difficulty > MAX_DIFFICULTY) {
      return ValidationResult(
        isValid: false,
        message: 'Zorluk seviyesi $MIN_DIFFICULTY-$MAX_DIFFICULTY arasında olmalıdır',
      );
    }

    if (additionalNotes.length > MAX_NOTE_LENGTH) {
      return ValidationResult(
        isValid: false,
        message: 'Notlar $MAX_NOTE_LENGTH karakterden uzun olamaz',
      );
    }

    if (exerciseIds.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'En az bir egzersiz seçilmelidir',
      );
    }

    return ValidationResult(isValid: true);
  }
}

class Parts with PartsValidation {
  final int id;
  final String name;
  final List<int> targetedBodyPartIds;
  final SetType setType;
  final String additionalNotes;
  final int difficulty;
  bool isFavorite;
  bool isCustom;
  int? userProgress;
  DateTime? lastUsedDate;
  bool? userRecommended;
  final List<int> exerciseIds;

  Parts._({
    required this.id,
    required this.name,
    required this.targetedBodyPartIds,
    required this.setType,
    required this.additionalNotes,
    required this.difficulty,
    this.isFavorite = false,
    this.isCustom = false,
    this.userProgress,
    this.lastUsedDate,
    this.userRecommended,
    required this.exerciseIds,
  });

  factory Parts({
    required int id,
    required String name,
    required List<int> targetedBodyPartIds,
    required SetType setType,
    required String additionalNotes,
    required int difficulty,
    bool isFavorite = false,
    bool isCustom = false,
    int? userProgress,
    DateTime? lastUsedDate,
    bool? userRecommended,
    required List<int> exerciseIds,
  }) {
    final validation = PartsValidation.validateParts(
      name: name,
      targetedBodyPartIds: targetedBodyPartIds,
      setType: setType,
      additionalNotes: additionalNotes,
      difficulty: difficulty,
      exerciseIds: exerciseIds,
    );

    if (!validation.isValid) {
      throw PartsException(validation.message);
    }

    return Parts._(
      id: id,
      name: name,
      targetedBodyPartIds: targetedBodyPartIds,
      setType: setType,
      additionalNotes: additionalNotes,
      difficulty: difficulty,
      isFavorite: isFavorite,
      isCustom: isCustom,
      userProgress: userProgress,
      lastUsedDate: lastUsedDate,
      userRecommended: userRecommended,
      exerciseIds: exerciseIds,
    );
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'id': id,
        'name': name,
        'targetedBodyPartIds': targetedBodyPartIds,
        'setType': setType.index,
        'additionalNotes': additionalNotes,
        'difficulty': difficulty,
        'isFavorite': isFavorite ? 1 : 0,
        'isCustom': isCustom ? 1 : 0,
        'userProgress': userProgress,
        'lastUsedDate': lastUsedDate?.toIso8601String(),
        'userRecommended': userRecommended == true ? 1 : 0,
      };
    } catch (e) {
      throw PartsException('Veri kaydetme hatası: $e');
    }
  }


  Parts copyWith({
    int? id,
    String? name,
    List<int>? targetedBodyPartIds,
    SetType? setType,
    String? additionalNotes,
    int? difficulty,
    bool? isFavorite,
    bool? isCustom,
    int? userProgress,
    DateTime? lastUsedDate,
    bool? userRecommended,
    List<int>? exerciseIds,
  }) {
    return Parts(
      id: id ?? this.id,
      name: name ?? this.name,
      targetedBodyPartIds: targetedBodyPartIds ?? this.targetedBodyPartIds,
      setType: setType ?? this.setType,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      difficulty: difficulty ?? this.difficulty,
      isFavorite: isFavorite ?? this.isFavorite,
      isCustom: isCustom ?? this.isCustom,
      userProgress: userProgress ?? this.userProgress,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
      userRecommended: userRecommended ?? this.userRecommended,
      exerciseIds: exerciseIds ?? this.exerciseIds,
    );
  }

  // Yardımcı getter
  String get setTypeString => setTypeToStringConverter(setType);
  Color get setTypeColor => setTypeToColorConverter(setType);
  int get exerciseCount => setTypeToExerciseCountConverter(setType);

  // Güvenli egzersiz ID'leri
  List<int> get safeExerciseIds {
    return exerciseIds.whereType<int>().toList();
  }

  // toString
  @override
  String toString() {
    return 'Part(id: $id, name: $name, targetedBodyPartIds: $targetedBodyPartIds, '
        'difficulty: $difficulty, setType: $setTypeString, '
        'isFavorite: $isFavorite, isCustom: $isCustom, '
        'userProgress: $userProgress, lastUsedDate: $lastUsedDate, '
        'userRecommended: $userRecommended, exerciseIds: $exerciseIds)';
  }

  // Eşitlik operatörü
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Parts &&
        other.id == id &&
        other.name == name &&
        listEquals(other.targetedBodyPartIds, targetedBodyPartIds) &&
        other.setType == setType &&
        other.additionalNotes == additionalNotes &&
        other.difficulty == difficulty &&
        other.isFavorite == isFavorite &&
        other.isCustom == isCustom;
  }

  // hashCode eklenmeli
  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      Object.hashAll(targetedBodyPartIds),
      setType,
      additionalNotes,
      difficulty,
      isFavorite,
      isCustom,
    );
  }


  factory Parts.fromMap(Map<String, dynamic> map, List<dynamic> exerciseIds) {
    try {
      final id = map['id'] as int?;
      if (id == null) {
        throw PartsException('Geçersiz part ID: null');
      }

      return Parts(
        id: id,
        name: map['name'] as String? ?? '',
        targetedBodyPartIds: List<int>.from(map['targetedBodyPartIds'] ?? []),
        setType: SetType.values[(map['setType'] as int?) ?? 0],
        additionalNotes: map['additionalNotes'] as String? ?? '',
        difficulty: map['difficulty'] as int? ?? 2,
        isFavorite: (map['isFavorite'] as int?) == 1,
        isCustom: (map['isCustom'] as int?) == 1,
        userProgress: map['userProgress'] as int?,
        lastUsedDate: map['lastUsedDate'] != null ?
        DateTime.parse(map['lastUsedDate'] as String) : null,
        userRecommended: (map['userRecommended'] as int?) == 1,
        exerciseIds: exerciseIds.map((e) => int.parse(e.toString())).toList(),
      );
    } catch (e) {
      throw PartsException('Veri dönüştürme hatası: $e');
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

class PartsException implements Exception {
  final String message;
  PartsException(this.message);

  @override
  String toString() => message;
}