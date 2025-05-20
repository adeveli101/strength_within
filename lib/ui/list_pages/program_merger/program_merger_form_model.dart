import 'package:flutter/material.dart';

class ProgramMergerFormModel extends ChangeNotifier {
  List<int> selectedDays = [];
  int? selectedGoalId;
  Map<int, List<int>> dayToExerciseIds = {}; // gün -> egzersiz id listesi
  String? routineName;

  void toggleDay(int day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
    notifyListeners();
  }

  void setGoal(int goalId) {
    selectedGoalId = goalId;
    notifyListeners();
  }

  void toggleExerciseForDay(int day, int exerciseId) {
    dayToExerciseIds.putIfAbsent(day, () => []);
    if (dayToExerciseIds[day]!.contains(exerciseId)) {
      dayToExerciseIds[day]!.remove(exerciseId);
    } else {
      dayToExerciseIds[day]!.add(exerciseId);
    }
    notifyListeners();
  }

  void setRoutineName(String name) {
    routineName = name;
    notifyListeners();
  }
} 