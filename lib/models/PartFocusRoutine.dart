import 'dart:ui';
import '../utils/routine_helpers.dart';

enum SetType { regular, drop, superSet, tri, giant, normal }

class Parts {
  final int id;
  final String name;
  final int bodyPartId;
  final SetType setType;
  final String additionalNotes;
  final int difficulty;
  bool isFavorite;
  bool isCustom;
  int? userProgress;
  DateTime? lastUsedDate;
  bool? userRecommended;
  final List<dynamic> exerciseIds;

  Parts({
    required this.id,
    required this.name,
    required this.bodyPartId,
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
  factory Parts.fromMap(Map<String, dynamic> map, List<dynamic> exerciseIds) {
    print("Creating Parts object from map: $map"); // Hata ayıklama için eklendi
    final id = map['id'] as int?;
    if (id == null) {
      throw ArgumentError('Invalid part id: null');
    }

    return Parts(
      id: id,
      name: map['name'] as String? ?? '',
      bodyPartId: map['bodyPartId'] as int? ?? 0,
      setType: SetType.values[(map['setType'] as int?) ?? 0],
      additionalNotes: map['additionalNotes'] as String? ?? '',
      difficulty: map['difficulty'] as int? ?? 2,
      isFavorite: (map['isFavorite'] as int?) == 1,
      isCustom: (map['isCustom'] as int?) == 1,
      userProgress: map['userProgress'] as int?,
      lastUsedDate: map['lastUsedDate'] != null ? DateTime.parse(map['lastUsedDate'] as String) : null,
      userRecommended: (map['userRecommended'] as int?) == 1,
      exerciseIds: exerciseIds,
    );
  }




  String get setTypeString => setTypeToStringConverter(setType);
  Color get setTypeColor => setTypeToColorConverter(setType);
  int get exerciseCount => setTypeToExerciseCountConverter(setType);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'Name': name,
      'BodyPartId': bodyPartId,
      'SetType': setType.index,
      'AdditionalNotes': additionalNotes,
      'difficulty': difficulty,
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
    int? difficulty,
    bool? isFavorite,
    bool? isCustom,
    int? userProgress,
    DateTime? lastUsedDate,
    bool? userRecommended,
    List<dynamic>? exerciseIds,
  }) {
    return Parts(
      id: id ?? this.id,
      name: name ?? this.name,
      bodyPartId: bodyPartId ?? this.bodyPartId,
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

  List<int> get safeExerciseIds {
    return exerciseIds.whereType<int>().toList();
  }
  @override
  String toString() {
    return 'Part(id: $id, name: $name, bodyPartId: $bodyPartId,difficulty: $difficulty, setType: $setTypeString, isFavorite: $isFavorite, isCustom: $isCustom, userProgress: $userProgress, lastUsedDate: $lastUsedDate, userRecommended: $userRecommended, exerciseIds: $exerciseIds)';
  }}
