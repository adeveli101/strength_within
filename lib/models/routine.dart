import 'dart:convert';
import 'part.dart';

enum MainTargetedBodyPart { abs, arm, back, chest, leg, shoulder, fullBody }

class Routine {
  late final int id;
  late final MainTargetedBodyPart mainTargetedBodyPart;
  final List<int> routineHistory;
  final List<int> weekdays;
  late final String routineName;
  final List<Part> parts;
  final DateTime lastCompletedDate;
  final DateTime createdDate;
  final int completionCount;

  Routine({
    required this.id,
    required this.mainTargetedBodyPart,
    required this.routineName,
    required List<Part> parts,
    required this.createdDate,
    DateTime? lastCompletedDate,
    int? completionCount,
    List<int>? routineHistory,
    List<int>? weekdays,
  }) :
        parts = parts.isNotEmpty ? parts : [],
        lastCompletedDate = lastCompletedDate ?? DateTime.now(),
        completionCount = completionCount ?? 0,
        routineHistory = routineHistory ?? [],
        weekdays = weekdays ?? [];

  static Map<bool, String> checkIfAnyNull(Routine routine) {
    for (var part in routine.parts) {
      var map = Part.validatePart(part);
      if (!map.keys.first) return map;
    }
    if (routine.routineName.isEmpty) {
      return {false: 'Please give your routine a name.'};
    }
    return {true: ''};
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map["Id"] as int,
      routineName: map['RoutineName'] as String,
      mainTargetedBodyPart: MainTargetedBodyPart.values[map['MainPart'] as int],
      parts: map['Parts'] != null
          ? (jsonDecode(map['Parts']) as List).map((partMap) => Part.fromMap(partMap as Map<String, dynamic>)).toList()
          : [],
      lastCompletedDate: map['LastCompletedDate'] != null
          ? DateTime.parse(map['LastCompletedDate'] as String)
          : null,
      createdDate: map['CreatedDate'] != null
          ? DateTime.parse(map['CreatedDate'] as String)
          : DateTime.now(),
      completionCount: map['Count'] as int,
      routineHistory: map["RoutineHistory"] != null
          ? (jsonDecode(map['RoutineHistory']) as List<dynamic>).cast<int>()
          : null,
      weekdays: map["Weekdays"] != null
          ? (jsonDecode(map["Weekdays"]) as List<dynamic>).cast<int>()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'RoutineName': routineName,
      'RoutineHistory': jsonEncode(routineHistory),
      'Weekdays': jsonEncode(weekdays),
      'MainPart': mainTargetedBodyPart.index,
      'Parts': jsonEncode(parts.map((part) => part.toMap()).toList()),
      'LastCompletedDate': lastCompletedDate.toIso8601String(),
      'CreatedDate': createdDate.toIso8601String(),
      'Count': completionCount,
    };
  }

  Routine copyWith({
    int? id,
    MainTargetedBodyPart? mainTargetedBodyPart,
    List<int>? routineHistory,
    List<int>? weekdays,
    String? routineName,
    List<Part>? parts,
    DateTime? lastCompletedDate,
    DateTime? createdDate,
    int? completionCount,
  }) {
    return Routine(
      id: id ?? this.id,
      mainTargetedBodyPart: mainTargetedBodyPart ?? this.mainTargetedBodyPart,
      routineName: routineName ?? this.routineName,
      parts: parts ?? this.parts.map((part) => Part.copyFromPart(part)).toList(),
      createdDate: createdDate ?? this.createdDate,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      completionCount: completionCount ?? this.completionCount,
      routineHistory: routineHistory ?? List.from(this.routineHistory),
      weekdays: weekdays ?? List.from(this.weekdays),
    );
  }

  Routine copyWithoutHistory() {
    return copyWith(routineHistory: [], weekdays: []);
  }

  @override
  String toString() => 'Routine(id: $id, name: $routineName)';
}
