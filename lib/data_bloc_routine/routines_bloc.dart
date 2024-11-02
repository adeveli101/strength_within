import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:workout/models/routines.dart';
import 'RoutineRepository.dart';
import 'package:logging/logging.dart';

// ignore: unused_element
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
  const RoutinesInitial({required super.userId, required super.repository});
}

class RoutinesLoading extends RoutinesState {
  const RoutinesLoading({required super.userId, required super.repository});
}

class RoutinesLoaded extends RoutinesState {
  final List<Routines> routines;


  const RoutinesLoaded({
    required super.userId,
    required super.repository,
    required this.routines,

  });

  @override
  List<Object> get props => [userId, repository, routines];

  RoutinesLoaded copyWith({List<Routines>? routines}) {
    return RoutinesLoaded(
      routines: routines ?? this.routines,
      userId: userId,
      repository: repository,
    );
  }
}

class RoutinesError extends RoutinesState {
  final String message;

  const RoutinesError({required super.userId, required super.repository, required this.message});

  @override
  List<Object> get props => [userId, repository, message];
}

class RoutineExercisesLoaded extends RoutinesState {
  final Routines routine;
  final Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart;
  final List<Routines> routines; // Eklendi

  const RoutineExercisesLoaded({
    required super.userId,
    required super.repository,
    required this.routine,
    required this.exerciseListByBodyPart,
    this.routines = const [], // Varsayılan değer
  });

  @override
  List<Object> get props => [userId, repository, routine, exerciseListByBodyPart, routines];
}



/// BLOC/// BLOC/// BLOC/// BLOC/// BLOC
/// BLOC/// BLOC/// BLOC/// BLOC/// BLOC
/// BLOC/// BLOC/// BLOC/// BLOC/// BLOC
///
///
///
class RoutinesBloc extends Bloc<RoutinesEvent, RoutinesState> {
  final _logger = Logger('RoutinesBloc');
  final RoutineRepository repository;
  final String userId;

  RoutinesBloc({required this.repository, required this.userId})
      : super(RoutinesInitial(userId: userId, repository: repository)) {
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
      final routine = await repository.getRoutineWithUserData(userId, event.routineId);
      if (routine != null) {
        final exerciseListByBodyPart = await repository.buildExerciseListForRoutine(routine);

        emit(RoutineExercisesLoaded(
          userId: userId,
          repository: repository,
          routine: routine,
          exerciseListByBodyPart: exerciseListByBodyPart,
          routines: currentRoutines, // Mevcut rutinleri koru
        ));
      }
    } catch (e, stackTrace) {
      _logger.severe('Error loading routine exercises', e, stackTrace);
      emit(RoutinesError(
        userId: userId,
        repository: repository,
        message: 'Failed to load routine exercises',
      ));
    }
  }

  Future<void> _onFetchRoutines(
      FetchRoutines event,
      Emitter<RoutinesState> emit,
      ) async {
    emit(RoutinesLoading(userId: userId, repository: repository));

    try {
      final routines = await repository.getRoutinesWithUserData(userId);
      emit(RoutinesLoaded(
        userId: userId,
        repository: repository,
        routines: routines,
      ));
    } catch (e, stackTrace) {
      _logger.severe('Error loading routines', e, stackTrace);
      emit(RoutinesError(
        userId: userId,
        repository: repository,
        message: 'Failed to load routines',
      ));
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
