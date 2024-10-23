import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:workout/models/routines.dart';
import 'RoutineRepository.dart';
import 'package:logging/logging.dart';

final _logger = Logger('RoutinesBloc');

// Events
abstract class RoutinesEvent extends Equatable {
  const RoutinesEvent();

  @override
  List<Object> get props => [];
}


class UpdateRoutine extends RoutinesEvent {

final Routines updatedRoutine;
const UpdateRoutine(this.updatedRoutine);


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

class FetchRoutineExercises extends RoutinesEvent {
  final int routineId;
  const FetchRoutineExercises({required this.routineId});

  @override
  List<Object> get props => [routineId];
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


  const RoutinesLoaded({
    required String userId,
    required RoutineRepository repository,
    required this.routines,

  }) : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, routines, ];
}

class RoutinesError extends RoutinesState {
  final String message;

  const RoutinesError({required String userId, required RoutineRepository repository, required this.message})
      : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, message];
}

class RoutineExercisesLoaded extends RoutinesState {
  final Routines routine;
  final Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart;

  const RoutineExercisesLoaded({
    required String userId,
    required RoutineRepository repository,
    required this.routine,
    required this.exerciseListByBodyPart,
  }) : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, routine, exerciseListByBodyPart];
}

// Bloc
class RoutinesBloc extends Bloc<RoutinesEvent, RoutinesState> {
  final RoutineRepository repository;
  final String userId;

  RoutinesBloc({required this.repository, required this.userId})
      : super(RoutinesInitial(userId: userId, repository: repository)) {
    on<FetchHomeData>(_onFetchHomeData);
    on<FetchRoutines>(_onFetchRoutines);
    on<FetchExercises>(_onFetchExercises);
    on<FetchBodyParts>(_onFetchBodyParts);
    on<FetchWorkoutTypes>(_onFetchWorkoutTypes);
    on<ToggleRoutineFavorite>(_onToggleRoutineFavorite);
    on<FetchRoutineExercises>(_onFetchRoutineExercises);
    on<UpdateRoutine>((event, emit) {
      if (state is RoutinesLoaded) {
        final currentState = state as RoutinesLoaded;
        final updatedRoutines = currentState.routines.map((routine) {
          return routine.id == event.updatedRoutine.id
              ? event.updatedRoutine
              : routine;
        }).toList();
        emit(RoutinesLoaded(
            routines: updatedRoutines, userId: userId, repository: repository ));
      }
    });
  }




  Future<void> _onFetchRoutineExercises(FetchRoutineExercises event, Emitter<RoutinesState> emit) async {
    emit(RoutinesLoading(userId: userId, repository: repository));
    try {
      final routine = await repository.getRoutineWithUserData(userId, event.routineId);
      if (routine != null) {
        final exerciseListByBodyPart = await repository.buildExerciseListForRoutine(routine);
        emit(RoutineExercisesLoaded(
          userId: userId,
          repository: repository,
          routine: routine,
          exerciseListByBodyPart: exerciseListByBodyPart,
        ));
      } else {
        emit(RoutinesError(userId: userId, repository: repository, message: 'Routine not found'));
      }
    } catch (e, stackTrace) {
      _logger.severe('Error loading routine exercises', e, stackTrace);
      emit(RoutinesError(userId: userId, repository: repository, message: 'Failed to load routine exercises'));
    }
  }

  Future<void> _onFetchHomeData(FetchHomeData event, Emitter<RoutinesState> emit) async {
    emit(RoutinesLoading(userId: userId, repository: repository));
    try {
      final routines = await repository.getRoutinesWithUserData(userId);

      emit(RoutinesLoaded(
        userId: userId,
        repository: repository,
        routines: routines,

      ));
    } catch (e, stackTrace) {
      _logger.severe('Error loading home data', e, stackTrace);
      emit(RoutinesError(userId: userId, repository: repository, message: 'Failed to load home data'));
    }
  }



  Future<void> _onFetchRoutines(FetchRoutines event, Emitter<RoutinesState> emit) async {
    if (isClosed) return;
    emit(RoutinesLoading(userId: userId, repository: repository));
    try {
      final routines = await repository.getRoutinesWithUserData(userId);

      if (isClosed) return;
      emit(RoutinesLoaded(
        userId: userId,
        repository: repository,
        routines: routines,


      ));
    } catch (e, stackTrace) {
      _logger.severe('Error loading routines', e, stackTrace);
      if (isClosed) return;
      emit(RoutinesError(userId: userId, repository: repository, message: 'Failed to load routines'));
    }
  }

  Future<void> _onFetchExercises(FetchExercises event, Emitter<RoutinesState> emit) async {
    emit(RoutinesLoading(userId: userId, repository: repository));
    try {
      emit(RoutinesLoaded(
        userId: userId,
        repository: repository,
        routines: [],


      ));
    } catch (e, stackTrace) {
      _logger.severe('Error loading exercises', e, stackTrace);
      emit(RoutinesError(userId: userId, repository: repository, message: 'Failed to load exercises'));
    }
  }

  Future<void> _onFetchBodyParts(FetchBodyParts event, Emitter<RoutinesState> emit) async {
    emit(RoutinesLoading(userId: userId, repository: repository));
    try {
      emit(RoutinesLoaded(
        userId: userId,
        repository: repository,
        routines: [],

      ));
    } catch (e, stackTrace) {
      _logger.severe('Error loading body parts', e, stackTrace);
      emit(RoutinesError(userId: userId, repository: repository, message: 'Failed to load body parts'));
    }
  }

  Future<void> _onFetchWorkoutTypes(FetchWorkoutTypes event, Emitter<RoutinesState> emit) async {
    emit(RoutinesLoading(userId: userId, repository: repository));
    try {

      emit(RoutinesLoaded(
        userId: userId,
        repository: repository,
        routines: [],


      ));
    } catch (e, stackTrace) {
      _logger.severe('Error loading workout types', e, stackTrace);
      emit(RoutinesError(userId: userId, repository: repository, message: 'Failed to load workout types'));
    }
  }
  Future<void> _onToggleRoutineFavorite(ToggleRoutineFavorite event, Emitter<RoutinesState> emit) async {
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
        await repository.toggleRoutineFavorite(userId, event.routineId, event.isFavorite);
        _logger.info('Routine favorite updated');
        // Database update successful, no need to do anything else
      } catch (e, stackTrace) {
        _logger.severe('Error updating routine favorite', e, stackTrace);
        // Revert to the old state in case of error
        emit(currentState);
        emit(RoutinesError(
          userId: currentState.userId,
          repository: currentState.repository,
          message: "Favori durumu güncellenirken bir hata oluştu. Lütfen tekrar deneyin.",
        ));
      }
    }
  }

}
