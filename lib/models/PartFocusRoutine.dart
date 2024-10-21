import 'dart:ui';
import '../utils/routine_helpers.dart';
import 'PartFocusRoutineExercises.dart';

enum SetType { regular, drop, superSet, tri, giant, normal }

class Parts {
  final int id;
  final String name;
  final int bodyPartId;
  final SetType setType;
  final String additionalNotes;
  bool isFavorite;
  bool isCustom;
  int? userProgress;
  DateTime? lastUsedDate;
  bool? userRecommended;
  final List<int> exerciseIds;

  Parts({
    required this.id,
    required this.name,
    required this.bodyPartId,
    required this.setType,
    required this.additionalNotes,
    this.isFavorite = false,
    this.isCustom = false,
    this.userProgress,
    this.lastUsedDate,
    this.userRecommended,
    required this.exerciseIds,
  });
  factory Parts.fromMap(Map<String, dynamic> map, List<int> exerciseIds) {
    return Parts(
      id: map['Id'] as int? ?? 0,
      name: map['Name'] as String? ?? '',
      bodyPartId: map['BodyPartId'] as int? ?? 0,
      setType: SetType.values[(map['SetType'] as int?) ?? 0],
      additionalNotes: map['AdditionalNotes'] as String? ?? '',
      isFavorite: (map['IsFavorite'] as int?) == 1,
      isCustom: (map['IsCustom'] as int?) == 1,
      userProgress: map['UserProgress'] as int?,
      lastUsedDate: map['LastUsedDate'] != null ? DateTime.parse(map['LastUsedDate'] as String) : null,
      userRecommended: (map['UserRecommended'] as int?) == 1,
      exerciseIds: exerciseIds,
    );
  }


  String get setTypeString => setTypeToStringConverter(setType);
  Color get setTypeColor => setTypeToColorConverter(setType);
  int get exerciseCount => setTypeToExerciseCountConverter(setType);

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Name': name,
      'BodyPartId': bodyPartId,
      'SetType': setType.index,
      'AdditionalNotes': additionalNotes,
      'IsFavorite': isFavorite,
      'IsCustom': isCustom,
      'UserProgress': userProgress,
      'LastUsedDate': lastUsedDate?.toIso8601String(),
      'UserRecommended': userRecommended,
    };
  }

  Parts copyWith({
    int? id,
    String? name,
    int? bodyPartId,
    SetType? setType,
    String? additionalNotes,
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
      bodyPartId: bodyPartId ?? this.bodyPartId,
      setType: setType ?? this.setType,
      additionalNotes: additionalNotes ?? this.additionalNotes,
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
    return 'Part(id: $id, name: $name, bodyPartId: $bodyPartId, setType: $setTypeString, isFavorite: $isFavorite, isCustom: $isCustom, userProgress: $userProgress, lastUsedDate: $lastUsedDate, userRecommended: $userRecommended, exerciseIds: $exerciseIds)';
  }}
