import 'package:flutter/material.dart';

class ProgramMergerFormModel extends ChangeNotifier {
  String? userId;
  String? routineName;
  String? routineDescription;
  int? selectedWorkoutTypeId;
  int? difficulty;
  String? selectedGoal;
  List<int>? selectedBodyParts;
  Map<int, List<int>> dayToExercises = {};
  Map<int, Map<String, dynamic>> exerciseDetails = {};
  List<Map<String, dynamic>> targetedBodyParts = [];
  List<int> selectedExercises = [];
  Set<int> trainingDays = {};
  Map<int, List<int>> selectedExercisesByMainBodyPart = {};
  List<int> selectedDays = [];
  Map<int, List<int>> dayToExerciseIds = {};
  Map<int, String> dayNames = {};

  bool get hasDayAssignments => dayToExercises.isNotEmpty;
  bool get hasExerciseDetails => exerciseDetails.isNotEmpty;
  bool get hasSelectedExercises => selectedExercises.isNotEmpty;

  void setUserId(String id) {
    userId = id;
    notifyListeners();
  }

  void setRoutineName(String? name) {
    routineName = name;
    notifyListeners();
  }

  void setRoutineDescription(String description) {
    routineDescription = description;
    notifyListeners();
  }

  void setWorkoutType(int typeId) {
    selectedWorkoutTypeId = typeId;
    notifyListeners();
  }

  void setDifficulty(int value) {
    difficulty = value;
    notifyListeners();
  }

  void setSelectedGoal(String goalId) {
    selectedGoal = goalId;
    notifyListeners();
  }

  void toggleBodyPart(int bodyPartId) {
    selectedBodyParts ??= [];
    if (selectedBodyParts!.contains(bodyPartId)) {
      selectedBodyParts!.remove(bodyPartId);
    } else {
      selectedBodyParts!.add(bodyPartId);
    }
    notifyListeners();
  }

  void toggleExercise(int exerciseId) {
    if (selectedExercises.contains(exerciseId)) {
      selectedExercises.remove(exerciseId);
    } else {
      selectedExercises.add(exerciseId);
    }
    notifyListeners();
  }

  void setSelectedExercises(List<int> exercises) {
    selectedExercises = exercises;
    notifyListeners();
  }

  void addExerciseToDay(int day, int exerciseId) {
    dayToExercises.putIfAbsent(day, () => []).add(exerciseId);
    notifyListeners();
  }

  void removeExerciseFromDay(int day, int exerciseId) {
    if (dayToExercises.containsKey(day)) {
      dayToExercises[day]?.remove(exerciseId);
      if (dayToExercises[day]?.isEmpty ?? true) {
        dayToExercises.remove(day);
      }
    }
    notifyListeners();
  }

  void setExerciseDetails(int exerciseId, Map<String, dynamic> details) {
    exerciseDetails[exerciseId] = details;
    notifyListeners();
  }

  void toggleTrainingDay(int day) {
    if (trainingDays.contains(day)) {
      trainingDays.remove(day);
    } else {
      trainingDays.add(day);
    }
    notifyListeners();
  }

  void reset() {
    userId = null;
    routineName = null;
    routineDescription = null;
    selectedWorkoutTypeId = null;
    difficulty = null;
    selectedGoal = null;
    selectedBodyParts = null;
    dayToExercises.clear();
    exerciseDetails.clear();
    targetedBodyParts.clear();
    selectedExercises.clear();
    trainingDays.clear();
    selectedExercisesByMainBodyPart.clear();
    selectedDays.clear();
    dayToExerciseIds.clear();
    dayNames.clear();
    notifyListeners();
  }

  bool validate() {
    return userId != null &&
           routineName != null &&
           selectedWorkoutTypeId != null &&
           difficulty != null &&
           selectedGoal != null &&
           selectedBodyParts != null &&
           selectedBodyParts!.isNotEmpty &&
           dayToExercises.isNotEmpty &&
           exerciseDetails.isNotEmpty;
  }

  void toggleExerciseForMainBodyPart(int mainBodyPartId, int exerciseId) {
    final list = List<int>.from(selectedExercisesByMainBodyPart[mainBodyPartId] ?? []);
    if (list.contains(exerciseId)) {
      list.remove(exerciseId);
    } else {
      list.add(exerciseId);
    }
    selectedExercisesByMainBodyPart[mainBodyPartId] = list;
    notifyListeners();
  }

  List<int> getSelectedExercisesForMainBodyPart(int mainBodyPartId) {
    return selectedExercisesByMainBodyPart[mainBodyPartId] ?? [];
  }

  void toggleDay(int day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
      dayToExerciseIds.remove(day);
      dayNames.remove(day);
    } else {
      selectedDays.add(day);
    }
    notifyListeners();
  }

  void setDayName(int day, String name) {
    dayNames[day] = name;
    notifyListeners();
  }

  void toggleExerciseForDay(int day, int exerciseId) {
    final list = List<int>.from(dayToExerciseIds[day] ?? []);
    if (list.contains(exerciseId)) {
      list.remove(exerciseId);
    } else {
      list.add(exerciseId);
    }
    dayToExerciseIds[day] = list;
    notifyListeners();
  }

  List<int> getExercisesForDay(int day) {
    return dayToExerciseIds[day] ?? [];
  }

  void clearAllDayExercises() {
    dayToExerciseIds.clear();
    notifyListeners();
  }

  void autoDistributeExercises(List<int> allExerciseIds) {
    if (selectedDays.isEmpty || allExerciseIds.isEmpty) return;
    clearAllDayExercises();
    int i = 0;
    for (final exId in allExerciseIds) {
      final day = selectedDays[i % selectedDays.length];
      dayToExerciseIds[day] = (dayToExerciseIds[day] ?? [])..add(exId);
      i++;
    }
    notifyListeners();
  }

  void setSelectedDays(List<int> days) {
    selectedDays = days;
    notifyListeners();
  }
} 