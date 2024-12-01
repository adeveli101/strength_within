import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/BodyPart.dart';
import '../models/WorkoutType.dart';
import '../models/Parts.dart';
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
  return bodyPart.name.capitalize!;
}

String bodyPartIdToStringConverter(int bodyPartId,  bodyParts) {
  // BodyPart ID'sine göre ismi döndür
  final bodyPart = bodyParts.firstWhere((part) => part.id == bodyPartId, orElse: () => BodyParts(id: -1, name: 'Bilinmiyor'));
  return bodyPart.name.capitalize!;
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

// Kas grubu ikon dönüştürücüsü
Widget bodyPartToIconConverter(BodyParts bodyPart) {
  double scale = 30;

  // Ana kas gruplarına göre ikon seçimi
  if (bodyPart.parentBodyPartId == null) {
    switch (bodyPart.id) {
      case 1: // Göğüs
        return Image.asset('assets/chest-96.png', scale: scale);
      case 2: // Sırt
        return Image.asset('assets/back-96.png', scale: scale);
      case 3: // Bacak
        return Image.asset('assets/leg-96.png', scale: scale);
      case 4: // Omuz
      case 5: // Kol
        return Image.asset('assets/muscle-96.png', scale: scale);
      case 6: // Karın
        return Image.asset('assets/abs-96.png', scale: scale);
      default:
        return Image.asset('assets/muscle-96.png', scale: scale);
    }
  } else {
    // Alt kas grupları için parent'ın ikonunu kullan
    return bodyPartToIconConverter(BodyParts(
      id: bodyPart.parentBodyPartId!,
      name: '',
      parentBodyPartId: null,
    ));
  }
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
