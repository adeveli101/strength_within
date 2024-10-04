import 'exercise.dart';

enum TargetedBodyPart {
  abs,
  arm,
  back,
  chest,
  leg,
  shoulder,
  fullBody,
  tricep,
  bicep
}

enum SetType { regular, drop, super_, tri, giant, normal }

class Part {
  bool defaultName;
  SetType setType;
  TargetedBodyPart targetedBodyPart;
  String partName;
  List<Exercise> exercises;
  String additionalNotes;

  Part({
    required this.setType,
    required this.targetedBodyPart,
    required this.exercises,
    required this.partName,
    this.defaultName = false,
    this.additionalNotes = '',
  });

  static String generateDefaultPartName(SetType setType, List<Exercise> exercises) {
    if (exercises.isEmpty) return '';

    switch (setType) {
    case SetType.regular:
    case SetType.drop:
    return exercises[0].name;
    case SetType.super_:
    return '${exercises[0].name} and ${exercises[1].name}';
    case SetType.tri:
    return 'Tri-set of ${exercises[0].name} and more';
    case SetType.giant:
    return 'Giant Set of ${exercises[0].name} and more';
    default:
    return '';
    }
  }

  static Map<bool, String> validatePart(Part part) {
    if (part.partName.isEmpty) {
      return {false: 'Please give your part a name.'};
    }
    for (var exercise in part.exercises) {
      if (exercise.name.isEmpty) {
        return {false: 'Please complete the names of exercises.'};
      }
      if (exercise.reps.isEmpty) {
        return {false: 'Reps of exercises need to be defined.'};
      }
      if (exercise.sets == 0) {
        return {false: 'Sets of exercises need to be defined.'};
      }
      if (exercise.weight <= 0)  {
        return {false: 'Weight of exercises need to be defined.'};
      }
    }
    return {true: ''};
  }

  Part.fromMap(Map<String, dynamic> map)
      : defaultName = map["isDefaultName"] ?? false,
        setType = intToSetTypeConverter(map['setType'] ?? 0),
        targetedBodyPart = intToTargetedBodyPartConverter(map['bodyPart'] ?? 0),
        additionalNotes = map['notes'] ?? '',
        exercises = (map['exercises'] as List?)?.map((e) => Exercise.fromMap(e)).toList() ?? [],
        partName = map['partName'] ?? '';

  Map<String, dynamic> toMap() {
    return {
      'isDefaultName': defaultName,
      'setType': setTypeToIntConverter(setType),
      'bodyPart': targetedBodyPartToIntConverter(targetedBodyPart),
      'notes': additionalNotes,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'partName': partName,
    };
  }

  Part.copyFromPart(Part part)
      : defaultName = part.defaultName,
        setType = part.setType,
        targetedBodyPart = part.targetedBodyPart,
        additionalNotes = part.additionalNotes,
        exercises = part.exercises.map((ex) => Exercise.copyFromExercise(ex)).toList(),
        partName = part.partName;

  @override
  String toString() {
    return exercises.toString();
  }
}

int setTypeToIntConverter(SetType setType) {
  switch (setType) {
  case SetType.regular:
  return 0;
  case SetType.drop:
  return 1;
  case SetType.super_:
  return 2;
  case SetType.tri:
  return 3;
  case SetType.giant:
  return 4;
  case SetType.normal:
  return 5;
  default:
  throw Exception("Invalid Set Type");
  }
}

SetType intToSetTypeConverter(int i) {
  switch (i) {
  case 0:
  return SetType.regular;
  case 1:
  return SetType.drop;
  case 2:
  return SetType.super_;
  case 3:
  return SetType.tri;
  case 4:
  return SetType.giant;
  case 5:
  return SetType.normal;
  default:
  throw Exception("Invalid integer for Set Type");
  }
}

TargetedBodyPart intToTargetedBodyPartConverter(int i) {
  switch (i) {
    case 0:
      return TargetedBodyPart.abs;
    case 1:
      return TargetedBodyPart.arm;
    case 2:
      return TargetedBodyPart.back;
    case 3:
      return TargetedBodyPart.chest;
    case 4:
      return TargetedBodyPart.leg;
    case 5:
      return TargetedBodyPart.shoulder;
    case 6:
      return TargetedBodyPart.fullBody;
    case 7:
      return TargetedBodyPart.tricep;
    case 8:
      return TargetedBodyPart.bicep;
    default:
      throw Exception("Invalid integer for Targeted Body Part");
  }
}

int targetedBodyPartToIntConverter(TargetedBodyPart tb) {
  switch (tb) {
    case TargetedBodyPart.abs:
      return 0;
    case TargetedBodyPart.arm:
      return 1;
    case TargetedBodyPart.back:
      return 2;
    case TargetedBodyPart.chest:
      return 3;
    case TargetedBodyPart.leg:
      return 4;
    case TargetedBodyPart.shoulder:
      return 5;
    case TargetedBodyPart.fullBody:
      return 6;
    case TargetedBodyPart.tricep:
      return 7;
    case TargetedBodyPart.bicep:
      return 8;
    default:
      throw Exception("Invalid Targeted Body Part");
  }
}
