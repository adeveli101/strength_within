import 'RoutineExercises.dart';

class Routines {
  final int id;
  final String name;
  final String description;
  final int mainTargetedBodyPartId;
  final int workoutTypeId;
  final int difficulty;
  bool isFavorite;
  bool isCustom;
  int? userProgress;
  DateTime? lastUsedDate;
  bool? userRecommended;
  final List<dynamic> exerciseIds;

  Routines({
    required this.id,
    required this.name,
    required this.description,
    required this.mainTargetedBodyPartId,
    required this.workoutTypeId,
    required this.difficulty,
    List<RoutineExercises>? routineExercises,
    this.isFavorite = false,
    this.isCustom = false,
    this.userProgress,
    this.lastUsedDate,
    this.userRecommended,
  }) : exerciseIds = routineExercises?.map((re) => re.exerciseId).toList() ?? [];

  factory Routines.fromMap(Map<String, dynamic> map) {
    return Routines(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      mainTargetedBodyPartId: map['mainTargetedBodyPartId'] as int? ?? 0,
      difficulty: map['difficulty'] as int,
      workoutTypeId: map['workoutTypeId'] as int? ?? 0,
      routineExercises: [], // Bu kısmı boş bir liste olarak başlatıyoruz
      isFavorite: map['isFavorite'] as bool? ?? false,
      isCustom: map['isCustom'] as bool? ?? false,
      userProgress: map['userProgress'] as int?,
      lastUsedDate: map['lastUsedDate'] != null ? DateTime.parse(map['lastUsedDate']) : null,
      userRecommended: map['userRecommended'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Name': name,
      'Description': description,
      'MainTargetedBodyPartId': mainTargetedBodyPartId,
      'WorkoutTypeId': workoutTypeId,
      'Difficulty': difficulty,
      'IsFavorite': isFavorite,
      'IsCustom': isCustom,
      'UserProgress': userProgress,
      'LastUsedDate': lastUsedDate?.toIso8601String(),
      'UserRecommended': userRecommended,
      'ExerciseIds': exerciseIds,
    };
  }

  Routines copyWith({
    int? id,
    String? name,
    String? description,
    int? mainTargetedBodyPartId,
    int? workoutTypeId,
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
      mainTargetedBodyPartId: mainTargetedBodyPartId ?? this.mainTargetedBodyPartId,
      workoutTypeId: workoutTypeId ?? this.workoutTypeId,
      difficulty: difficulty ?? this.difficulty,
      isFavorite: isFavorite ?? this.isFavorite,
      isCustom: isCustom ?? this.isCustom,
      userProgress: userProgress ?? this.userProgress,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
      userRecommended: userRecommended ?? this.userRecommended,
      routineExercises: routineExercises ?? (this.exerciseIds.map((id) => RoutineExercises(id: 0, routineId: this.id, exerciseId: id)).toList()),
    );
  }

  @override
  String toString() => 'Routine(id: $id, name: $name, mainTargetedBodyPartId: $mainTargetedBodyPartId, workoutTypeId: $workoutTypeId, difficulty: $difficulty, isFavorite: $isFavorite, isCustom: $isCustom, userProgress: $userProgress, lastUsedDate: $lastUsedDate, userRecommended: $userRecommended, exerciseIds: $exerciseIds)';
}