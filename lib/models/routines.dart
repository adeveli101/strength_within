import '../firebase_class/firebase_routines.dart';
import '../utils/routine_helpers.dart';
import 'WorkoutType.dart';
import 'BodyPart.dart';

class Routines {
  final int id;
  final String name;
  final MainTargetedBodyPart mainTargetedBodyPart;
  final WorkoutTypes workoutType;
  final List<int> partIds;  // List<int> olarak değiştirildi
  final bool isRecommended;
  final int difficulty;
  final int estimatedTime;
  final String mainTargetedBodyPartString;

  Routines({
    required this.id,
    required this.name,
    required this.mainTargetedBodyPart,
    required this.workoutType,
    required this.partIds,
    required this.isRecommended,
    required this.difficulty,
    required this.estimatedTime,
  }) : mainTargetedBodyPartString = mainTargetedBodyPartToStringConverter(mainTargetedBodyPart);

  factory Routines.fromMap(Map map) {
    return Routines(
      id: map['Id'] as int,
      name: map['Name'] as String,
      mainTargetedBodyPart: MainTargetedBodyPart.values[map['MainTargetedBodyPart'] as int],
      workoutType: WorkoutTypes.fromMap(map['WorkoutType'] as Map<String, dynamic>),
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

  Routines copyWith({
    int? id,
    String? name,
    MainTargetedBodyPart? mainTargetedBodyPart,
    WorkoutTypes? workoutType,
    List<int>? partIds,
    bool? isRecommended,
    int? difficulty,
    int? estimatedTime,
  }) {
    return Routines(
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





  FirebaseRoutine toFirebaseRoutine(String userId) {
    return FirebaseRoutine(
      id: id.toString(), // Eğer id String değilse toString() kullanın
      userId: userId,
      routineId: id,
      userProgress: 0, // Varsayılan değer, gerekirse değiştirin
      lastUsedDate: null, // Varsayılan değer, gerekirse değiştirin
      userRecommended: false, // Varsayılan değer, gerekirse değiştirin
      isCustom: false, // Varsayılan değer, gerekirse değiştirin
      isFavorite: false, // Varsayılan değer, gerekirse değiştirin
    );
  }



  @override
  String toString() => 'Routine(id: $id, name: $name, mainTargetedBodyPart: $mainTargetedBodyPartString, workoutType: $workoutType, difficulty: $difficulty, isRecommended: $isRecommended)';
}
