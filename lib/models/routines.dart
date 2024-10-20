class Routines {
  final int id;
  final String name;
  final String description;
  final int mainTargetedBodyPartId;
  final int workoutTypeId;
  bool isFavorite;
  bool isCustom;
  int? userProgress;
  DateTime? lastUsedDate;
  bool? userRecommended;
  List<int> exerciseIds;

  Routines({
    required this.id,
    required this.name,
    required this.description,
    required this.mainTargetedBodyPartId,
    required this.workoutTypeId,
    this.isFavorite = false,
    this.isCustom = false,
    this.userProgress,
    this.lastUsedDate,
    this.userRecommended,
    this.exerciseIds = const [],
  });

  factory Routines.fromMap(Map<String, dynamic> map) {
    print("fromMap çağrıldı: $map");
    return Routines(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      mainTargetedBodyPartId: map['mainTargetedBodyPartId'],
      workoutTypeId: map['workoutTypeId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Name': name,
      'Description': description,
      'MainTargetedBodyPartId': mainTargetedBodyPartId,
      'WorkoutTypeId': workoutTypeId,
    };
  }

  Routines copyWith({
    int? id,
    String? name,
    String? description,
    int? mainTargetedBodyPartId,
    int? workoutTypeId,
    bool? isFavorite,
    bool? isCustom,
    int? userProgress,
    DateTime? lastUsedDate,
    bool? userRecommended,
    List<int>? exerciseIds,
  }) {
    return Routines(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      mainTargetedBodyPartId: mainTargetedBodyPartId ?? this.mainTargetedBodyPartId,
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
  String toString() => 'Routine(id: $id, name: $name, mainTargetedBodyPartId: $mainTargetedBodyPartId, workoutTypeId: $workoutTypeId, isFavorite: $isFavorite, isCustom: $isCustom, userProgress: $userProgress, lastUsedDate: $lastUsedDate, userRecommended: $userRecommended, exerciseIds: $exerciseIds)';
}