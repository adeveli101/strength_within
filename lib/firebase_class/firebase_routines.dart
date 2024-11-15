import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/routines.dart';

class FirebaseRoutines {
  final String id;
  final String name;
  final String description;
  final int mainTargetedBodyPartId;
  final int workoutTypeId;
  final bool isFavorite;
  final bool isCustom;
  final int? userProgress;
  final DateTime? lastUsedDate;
  final bool? userRecommended;
  final List<dynamic> exerciseIds;

  FirebaseRoutines({
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
    required this.exerciseIds,
  });

  factory FirebaseRoutines.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return FirebaseRoutines(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      mainTargetedBodyPartId: data['mainTargetedBodyPartId'] as int,
      workoutTypeId: data['workoutTypeId'] as int,
      isFavorite: data['isFavorite'] as bool? ?? false,
      isCustom: data['isCustom'] as bool? ?? false,
      userProgress: data['userProgress'] as int?,
      lastUsedDate: (data['lastUsedDate'] as Timestamp?)?.toDate(),
      userRecommended: data['userRecommended'] as bool?,
      exerciseIds: (data['exerciseIds'] as List<dynamic>?)?.cast<int>() ?? [],
    );
  }

  factory FirebaseRoutines.fromRoutine(Routines routine) {
    return FirebaseRoutines(
      id: routine.id.toString(),
      name: routine.name,
      description: routine.description,
      mainTargetedBodyPartId: routine.mainTargetedBodyPartId,
      workoutTypeId: routine.workoutTypeId,
      exerciseIds: routine.exerciseIds,
      isFavorite: routine.isFavorite,
      isCustom: routine.isCustom,
      userProgress: routine.userProgress,
      lastUsedDate: routine.lastUsedDate,
      userRecommended: routine.userRecommended,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'mainTargetedBodyPartId': mainTargetedBodyPartId,
      'workoutTypeId': workoutTypeId,
      'isFavorite': isFavorite,
      'isCustom': isCustom,
      'userProgress': userProgress,
      'lastUsedDate': lastUsedDate != null ? Timestamp.fromDate(lastUsedDate!) : null,
      'userRecommended': userRecommended,
      'exerciseIds': exerciseIds,
    };
  }

  FirebaseRoutines copyWith({
    String? id,
    String? name,
    String? description,
    int? mainTargetedBodyPartId,
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
  String toString() {
    return 'FirebaseRoutine(id: $id, name: $name, description: $description, mainTargetedBodyPartId: $mainTargetedBodyPartId, workoutTypeId: $workoutTypeId, isFavorite: $isFavorite, isCustom: $isCustom, userProgress: $userProgress, lastUsedDate: $lastUsedDate, userRecommended: $userRecommended, exerciseIds: $exerciseIds)';
  }
}