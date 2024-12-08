import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/BodyPart.dart';
import '../models/PartTargetedBodyParts.dart';
import '../models/WorkoutType.dart';
import '../models/Parts.dart';
final Map<int, String> _cache = {};
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
enum SetType {
  regular,  // Normal set
  drop,     // Drop set
  superSet, // Super set
  tri,      // Tri set
  giant,    // Giant set
  normal    // Normal set (legacy support)
}
// Kas grubu dönüştürücüler
String bodyPartToStringConverter(BodyParts bodyPart) {
  return GetStringUtils(bodyPart.name).capitalize!;
}

String bodyPartidToName(int bodyPartId, List<BodyParts> bodyParts) {
  if (_cache.containsKey(bodyPartId)) {
    return _cache[bodyPartId]!;
  }

  final bodyPart = bodyParts.firstWhere(
        (part) => part.id == bodyPartId,
    orElse: () => BodyParts(id: -1, name: 'Bilinmeyen'),
  );

  final capitalizedName = GetStringUtils(bodyPart.name).capitalize!;
  _cache[bodyPartId] = capitalizedName;

  return capitalizedName;
}

 void clearCache() {
_cache.clear();
}



String bodyPartIdToStringConverter(int bodyPartId, List<BodyParts> bodyParts) {
  final bodyPart = bodyParts.firstWhere(
          (part) => part.id == bodyPartId,
      orElse: () => BodyParts(id: -1, name: 'Unknown')
  );
  return GetStringUtils(bodyPart.name).capitalize!;
}

String workoutTypeToStringConverter(WorkoutTypes workoutType) {
  return workoutType.name;
}



// Set tipleri için dönüştürücüler
Color setTypeToColorConverter(SetType setType) {
  switch (setType) {
    case SetType.regular:
      return Colors.orangeAccent;
    case SetType.drop:
      return Colors.grey;
    case SetType.superSet:
      return Colors.orange;
    case SetType.tri:
      return Colors.deepOrange;
    case SetType.giant:
      return Colors.red;
    case SetType.normal:
      return Colors.orange;
    default:
      return Colors.transparent; // Varsayılan bir renk
  }
}

String setTypeToStringConverter(SetType setType) {
  switch (setType) {
    case SetType.regular:
      return 'Regular Sets';
    case SetType.drop:
      return 'Drop Sets';
    case SetType.superSet:
      return 'Supersets';
    case SetType.tri:
      return 'Tri-sets';
    case SetType.giant:
      return 'Giant sets';
    case SetType.normal:
      return 'Normal';
    default:
      return 'Bilinmiyor'; // Varsayılan bir değer
  }
}

int setTypeToExerciseCountConverter(SetType setType) {
  switch (setType) {
    case SetType.regular:
    case SetType.drop:
    case SetType.normal:
      return 1;
    case SetType.superSet:
      return 2;
    case SetType.tri:
      return 3;
    case SetType.giant:
      return 4;
    default:
      return 0; // Varsayılan bir değer
  }
}

//todo



Widget buildTargetIcon(PartTargetedBodyParts target, bool isPrimary) {
  String getBodyPartAsset(int bodyPartId) {
    switch (bodyPartId) {
      case 1: // Chest
        return 'assets/chests-modified.png';
      case 2: // Back
        return 'assets/back-modified.png';
      case 3: // Legs
        return 'assets/leg-modif.png';
      case 4: // Shoulders
        return 'assets/shoulder-modified.png';
      case 5: // Arms
        return 'assets/arm-modified.png';
      case 6: // Abs/Core
        return 'assets/core-modified.png';
      default:
        return 'assets/core-modified.png';
    }
  }

  return Image.asset(
    getBodyPartAsset(target.bodyPartId),
    width: isPrimary ? 24 : 20,
    height: isPrimary ? 24 : 20,
    color: isPrimary ? Colors.white : Colors.white70,
  );
}



  int getTimestampNow() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  class StringHelper {
  static String weightToString(double? weight) {
  if (weight == null) return '';
  if (weight - weight.truncate() != 0) {
  return weight.toStringAsFixed(1);
  } else {
  return weight.toStringAsFixed(0);
  }
  }
  }
