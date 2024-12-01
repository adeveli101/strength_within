import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import '../data_schedule_bloc/schedule_repository.dart';
import '../models/RoutinetargetedBodyParts.dart';
import '../models/routines.dart';
import 'RoutineRepository.dart';


// Events
abstract class RoutinesEvent extends Equatable {
  const RoutinesEvent();

  @override
  List<Object?> get props => [];
}

class FetchRoutines extends RoutinesEvent {}

class UpdateRoutine extends RoutinesEvent {
  final Routines updatedRoutine;
  const UpdateRoutine(this.updatedRoutine);

  @override
  List<Object?> get props => [updatedRoutine];
}

class UpdateRoutineTargetedBodyParts extends RoutinesEvent {
  final int routineId;
  final List<RoutineTargetedBodyParts> targetedBodyParts;

  const UpdateRoutineTargetedBodyParts({
    required this.routineId,
    required this.targetedBodyParts,
  });

  @override
  List<Object> get props => [routineId, targetedBodyParts];
}

class FetchRoutineTargets extends RoutinesEvent {
  final int routineId;

  const FetchRoutineTargets({required this.routineId});

  @override
  List<Object> get props => [routineId];
}

class FetchRoutineExercises extends RoutinesEvent {
  final int routineId;
  const FetchRoutineExercises({required this.routineId});

  @override
  List<Object?> get props => [routineId];
}

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
  List<Object?> get props => [userId, routineId, isFavorite];
}

class UpdateRoutineProgress extends RoutinesEvent {
  final String userId;
  final String routineId;
  final int progress;

  const UpdateRoutineProgress({
    required this.userId,
    required this.routineId,
    required this.progress,
  });

  @override
  List<Object?> get props => [userId, routineId, progress];
}

class AcceptWeeklyChallenge extends RoutinesEvent {
  final String userId;
  final int routineId;

  const AcceptWeeklyChallenge({
    required this.userId,
    required this.routineId,
  });

  @override
  List<Object?> get props => [userId, routineId];
}

// States
abstract class RoutinesState extends Equatable {
  final String userId;
  final RoutineRepository repository;

  const RoutinesState({
    required this.userId,
    required this.repository,
  });

  @override
  List<Object?> get props => [userId, repository];
}

class RoutinesInitial extends RoutinesState {
  const RoutinesInitial({
    required super.userId,
    required super.repository,
  });
}

class RoutinesLoading extends RoutinesState {
  const RoutinesLoading({
    required super.userId,
    required super.repository,
  });
}

class RoutinesLoaded extends RoutinesState {
  final List<Routines> routines;
  final Map<int, List<RoutineTargetedBodyParts>> targetedBodyParts;

  const RoutinesLoaded({
    required super.userId,
    required super.repository,
    required this.routines,
    this.targetedBodyParts = const {},
  });

  @override
  List<Object?> get props => [userId, repository, routines, targetedBodyParts];

  RoutinesLoaded copyWith({
    List<Routines>? routines,
    Map<int, List<RoutineTargetedBodyParts>>? targetedBodyParts,
  }) {
    return RoutinesLoaded(
      routines: routines ?? this.routines,
      targetedBodyParts: targetedBodyParts ?? this.targetedBodyParts,
      userId: userId,
      repository: repository,
    );
  }

  List<RoutineTargetedBodyParts> getTargetsForRoutine(int routineId) {
    return targetedBodyParts[routineId] ?? [];
  }
}

class RoutineExercisesLoaded extends RoutinesState {
  final Routines routine;
  final Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart;
  final List<Routines> routines;
  final List<RoutineTargetedBodyParts> targetedBodyParts;

  const RoutineExercisesLoaded({
    required super.userId,
    required super.repository,
    required this.routine,
    required this.exerciseListByBodyPart,
    this.routines = const [],
    this.targetedBodyParts = const [],
  });

  @override
  List<Object?> get props => [
    userId,
    repository,
    routine,
    exerciseListByBodyPart,
    routines,
    targetedBodyParts
  ];

  RoutineExercisesLoaded copyWith({
    Routines? routine,
    Map<String, List<Map<String, dynamic>>>? exerciseListByBodyPart,
    List<Routines>? routines,
    List<RoutineTargetedBodyParts>? targetedBodyParts,
  }) {
    return RoutineExercisesLoaded(
      userId: userId,
      repository: repository,
      routine: routine ?? this.routine,
      exerciseListByBodyPart: exerciseListByBodyPart ?? this.exerciseListByBodyPart,
      routines: routines ?? this.routines,
      targetedBodyParts: targetedBodyParts ?? this.targetedBodyParts,
    );
  }
}

class RoutinesError extends RoutinesState {
  final String message;

  const RoutinesError({
    required super.userId,
    required super.repository,
    required this.message,
  });

  @override
  List<Object?> get props => [userId, repository, message];
}

// Bloc
class RoutinesBloc extends Bloc<RoutinesEvent, RoutinesState> {
  final Logger _logger = Logger('RoutinesBloc');
  final RoutineRepository repository;
  final ScheduleRepository scheduleRepository;
  final String userId;

  RoutinesBloc({
    required this.repository,
    required this.scheduleRepository,
    required this.userId,
  }) : super(RoutinesInitial(userId: userId, repository: repository)) {
    on<FetchRoutines>(_onFetchRoutines);
    on<UpdateRoutine>(_onUpdateRoutine);
    on<FetchRoutineExercises>(_onFetchRoutineExercises);
    on<ToggleRoutineFavorite>(_onToggleRoutineFavorite);
    on<UpdateRoutineProgress>(_onUpdateRoutineProgress);
    on<AcceptWeeklyChallenge>(_onAcceptWeeklyChallenge);
    on<FetchRoutineTargets>(_onFetchRoutineTargets);
  }


  Future<void> _onFetchRoutineTargets(
      FetchRoutineTargets event,
      Emitter<RoutinesState> emit,
      ) async {
    if (state is RoutinesLoaded) {
      final currentState = state as RoutinesLoaded;
      try {
        final targets = await repository.getRoutineTargets(event.routineId);
        final updatedTargetedBodyParts = Map<int, List<RoutineTargetedBodyParts>>.from(
          currentState.targetedBodyParts,
        );
        updatedTargetedBodyParts[event.routineId] = targets;

        emit(currentState.copyWith(
          targetedBodyParts: updatedTargetedBodyParts,
        ));
      } catch (e) {
        _logger.severe('Error fetching routine targets', e);
      }
    }
  }

  Future<void> _onFetchRoutines(
      FetchRoutines event,
      Emitter<RoutinesState> emit,
      ) async {
    emit(RoutinesLoading(userId: userId, repository: repository));
    try {
      final routines = await repository.getRoutinesWithUserData(userId);

      // Tüm rutinler için hedef kas gruplarını al
      final Map<int, List<RoutineTargetedBodyParts>> targetedBodyParts = {};
      for (var routine in routines) {
        final targets = await repository.getRoutineTargets(routine.id);
        targetedBodyParts[routine.id] = targets;
      }

      emit(RoutinesLoaded(
        userId: userId,
        repository: repository,
        routines: routines,
        targetedBodyParts: targetedBodyParts,
      ));
    } catch (e, stackTrace) {
      _logger.severe('Error loading routines', e, stackTrace);
      emit(RoutinesError(
        userId: userId,
        repository: repository,
        message: 'Rutinler yüklenirken hata oluştu',
      ));
    }
  }


  Future<void> _onUpdateRoutine(
      UpdateRoutine event,
      Emitter<RoutinesState> emit,
      ) async {
    if (state is RoutinesLoaded) {
      final currentState = state as RoutinesLoaded;

      // Yeni hedef kas gruplarını al
      final targets = await repository.getRoutineTargets(event.updatedRoutine.id);

      // Mevcut hedef kas grupları map'ini güncelle
      final updatedTargetedBodyParts = Map<int, List<RoutineTargetedBodyParts>>.from(
        currentState.targetedBodyParts,
      );
      updatedTargetedBodyParts[event.updatedRoutine.id] = targets;

      final updatedRoutines = currentState.routines.map((routine) {
        return routine.id == event.updatedRoutine.id
            ? event.updatedRoutine
            : routine;
      }).toList();

      emit(currentState.copyWith(
        routines: updatedRoutines,
        targetedBodyParts: updatedTargetedBodyParts,
      ));
    }
  }


  Future<void> _onFetchRoutineExercises(
      FetchRoutineExercises event,
      Emitter<RoutinesState> emit,
      ) async {
    final currentState = state;
    List<Routines> currentRoutines = [];
    if (currentState is RoutinesLoaded) {
      currentRoutines = currentState.routines;
    }

    emit(RoutinesLoading(userId: userId, repository: repository));

    try {
      // Rutin ve ilişkili verileri al
      final routine = await repository.getRoutineWithUserData(userId, event.routineId);

      if (routine != null) {
        // Egzersiz listesini ve hedef kas gruplarını al
        final exerciseListByBodyPart = await repository.buildExerciseListForRoutine(routine);
        final targetedBodyParts = await repository.getRoutineTargets(event.routineId);

        emit(RoutineExercisesLoaded(
          userId: userId,
          repository: repository,
          routine: routine,
          exerciseListByBodyPart: exerciseListByBodyPart,
          routines: currentRoutines,
          targetedBodyParts: targetedBodyParts,
        ));
      }
    } catch (e, stackTrace) {
      _logger.severe('Error loading routine exercises', e, stackTrace);
      emit(RoutinesError(
        userId: userId,
        repository: repository,
        message: 'Rutin egzersizleri yüklenirken hata oluştu',
      ));
    }
  }


  Future<void> _onToggleRoutineFavorite(
      ToggleRoutineFavorite event,
      Emitter<RoutinesState> emit,
      ) async {
    if (state is RoutinesLoaded) {
      final currentState = state as RoutinesLoaded;
      final updatedRoutines = currentState.routines.map((routine) {
        if (routine.id.toString() == event.routineId) {
          return routine.copyWith(isFavorite: event.isFavorite);
        }
        return routine;
      }).toList();

      // Optimistic update
      emit(RoutinesLoaded(
        userId: currentState.userId,
        repository: currentState.repository,
        routines: updatedRoutines,
      ));

      try {
        await repository.toggleRoutineFavorite(
          userId,
          event.routineId,
          event.isFavorite,
        );
      } catch (e, stackTrace) {
        _logger.severe('Error updating routine favorite', e, stackTrace);
        // Revert to previous state
        emit(currentState);
        emit(RoutinesError(
          userId: currentState.userId,
          repository: currentState.repository,
          message: "Favori durumu güncellenirken hata oluştu",
        ));
      }
    }
  }

  Future<void> _onUpdateRoutineProgress(
      UpdateRoutineProgress event,
      Emitter<RoutinesState> emit,
      ) async {
    try {
      await repository.updateUserRoutineProgress(
        event.userId,
        event.routineId,
        event.progress,
      );

      if (state is RoutinesLoaded) {
        final currentState = state as RoutinesLoaded;
        final updatedRoutines = currentState.routines.map((routine) {
          if (routine.id.toString() == event.routineId) {
            return routine.copyWith(userProgress: event.progress);
          }
          return routine;
        }).toList();

        emit(currentState.copyWith(routines: updatedRoutines));
      }
    } catch (e, stackTrace) {
      _logger.severe('Error updating routine progress', e, stackTrace);
      emit(RoutinesError(
        userId: userId,
        repository: repository,
        message: "İlerleme güncellenirken hata oluştu",
      ));
    }
  }

  Future<void> _onAcceptWeeklyChallenge(
      AcceptWeeklyChallenge event,
      Emitter<RoutinesState> emit,
      ) async {
    try {
      await repository.acceptWeeklyChallenge(event.userId, event.routineId);
      add(FetchRoutines()); // Refresh routines after accepting challenge
    } catch (e, stackTrace) {
      _logger.severe('Error accepting weekly challenge', e, stackTrace);
      emit(RoutinesError(
        userId: userId,
        repository: repository,
        message: "Haftalık meydan okuma kabul edilirken hata oluştu",
      ));
    }
  }


  Future<String> _getWorkoutTypeName(int workoutTypeId) async {
    try {
      final workoutType = await repository.getWorkoutTypeById(workoutTypeId);
      return workoutType?.name ?? 'Bilinmeyen Antrenman Türü';
    } catch (e) {
      _logger.severe('Error getting workout type name', e);
      return 'Bilinmeyen Antrenman Türü';
    }
  }

  Future<String> _getBodyPartName(int bodyPartId) async {
    try {
      final bodyPart = await repository.getBodyPartById(bodyPartId);
      return bodyPart?.name ?? 'Bilinmeyen Kas Grubu';
    } catch (e) {
      _logger.severe('Error getting body part name', e);
      return 'Bilinmeyen Kas Grubu';
    }
  }
}

