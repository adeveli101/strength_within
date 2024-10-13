import 'dart:convert';

enum MainTargetedBodyPart { abs, arm, back, chest, leg, shoulder, fullBody }

class Routine {
  int id;
  String name;
  MainTargetedBodyPart mainTargetedBodyPart;
  List<int> partIds;
  DateTime createdDate;
  DateTime? lastCompletedDate;
  int completionCount;
  bool isRecommended;
  bool isFavorite; // Yeni eklenen özellik
  int difficulty; // Yeni eklenen özellik (1-3 arası bir değer olabilir)
  int estimatedTime; // Yeni eklenen özellik (dakika cinsinden)

  Routine({
    required this.id,
    required this.name,
    required this.mainTargetedBodyPart,
    required this.partIds,
    required this.createdDate,
    this.lastCompletedDate,
    this.completionCount = 0,
    this.isRecommended = false,
    this.isFavorite = false, // Varsayılan değer
    this.difficulty = 1, // Varsayılan değer
    this.estimatedTime = 30, // Varsayılan değer
  });

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['Id'] as int,
      name: map['Name'] as String,
      mainTargetedBodyPart: MainTargetedBodyPart.values.firstWhere(
            (e) => e.toString() == 'MainTargetedBodyPart.${map['MainTargetedBodyPart']}',
        orElse: () => MainTargetedBodyPart.fullBody,
      ),
      partIds: (map['PartIds'] as String?)?.split(',').map((e) => int.parse(e)).toList() ?? [],
      createdDate: DateTime.parse(map['CreatedDate'] as String),
      lastCompletedDate: map['LastCompletedDate'] != null ? DateTime.parse(map['LastCompletedDate'] as String) : null,
      completionCount: map['CompletionCount'] as int? ?? 0,
      isRecommended: (map['IsRecommended'] as int?) == 1,
      difficulty: map['Difficulty'] as int? ?? 1,
      estimatedTime: map['EstimatedTime'] as int? ?? 30,
      isFavorite: (map['IsFavorite'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'RoutineName': name,
      'MainPart': mainTargetedBodyPart.index,
      'Parts': jsonEncode(partIds),
      'CreatedDate': createdDate.toIso8601String(),
      'LastCompletedDate': lastCompletedDate?.toIso8601String(),
      'Count': completionCount,
      'IsRecommended': isRecommended ? 1 : 0,
      'IsFavorite': isFavorite ? 1 : 0, // Yeni eklenen
      'Difficulty': difficulty, // Yeni eklenen
      'EstimatedTime': estimatedTime, // Yeni eklenen

    };
  }

  Routine copyWith({
    int? id,
    String? name,
    MainTargetedBodyPart? mainTargetedBodyPart,
    List<int>? partIds,
    DateTime? createdDate,
    DateTime? lastCompletedDate,
    int? completionCount,
    bool? isRecommended,
    bool? isFavorite, // Yeni eklenen
    int? difficulty, // Yeni eklenen
    int? estimatedTime, // Yeni eklenen
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      mainTargetedBodyPart: mainTargetedBodyPart ?? this.mainTargetedBodyPart,
      partIds: partIds ?? List.from(this.partIds),
      createdDate: createdDate ?? this.createdDate,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      completionCount: completionCount ?? this.completionCount,
      isRecommended: isRecommended ?? this.isRecommended,
      isFavorite: isFavorite ?? this.isFavorite, // Yeni eklenen
      difficulty: difficulty ?? this.difficulty, // Yeni eklenen
      estimatedTime: estimatedTime ?? this.estimatedTime, // Yeni eklenen
    );
  }

  @override
  String toString() => 'Routine(id: $id, name: $name, difficulty: $difficulty, isFavorite: $isFavorite)';
}