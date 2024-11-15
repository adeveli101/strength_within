// ignore_for_file: use_super_parameters

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:workout/data_schedule_bloc/schedule_repository.dart';
import '../models/Parts.dart';
import '../models/part_frequency.dart';
import 'PartRepository.dart';
import 'package:logging/logging.dart';

final _logger = Logger('PartsBloc');

// Events
sealed class PartsEvent extends Equatable {
  const PartsEvent();

  @override
  List<Object?> get props => [];
}

class FetchParts extends PartsEvent {}

class FetchPartExercises extends PartsEvent {
  final int partId;
  const FetchPartExercises({required this.partId});

  @override
  List<Object?> get props => [partId];
}

class RefreshWeeklySchedule extends PartsEvent {
  final bool forceRefresh;
  const RefreshWeeklySchedule({this.forceRefresh = false});
  @override
  List<Object> get props => [forceRefresh];
}

class ClearSchedule extends PartsEvent {
  final int weekday;
  const ClearSchedule({required this.weekday});
  @override
  List<Object> get props => [weekday];
}

class FetchScheduleStatistics extends PartsEvent {
  const FetchScheduleStatistics();
  @override
  List<Object> get props => [];
}


class AssignPartToWeekday extends PartsEvent {
  final int partId;
  final int weekday;

  const AssignPartToWeekday({
    required this.partId,
    required this.weekday,
  });

  @override
  List<Object> get props => [partId, weekday];
}

class RemovePartFromWeekday extends PartsEvent {
  final int partId;
  final int weekday;

  const RemovePartFromWeekday({
    required this.partId,
    required this.weekday,
  });

  @override
  List<Object> get props => [partId, weekday];
}

class FetchWeeklySchedule extends PartsEvent {}

class FetchPartFrequency extends PartsEvent {
  final int partId;

  const FetchPartFrequency({required this.partId});

  @override
  List<Object> get props => [partId];
}

class FetchSinglePart extends PartsEvent {
  final int partId;
  const FetchSinglePart({required this.partId});

  @override
  List<Object?> get props => [partId];
}

class UpdatePart extends PartsEvent {
  final Parts updatedPart;
  const UpdatePart(this.updatedPart);

  @override
  List<Object?> get props => [updatedPart];
}


class FetchPartsByBodyPart extends PartsEvent {
  final int bodyPartId;
  const FetchPartsByBodyPart({required this.bodyPartId});

  @override
  List<Object> get props => [bodyPartId];
}

class FetchPartsByWorkoutType extends PartsEvent {
  final int workoutTypeId;
  const FetchPartsByWorkoutType({required this.workoutTypeId});

  @override
  List<Object> get props => [workoutTypeId];
}


class WeeklyScheduleLoading extends PartsState {
  const WeeklyScheduleLoading({
    required String userId,
    required PartRepository repository,
  }) : super(userId: userId, repository: repository);
}

class ScheduleUpdateSuccess extends PartsState {
  final String message;
  const ScheduleUpdateSuccess({
    required String userId,
    required PartRepository repository,
    required this.message,
  }) : super(userId: userId, repository: repository);
}

class TogglePartFavorite extends PartsEvent {
  final String userId;
  final String partId;
  final bool isFavorite;

  const TogglePartFavorite({
    required this.userId,
    required this.partId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [userId, partId, isFavorite];
}

// States
sealed class PartsState extends Equatable {
  final String userId;
  final PartRepository repository;

  const PartsState({
    required this.userId,
    required this.repository
  });

  @override
  List<Object?> get props => [userId, repository];
}

class ScheduleStatisticsLoaded extends PartsState {
  final Map<String, int> statistics;
  const ScheduleStatisticsLoaded({
    required String userId,
    required PartRepository repository,
    required this.statistics,
  }) : super(userId: userId, repository: repository);
  @override
  List<Object> get props => [userId, repository, statistics];
}

class ScheduleOperationSuccess extends PartsState {
  final String message;
  const ScheduleOperationSuccess({
    required String userId,
    required PartRepository repository,
    required this.message,
  }) : super(userId: userId, repository: repository);
  @override
  List<Object> get props => [userId, repository, message];
}


// States
class WeeklyScheduleLoaded extends PartsState {
  final Map<int, List<Parts>> schedule;

  const WeeklyScheduleLoaded({
    required String userId,
    required PartRepository repository,
    required this.schedule,
  }) : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, schedule];
}

class PartFrequencyLoaded extends PartsState {
  final PartFrequency frequency;

  const PartFrequencyLoaded({
    required String userId,
    required PartRepository repository,
    required this.frequency,
  }) : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, frequency];
}

class PartsInitial extends PartsState {
  const PartsInitial({
    required String userId,
    required PartRepository repository
  }) : super(userId: userId, repository: repository);
}

class PartsLoading extends PartsState {
  const PartsLoading({
    required String userId,
    required PartRepository repository
  }) : super(userId: userId, repository: repository);
}

class PartsLoaded extends PartsState {
  final List<Parts> parts;

  const PartsLoaded({
    required String userId,
    required PartRepository repository,
    required this.parts,
  }) : super(userId: userId, repository: repository);

  @override
  List<Object?> get props => [userId, repository, parts];

  PartsLoaded copyWith({List<Parts>? parts}) {
    return PartsLoaded(
      parts: parts ?? this.parts,
      userId: userId,
      repository: repository,
    );
  }


}

class PartExercisesLoaded extends PartsState {
  final Parts part;
  final List<Parts> parts; //
  final Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart;

  const PartExercisesLoaded({
    required String userId,
    required PartRepository repository,
    required this.part,
    required this.parts, // Bunu ekledik
    required this.exerciseListByBodyPart,
  }) : super(userId: userId, repository: repository);

  @override
  List<Object?> get props => [userId, repository, part, parts, exerciseListByBodyPart];
}


class PartsError extends PartsState {
  final String message;

  const PartsError({
    required String userId,
    required PartRepository repository,
    required this.message
  }) : super(userId: userId, repository: repository);

  @override
  List<Object?> get props => [userId, repository, message];
}

// Bloc
class PartsBloc extends Bloc<PartsEvent, PartsState> {
  final PartRepository repository;
  final String userId;

  PartsBloc({
    required this.repository,
    required this.userId, required ScheduleRepository scheduleRepository
  }) : super(PartsInitial(userId: userId, repository: repository)) {
    on<FetchParts>(_onFetchParts);
    on<FetchPartExercises>(_onFetchPartExercises);
    on<TogglePartFavorite>(_onTogglePartFavorite);
    on<UpdatePart>(_onUpdatePart);
    on<FetchPartsByBodyPart>(_onFetchPartsByBodyPart);
    on<FetchPartsByWorkoutType>(_onFetchPartsByWorkoutType);
    on<FetchPartFrequency>(_onFetchPartFrequency);

  }












  Future<void> _onFetchPartFrequency(
      FetchPartFrequency event,
      Emitter<PartsState> emit,
      ) async {
    try {
      final frequency = await repository.getPartFrequency(event.partId);
      if (frequency != null) {
        emit(PartFrequencyLoaded(
          userId: userId,
          repository: repository,
          frequency: frequency,
        ));
      } else {
        emit(PartsError(
          userId: userId,
          repository: repository,
          message: 'Part frequency not found',
        ));
      }
    } catch (e) {
      emit(PartsError(
        userId: userId,
        repository: repository,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onFetchParts(
      FetchParts event,
      Emitter<PartsState> emit
      ) async {
    emit(PartsLoading(userId: userId, repository: repository));
    try {
      _logger.info('Fetching parts for user: $userId');
      final parts = await repository.getPartsWithUserData(userId);

      if (parts.isEmpty) {
        _logger.warning('No parts found for user: $userId');
      } else {
        _logger.info('Fetched ${parts.length} parts for user: $userId');
      }

      emit(PartsLoaded(
        userId: userId,
        repository: repository,
        parts: parts,
      ));
    } catch (e, stackTrace) {
      _logger.severe('Error fetching parts for user: $userId', e, stackTrace);
      emit(PartsError(
        userId: userId,
        repository: repository,
        message: 'Failed to fetch parts: ${e.toString()}',
      ));
    }
  }


  Future<void> _onFetchPartsByBodyPart(
      FetchPartsByBodyPart event,
      Emitter<PartsState> emit,
      ) async {
    emit(PartsLoading(userId: state.userId, repository: state.repository));

    try {
      final parts = await state.repository.getPartsByBodyPart(event.bodyPartId);

      emit(PartsLoaded(
        userId: state.userId,
        repository: state.repository,
        parts: parts,
      ));

      _logger.info('Successfully fetched ${parts.length} parts for body part ${event.bodyPartId}');
    } catch (e, stackTrace) {
      _logger.severe('Error fetching parts by body part', e, stackTrace);
      emit(PartsError(
        userId: state.userId,
        repository: state.repository,
        message: 'Failed to fetch parts: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFetchPartsByWorkoutType(
      FetchPartsByWorkoutType event,
      Emitter<PartsState> emit,
      ) async {
    emit(PartsLoading(userId: state.userId, repository: state.repository));

    try {
      final parts = await state.repository.getPartsByWorkoutType(event.workoutTypeId);

      emit(PartsLoaded(
        userId: state.userId,
        repository: state.repository,
        parts: parts,
      ));

      _logger.info('Successfully fetched ${parts.length} parts for workout type ${event.workoutTypeId}');
    } catch (e, stackTrace) {
      _logger.severe('Error fetching parts by workout type', e, stackTrace);
      emit(PartsError(
        userId: state.userId,
        repository: state.repository,
        message: 'Failed to fetch parts: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFetchPartExercises(
      FetchPartExercises event,
      Emitter<PartsState> emit
      ) async {
    emit(PartsLoading(userId: state.userId, repository: state.repository));
    try {
      // Önce part'ı al
      final part = await repository.getPartById(event.partId);
      if (part == null) {
        emit(PartsError(
            userId: state.userId,
            repository: state.repository,
            message: "Part bulunamadı"
        ));
        return;
      }

      // Egzersiz listesini oluştur
      final exerciseListByBodyPart = await repository.buildExerciseListForPart(part);

      // Tüm part'ları al
      final allParts = await repository.getPartsWithUserData(state.userId);

      // State'i güncelle
      emit(PartExercisesLoaded(
        userId: state.userId,
        repository: state.repository,
        part: part,
        parts: allParts,
        exerciseListByBodyPart: exerciseListByBodyPart,
      ));

    } catch (e, stackTrace) {
      _logger.severe('Error in _onFetchPartExercises', e, stackTrace);
      emit(PartsError(
          userId: state.userId,
          repository: state.repository,
          message: e.toString()
      ));
    }
  }




  void _onUpdatePart(UpdatePart event, Emitter<PartsState> emit) {
    if (state is PartsLoaded) {
      final currentState = state as PartsLoaded;
      final updatedParts = currentState.parts.map((part) {
        return part.id == event.updatedPart.id ? event.updatedPart : part;
      }).toList();
      emit(currentState.copyWith(parts: updatedParts));
    }
  }

  Future<void> _onTogglePartFavorite(
      TogglePartFavorite event,
      Emitter<PartsState> emit,
      ) async {
    if (state is! PartsLoaded) {
      _logger.warning('TogglePartFavorite called when state is not PartsLoaded');
      return;
    }

    final currentState = state as PartsLoaded;
    final updatedParts = List<Parts>.from(currentState.parts);
    final partIndex = updatedParts.indexWhere((p) => p.id.toString() == event.partId);

    if (partIndex == -1) {
      _logger.warning('Part with id ${event.partId} not found');
      return;
    }

    try {
      // Favori durumunu güncelle
      await repository.togglePartFavorite(
          event.userId,
          event.partId,
          event.isFavorite
      );

      // Yerel state'i güncelle
      updatedParts[partIndex] = updatedParts[partIndex].copyWith(isFavorite: event.isFavorite);

      // Yeni state'i emit et
      emit(PartsLoaded(
        userId: currentState.userId,
        repository: currentState.repository,
        parts: updatedParts,
      ));

      _logger.info('Successfully updated favorite status for part: ${event.partId}');
    } catch (e) {
      _logger.severe('Error in _onTogglePartFavorite: $e');
      emit(PartsError(
        userId: currentState.userId,
        repository: currentState.repository,
        message: 'Favori durumu güncellenirken bir hata oluştu: $e',
      ));
    }
  }









}
