import 'package:flutter/material.dart';

import 'package:workout/models/routine.dart';

import '../models/part.dart';

enum AddOrEdit { add, edit }

String mainTargetedBodyPartToStringConverter(MainTargetedBodyPart targetedBodyPart) {
  switch (targetedBodyPart) {
    case MainTargetedBodyPart.abs:
      return 'Abs';
    case MainTargetedBodyPart.arm:
      return 'Arms';
    case MainTargetedBodyPart.back:
      return 'Back';
    case MainTargetedBodyPart.chest:
      return 'Chest';
    case MainTargetedBodyPart.leg:
      return 'Legs';
    case MainTargetedBodyPart.shoulder:
      return 'Shoulders';
    case MainTargetedBodyPart.fullBody:
      return 'Full Body';
    default:
      throw Exception('Unmatched main targetedBodyPart: $targetedBodyPart');
  }
}

Color setTypeToColorConverter(SetType setType) {
  switch (setType) {
    case SetType.regular:
      return Colors.orangeAccent;
    case SetType.drop:
      return Colors.grey;
    case SetType.super_:
      return Colors.orange;
    case SetType.tri:
      return Colors.deepOrange;
    case SetType.giant:
      return Colors.red;
    default:
      return Colors.orange;
  }
}

String targetedBodyPartToStringConverter(dynamic bodyPart) {
  if (bodyPart is MainTargetedBodyPart) {
    return bodyPart.toString().split('.').last;
  } else if (bodyPart is TargetedBodyPart) {
    return bodyPart.toString().split('.').last;
  }
  return 'Unknown';
}


String setTypeToStringConverter(SetType setType) {
  switch (setType) {
    case SetType.regular:
      return 'Regular Sets';
    case SetType.drop:
      return 'Drop Sets';
    case SetType.super_:
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
      return 1;
    case SetType.drop:
      return 1;
    case SetType.super_:
      return 2;
    case SetType.tri:
      return 3;
    case SetType.giant:
      return 4;
    default:
      throw Exception('setTypeToExerciseCountConverter(), setType is $setType');
  }
}

Widget targetedBodyPartToImageConverter(TargetedBodyPart targetedBodyPart) {
  double scale = 30;
  switch (targetedBodyPart) {
    case TargetedBodyPart.abs:
      return Image.asset(
        'assets/abs-96.png',
        scale: scale,
      );
    case TargetedBodyPart.arm:
      return Image.asset(
        'assets/muscle-96.png',
        scale: scale,
      );
    case TargetedBodyPart.back:
      return Image.asset(
        'assets/back-96.png',
        scale: scale,
      );
    case TargetedBodyPart.chest:
      return Image.asset(
        'assets/chest-96.png',
        scale: scale,
      );
    case TargetedBodyPart.leg:
      return Image.asset(
        'assets/leg-96.png',
        scale: scale,
      );
    case TargetedBodyPart.shoulder:
      return Image.asset(
        'assets/muscle-96.png',
        scale: scale,
      );
    default:
      return Image.asset(
        'assets/muscle-96.png',
        scale: scale,
      );
  }
}

int getTimestampNow() {
  return DateTime.now().millisecondsSinceEpoch;
  //return dateTimeToStringConverter(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
}

class StringHelper {
  static String weightToString(double weight) {
    if (weight - weight.truncate() != 0) {
      return weight.toStringAsFixed(1);
    } else {
      return weight.toStringAsFixed(0);
    }
  }
}
