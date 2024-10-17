import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../firebase_class/RoutineHistory.dart';
import '../firebase_class/RoutineWeekday.dart';
import '../firebase_class/firebase_routines.dart';
import '../firebase_class/users.dart';
import '../models/BodyPart.dart';
import '../models/RoutinePart.dart';
import '../models/WorkoutType.dart';
import '../models/exercises.dart';
import '../models/parts.dart';
import '../models/routines.dart';
import 'firebase_provider.dart';
import 'sql_provider.dart';

// Events
abstract class RoutinesEvent extends Equatable {
  const RoutinesEvent();

  @override
  List<Object> get props => [];
}

class FetchRoutines extends RoutinesEvent {}
class UpdateRoutine extends RoutinesEvent {
  final String userId;
  final FirebaseRoutine routine;

  const UpdateRoutine(this.userId, this.routine);

  @override
  List<Object> get props => [userId, routine];
}

// States
abstract class RoutinesState extends Equatable {
  const RoutinesState();

  @override
  List<Object> get props => [];
}

class RoutinesInitial extends RoutinesState {}
class RoutinesLoading extends RoutinesState {}
class RoutinesLoaded extends RoutinesState {
  final List<Routines> routines;

  const RoutinesLoaded(this.routines);

  @override
  List<Object> get props => [routines];
}
class RoutinesError extends RoutinesState {
  final String message;

  const RoutinesError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class RoutinesBloc extends Bloc<RoutinesEvent, RoutinesState> {
  final FirebaseProvider firebaseProvider;
  final SQLProvider sqlProvider;

  RoutinesBloc({required this.firebaseProvider, required this.sqlProvider}) : super(RoutinesInitial()) {
    on<FetchRoutines>(_onFetchRoutines);
    on<UpdateRoutine>(_onUpdateRoutine);
  }

  Future<void> _onFetchRoutines(FetchRoutines event, Emitter<RoutinesState> emit) async {
    emit(RoutinesLoading());
    try {
      final routines = await sqlProvider.getAllRoutines();
      emit(RoutinesLoaded(routines));
    } catch (e) {
      emit(RoutinesError('Failed to fetch routines: $e'));
    }
  }

  Future<void> _onUpdateRoutine(UpdateRoutine event, Emitter<RoutinesState> emit) async {
    try {
      await firebaseProvider.addOrUpdateUserRoutine(event.userId, event.routine);
      final routines = await sqlProvider.getAllRoutines();
      emit(RoutinesLoaded(routines));
    } catch (e) {
      emit(RoutinesError('Failed to update routine: $e'));
    }
  }

  /// Firebase methods  /// Firebase methods  /// Firebase methods
  /// Firebase methods  /// Firebase methods  /// Firebase methods
  ///
  Future<String?> signInAnonymously() => firebaseProvider.signInAnonymously();
  Future<String> getDeviceId() => firebaseProvider.getDeviceId();
  Future<Users?> getUser(String userId) => firebaseProvider.getUser(userId);
  Future<List<FirebaseRoutine>> getUserRoutines(String userId) => firebaseProvider.getUserRoutines(userId);
  Future<void> toggleRoutineFavorite(String userId, String routineId, bool isFavorite) =>
      firebaseProvider.toggleRoutineFavorite(userId, routineId, isFavorite);
  Future<void> deleteUserRoutine(String userId, String routineId) =>
      firebaseProvider.deleteUserRoutine(userId, routineId);
  Future<List<RoutineHistory>> getUserRoutineHistory(String userId) =>
      firebaseProvider.getUserRoutineHistory(userId);
  Future<void> addRoutineHistoryEntry(String userId, RoutineHistory historyEntry) =>
      firebaseProvider.addRoutineHistoryEntry(userId, historyEntry);
  Future<List<RoutineWeekday>> getUserRoutineWeekdays(String userId) =>
      firebaseProvider.getUserRoutineWeekdays(userId);
  Future<void> addOrUpdateRoutineWeekday(String userId, RoutineWeekday weekday) =>
      firebaseProvider.addOrUpdateRoutineWeekday(userId, weekday);
  Future<void> deleteRoutineWeekday(String userId, String weekdayId) =>
      firebaseProvider.deleteRoutineWeekday(userId, weekdayId);
  Future<void> updateUserRoutineProgress(String userId, String routineId, int progress) =>
      firebaseProvider.updateUserRoutineProgress(userId, routineId, progress);
  Future<void> updateUserRoutineLastUsedDate(String userId, String routineId) =>
      firebaseProvider.updateUserRoutineLastUsedDate(userId, routineId);
  Future<List<Exercises>> getUserCustomExercises(String userId) =>
      firebaseProvider.getUserCustomExercises(userId);
  Future<void> addOrUpdateUserCustomExercise(String userId, Exercises exercise) =>
      firebaseProvider.addOrUpdateUserCustomExercise(userId, exercise);
  Future<void> deleteUserCustomExercise(String userId, String exerciseId) =>
      firebaseProvider.deleteUserCustomExercise(userId, exerciseId);
  Future<void> updateUserRoutine(String userId, FirebaseRoutine routine) async {
    await firebaseProvider.updateUserRoutine(userId, routine);}
  Future<List<FirebaseRoutine>> getFavoriteRoutines(String userId) async  { return await firebaseProvider.getFavoriteRoutines(userId);}

  Future<String?> getUserId(String deviceId) => FirebaseProvider.getUserId(deviceId);

  String getIdFromDocument(DocumentSnapshot doc) {
    return Users.getIdFromFirestore(doc);
  }




  /// SQL methods /// SQL methods /// SQL methods
  /// SQL methods /// SQL methods /// SQL methods
  ///
  Future<List<WorkoutTypes>> getAllWorkoutTypes() => sqlProvider.getAllWorkoutTypes();
  Future<WorkoutTypes?> getWorkoutType(int id) => sqlProvider.getWorkoutType(id);
  Future<Routines?> getRoutine(int id) => sqlProvider.getRoutine(id);
  Future<List<Routines>> getRecommendedRoutines() => sqlProvider.getRecommendedRoutines();
  Future<List<Routines>> getRoutinesByWorkoutType(int workoutTypeId) =>
      sqlProvider.getRoutinesByWorkoutType(workoutTypeId);
  Future<List<Routines>> getRoutinesPaginated(int page, int pageSize) =>
      sqlProvider.getRoutinesPaginated(page, pageSize);
  Future<List<RoutineParts>> getRoutinePartsByRoutineId(int routineId) =>
      sqlProvider.getRoutinePartsByRoutineId(routineId);
  Future<List<Exercises>> getAllExercises() => sqlProvider.getAllExercises();
  Future<Exercises?> getExerciseById(int id) => sqlProvider.getExerciseById(id);
  Future<List<Exercises>> getExercisesByWorkoutType(int workoutTypeId) =>
      sqlProvider.getExercisesByWorkoutType(workoutTypeId);
  Future<List<Exercises>> searchExercisesByName(String name) => sqlProvider.searchExercisesByName(name);
  Future<List<Exercises>> getExercisesPaginated(int page, int pageSize) =>
      sqlProvider.getExercisesPaginated(page, pageSize);
  Future<List<Exercises>> getExercisesByBodyPart(MainTargetedBodyPart bodyPart) =>
      sqlProvider.getExercisesByBodyPart(bodyPart);
  Future<List<BodyParts>> getAllBodyParts() => sqlProvider.getAllBodyParts();
  Future<BodyParts?> getBodyPartById(int id) => sqlProvider.getBodyPartById(id);
  Future<List<BodyParts>> getBodyPartsByMainTargetedBodyPart(MainTargetedBodyPart mainTargetedBodyPart) =>
      sqlProvider.getBodyPartsByMainTargetedBodyPart(mainTargetedBodyPart);
  Future<List<String>> getAllBodyPartNames() => sqlProvider.getAllBodyPartNames();
  Future<Parts?> getPartById(int id) => sqlProvider.getPartById(id);
  Future<List<Parts>> getPartsByMainTargetedBodyPart(MainTargetedBodyPart bodyPart) =>
      sqlProvider.getPartsByMainTargetedBodyPart(bodyPart);
  Future<List<Parts>> getPartsBySetType(SetType setType) => sqlProvider.getPartsBySetType(setType);
  Future<List<Parts>> searchPartsByName(String query) => sqlProvider.searchPartsByName(query);
  Future<List<Parts>> getPartsPaginated(int page, int pageSize) =>
      sqlProvider.getPartsPaginated(page, pageSize);
}
