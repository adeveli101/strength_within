import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:workout/data_bloc/RoutineRepository.dart';
import 'package:workout/models/routines.dart';
import 'package:workout/models/exercises.dart';
import 'package:workout/models/BodyPart.dart';
import 'package:workout/models/WorkoutType.dart';
import '../models/PartFocusRoutine.dart';

// Events
abstract class RoutinesEvent extends Equatable {
  const RoutinesEvent();

  @override
  List<Object> get props => [];
}

class FetchHomeData extends RoutinesEvent {
  final String userId;

  const FetchHomeData({required this.userId});

  @override
  List<Object> get props => [userId];
}

class FetchForYouData extends RoutinesEvent {
  final String userId;

  const FetchForYouData({required this.userId});

  @override
  List<Object> get props => [userId];
}

class FetchRoutines extends RoutinesEvent {}

class FetchExercises extends RoutinesEvent {}

class FetchBodyParts extends RoutinesEvent {}

class FetchWorkoutTypes extends RoutinesEvent {}

class FetchParts extends RoutinesEvent {}

class ToggleRoutineFavorite extends RoutinesEvent {
  final String userId;
  final String routineId;
  final bool isFavorite;

  const ToggleRoutineFavorite({
    required this.userId,
    required this.routineId,
    required this.isFavorite,
  });

  @override
  List<Object> get props => [userId, routineId, isFavorite];
}

// States
abstract class RoutinesState extends Equatable {
  final String userId;
  final RoutineRepository repository;

  const RoutinesState({required this.userId, required this.repository});

  @override
  List<Object> get props => [userId, repository];
}

class RoutinesInitial extends RoutinesState {
  const RoutinesInitial({required String userId, required RoutineRepository repository})
      : super(userId: userId, repository: repository);
}

class RoutinesLoading extends RoutinesState {
  const RoutinesLoading({required String userId, required RoutineRepository repository})
      : super(userId: userId, repository: repository);
}

class RoutinesLoaded extends RoutinesState {
  final List<Routines> routines;
  final List<Exercises> exercises;
  final List<BodyParts> bodyParts;
  final List<WorkoutTypes> workoutTypes;
  final List<Parts> parts;

  const RoutinesLoaded({
    required String userId,
    required RoutineRepository repository,
    required this.routines,
    required this.exercises,
    required this.bodyParts,
    required this.workoutTypes,
    required this.parts,
  }) : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, routines, exercises, bodyParts, workoutTypes, parts];
}

class RoutinesError extends RoutinesState {
  final String message;

  const RoutinesError({required String userId, required RoutineRepository repository, required this.message})
      : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, message];
}

// Bloc
class RoutinesBloc extends Bloc<RoutinesEvent, RoutinesState> {
  final RoutineRepository repository;
  final String userId;

  RoutinesBloc({required this.repository, required this.userId})
      : super(RoutinesInitial(userId: userId, repository: repository)) {
    on<FetchHomeData>(_onFetchHomeData);
    on<FetchForYouData>(_onFetchForYouData);
    on<FetchRoutines>(_onFetchRoutines);
    on<FetchExercises>(_onFetchExercises);
    on<FetchBodyParts>(_onFetchBodyParts);
    on<FetchWorkoutTypes>(_onFetchWorkoutTypes);
    on<FetchParts>(_onFetchParts);
    on<ToggleRoutineFavorite>(_onToggleRoutineFavorite);
  }

  Future<void> _onFetchHomeData(FetchHomeData event, Emitter<RoutinesState> emit) async {
    emit(RoutinesLoading(userId: userId, repository: repository));
    try {
      final routines = await repository.getRoutinesWithUserData(userId);
      final exercises = await repository.getAllExercises();
      final bodyParts = await repository.getAllBodyParts();
      final workoutTypes = await repository.getAllWorkoutTypes();
      final parts = await repository.getPartsWithUserData(userId);

      emit(RoutinesLoaded(
        userId: userId,
        repository: repository,
        routines: routines,
        exercises: exercises,
        bodyParts: bodyParts,
        workoutTypes: workoutTypes,
        parts: parts.isNotEmpty ? parts : await repository.getAllParts(),
      ));
    } catch (e, stackTrace) {
      print("Veri çekme hatası: $e");
      print("Stack trace: $stackTrace");
      emit(RoutinesError(userId: userId, repository: repository, message: e.toString()));
    }
  }

  Future<void> _onFetchForYouData(FetchForYouData event, Emitter<RoutinesState> emit) async {
    emit(RoutinesLoading(userId: userId, repository: repository));
    try {
      final routines = await repository.getRoutinesWithUserData(userId);
      final exercises = await repository.getAllExercises();
      final bodyParts = await repository.getAllBodyParts();
      final workoutTypes = await repository.getAllWorkoutTypes();
      final parts = await repository.getPartsWithUserData(userId);
      emit(RoutinesLoaded(
        userId: userId,
        repository: repository,
        routines: routines,
        exercises: exercises,
        bodyParts: bodyParts,
        workoutTypes: workoutTypes,
        parts: parts,
      ));
    } catch (e) {
      emit(RoutinesError(userId: userId, repository: repository, message: e.toString()));
    }
  }

  Future<void> _onFetchRoutines(FetchRoutines event, Emitter<RoutinesState> emit) async {
    emit(RoutinesLoading(userId: userId, repository: repository));
    try {
      final routines = await repository.getRoutinesWithUserData(userId);
      emit(RoutinesLoaded(
        userId: userId,
        repository: repository,
        routines: routines,
        exercises: [],
        bodyParts: [],
        workoutTypes: [],
        parts: [],
      ));
    } catch (e) {
      print("Rutinler yüklenirken hata oluştu: $e");
      emit(RoutinesError(userId: userId, repository: repository, message: e.toString()));
    }
  }

  Future<void> _onFetchExercises(FetchExercises event, Emitter<RoutinesState> emit) async {
    emit(RoutinesLoading(userId: userId, repository: repository));
    try {
      final exercises = await repository.getAllExercises();
      emit(RoutinesLoaded(
        userId: userId,
        repository: repository,
        routines: [],
        exercises: exercises,
        bodyParts: [],
        workoutTypes: [],
        parts: [],
      ));
    } catch (e) {
      emit(RoutinesError(userId: userId, repository: repository, message: e.toString()));
    }
  }

  Future<void> _onFetchBodyParts(FetchBodyParts event, Emitter<RoutinesState> emit) async {
    emit(RoutinesLoading(userId: userId, repository: repository));
    try {
      final bodyParts = await repository.getAllBodyParts();
      emit(RoutinesLoaded(
        userId: userId,
        repository: repository,
        routines: [],
        exercises: [],
        bodyParts: bodyParts,
        workoutTypes: [],
        parts: [],
      ));
    } catch (e) {
      emit(RoutinesError(userId: userId, repository: repository, message: e.toString()));
    }
  }

  Future<void> _onFetchWorkoutTypes(FetchWorkoutTypes event, Emitter<RoutinesState> emit) async {
    emit(RoutinesLoading(userId: userId, repository: repository));
    try {
      final workoutTypes = await repository.getAllWorkoutTypes();
      emit(RoutinesLoaded(
        userId: userId,
        repository: repository,
        routines: [],
        exercises: [],
        bodyParts: [],
        workoutTypes: workoutTypes,
        parts: [],
      ));
    } catch (e) {
      emit(RoutinesError(userId: userId, repository: repository, message: e.toString()));
    }
  }

  Future<void> _onFetchParts(FetchParts event, Emitter<RoutinesState> emit) async {
    emit(RoutinesLoading(userId: userId, repository: repository));
    try {
      final parts = await repository.getPartsWithUserData(userId);
      emit(RoutinesLoaded(
        userId: userId,
        repository: repository,
        routines: [],
        exercises: [],
        bodyParts: [],
        workoutTypes: [],
        parts: parts,
      ));
    } catch (e) {
      emit(RoutinesError(userId: userId, repository: repository, message: e.toString()));
    }
  }

  Future<void> _onToggleRoutineFavorite(ToggleRoutineFavorite event, Emitter<RoutinesState> emit) async {
    try {
      await repository.toggleRoutineFavorite(userId, event.routineId, event.isFavorite);
      add(FetchRoutines());
    } catch (e) {
      emit(RoutinesError(userId: userId, repository: repository, message: e.toString()));
    }
  }
}