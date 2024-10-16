import '../utils/routine_helpers.dart';
import 'WorkoutType.dart';
import 'BodyPart.dart';

class Routine {
  final int id;
  final String name;
  final MainTargetedBodyPart mainTargetedBodyPart;
  final WorkoutType workoutType;
  final List<int> partIds;  // List<int> olarak değiştirildi
  final bool isRecommended;
  final int difficulty;
  final int estimatedTime;
  final String mainTargetedBodyPartString;

  Routine({
    required this.id,
    required this.name,
    required this.mainTargetedBodyPart,
    required this.workoutType,
    required this.partIds,
    required this.isRecommended,
    required this.difficulty,
    required this.estimatedTime,
  }) : mainTargetedBodyPartString = mainTargetedBodyPartToStringConverter(mainTargetedBodyPart);

  factory Routine.fromMap(Map map) {
    return Routine(
      id: map['Id'] as int,
      name: map['Name'] as String,
      mainTargetedBodyPart: MainTargetedBodyPart.values[map['MainTargetedBodyPart'] as int],
      workoutType: WorkoutType.fromMap(map['WorkoutType'] as Map<String, dynamic>),
      partIds: (map['PartIds'] as String).split(',').map((e) => int.parse(e)).toList(),
      isRecommended: map['IsRecommended'] == 1,
      difficulty: map['Difficulty'] as int,
      estimatedTime: map['EstimatedTime'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Name': name,
      'MainTargetedBodyPart': mainTargetedBodyPart.index,
      'WorkoutType': workoutType.toMap(),
      'PartIds': partIds.join(','),
      'IsRecommended': isRecommended ? 1 : 0,
      'Difficulty': difficulty,
      'EstimatedTime': estimatedTime,
    };
  }

  Routine copyWith({
    int? id,
    String? name,
    MainTargetedBodyPart? mainTargetedBodyPart,
    WorkoutType? workoutType,
    List<int>? partIds,
    bool? isRecommended,
    int? difficulty,
    int? estimatedTime,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      mainTargetedBodyPart: mainTargetedBodyPart ?? this.mainTargetedBodyPart,
      workoutType: workoutType ?? this.workoutType,
      partIds: partIds ?? this.partIds,
      isRecommended: isRecommended ?? this.isRecommended,
      difficulty: difficulty ?? this.difficulty,
      estimatedTime: estimatedTime ?? this.estimatedTime,
    );
  }

  @override
  String toString() => 'Routine(id: $id, name: $name, mainTargetedBodyPart: $mainTargetedBodyPartString, workoutType: $workoutType, difficulty: $difficulty, isRecommended: $isRecommended)';
}
