import 'RoutineExercises.dart';
import 'RoutinetargetedBodyParts.dart';

mixin RoutineValidation {
  static const int MIN_NAME_LENGTH = 2;
  static const int MAX_NAME_LENGTH = 100;
  static const int MAX_DESCRIPTION_LENGTH = 500;
  static const int MIN_DIFFICULTY = 1;
  static const int MAX_DIFFICULTY = 5;

  static ValidationResult validateRoutine({
    required String name,
    required String description,
    required List<int> targetedBodyPartIds,
    required int workoutTypeId,
    required int difficulty,
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

    if (difficulty < MIN_DIFFICULTY || difficulty > MAX_DIFFICULTY) {
      return ValidationResult(
        isValid: false,
        message: 'Zorluk seviyesi $MIN_DIFFICULTY-$MAX_DIFFICULTY arasında olmalıdır',
      );
    }

    return ValidationResult(isValid: true);
  }
}

class Routines with RoutineValidation {
  final int id;
  final String name;
  final String description;
  late final List<int> targetedBodyPartIds;
  final int workoutTypeId;
  final int difficulty;
  final bool isFavorite;
  final bool isCustom;
  final int? userProgress;
  final DateTime? lastUsedDate;
  final bool? userRecommended;
  late final List<dynamic> exerciseIds;
  final int goalId;

  Routines({
    required this.id,
    required this.name,
    required this.description,
    List<RoutineTargetedBodyParts>? targetedBodyParts,
    required this.workoutTypeId,
    required this.difficulty,
    required this.goalId,
    List? routineExercises,
    this.isFavorite = false,
    this.isCustom = false,
    this.userProgress,
    this.lastUsedDate,
    this.userRecommended,
  }) {
    exerciseIds = routineExercises?.map((re) => re.exerciseId).toList() ?? [];
    targetedBodyPartIds = targetedBodyParts?.map((tb) => tb.bodyPartId).toList() ?? [];

    final validation = RoutineValidation.validateRoutine(
      name: name,
      description: description,
      targetedBodyPartIds: targetedBodyPartIds,
      workoutTypeId: workoutTypeId,
      difficulty: difficulty,
      exerciseIds: exerciseIds,
    );

    if (!validation.isValid) {
      throw RoutineException(validation.message);
    }
  }

  factory Routines.fromMap(Map<String, dynamic> map) {
    try {
      List<RoutineTargetedBodyParts> targetedParts = [];
      if (map['targetedBodyParts'] != null) {
        targetedParts = (map['targetedBodyParts'] as List)
            .map((item) => RoutineTargetedBodyParts.fromMap(item))
            .toList();
      }

      return Routines(
        id: map['id'] as int? ?? 0,
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        targetedBodyParts: targetedParts,
        workoutTypeId: map['workoutTypeId'] as int? ?? 0,
        difficulty: map['difficulty'] as int? ?? 1,
        isFavorite: map['isFavorite'] as bool? ?? false,
        isCustom: map['isCustom'] as bool? ?? false,
        userProgress: map['userProgress'] as int?,
        lastUsedDate: map['lastUsedDate'] != null
            ? DateTime.parse(map['lastUsedDate'] as String)
            : null,
        userRecommended: map['userRecommended'] as bool?,
        routineExercises: [],
        goalId:  map['id'] as int? ?? 0,
      );
    } catch (e) {
      throw RoutineException('Veri dönüştürme hatası: $e');
    }
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'id': id,
        'name': name,
        'description': description,
        'targetedBodyPartIds': targetedBodyPartIds,
        'workoutTypeId': workoutTypeId,
        'difficulty': difficulty,
        'isFavorite': isFavorite,
        'isCustom': isCustom,
        'userProgress': userProgress,
        'lastUsedDate': lastUsedDate?.toIso8601String(),
        'userRecommended': userRecommended,
        'exerciseIds': exerciseIds,
      };
    } catch (e) {
      throw RoutineException('Veri kaydetme hatası: $e');
    }
  }

  Routines copyWith({
    int? id,
    String? name,
    String? description,
    List<RoutineTargetedBodyParts>? targetedBodyParts,
    int? workoutTypeId,
    int? goalId,
    int? difficulty,
    bool? isFavorite,
    bool? isCustom,
    int? userProgress,
    DateTime? lastUsedDate,
    bool? userRecommended,
    List<RoutineExercises>? routineExercises,
  }) {
    return Routines(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      goalId: goalId ?? this.goalId,
      targetedBodyParts: targetedBodyParts ??
          targetedBodyPartIds.map((id) => RoutineTargetedBodyParts(
            routineId: this.id,
            bodyPartId: id,
          )).toList(),
      workoutTypeId: workoutTypeId ?? this.workoutTypeId,
      difficulty: difficulty ?? this.difficulty,
      isFavorite: isFavorite ?? this.isFavorite,
      isCustom: isCustom ?? this.isCustom,
      userProgress: userProgress ?? this.userProgress,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
      userRecommended: userRecommended ?? this.userRecommended,
      routineExercises: routineExercises ?? exerciseIds.asMap().entries.map(
              (entry) => RoutineExercises(
            id: DateTime.now().millisecondsSinceEpoch + entry.key,
            routineId: this.id,
            exerciseId: entry.value,
            orderIndex: entry.key + 1,
          )
      ).toList(),
    );
  }

  @override
  String toString() {
    return 'Routines(id: $id, name: $name, description: $description, '
        'targetedBodyPartIds: $targetedBodyPartIds, workoutTypeId: $workoutTypeId, '
        'difficulty: $difficulty, isFavorite: $isFavorite, isCustom: $isCustom, '
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

class RoutineException implements Exception {
  final String message;
  RoutineException(this.message);

  @override
  String toString() => message;
}