import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/BodyPart.dart';
import '../models/WorkoutType.dart';
import '../models/parts.dart';


String mainTargetedBodyPartToStringConverter(MainTargetedBodyPart? mainTargetedBodyPart) {
  return mainTargetedBodyPart!.name.capitalize!;
}

String workoutTypeToStringConverter(WorkoutType workoutType) {
  return workoutType.name;
}



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
  }
}

Widget mainTargetedBodyPartToImageConverter(MainTargetedBodyPart mainTargetedBodyPart) {
  double scale = 30;
  switch (mainTargetedBodyPart) {
    case MainTargetedBodyPart.abs:
      return Image.asset('assets/abs-96.png', scale: scale);
    case MainTargetedBodyPart.arm:
    case MainTargetedBodyPart.shoulder:
      return Image.asset('assets/muscle-96.png', scale: scale);
    case MainTargetedBodyPart.back:
      return Image.asset('assets/back-96.png', scale: scale);
    case MainTargetedBodyPart.chest:
      return Image.asset('assets/chest-96.png', scale: scale);
    case MainTargetedBodyPart.leg:
      return Image.asset('assets/leg-96.png', scale: scale);
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



