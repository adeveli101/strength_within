// ignore_for_file: use_super_parameters

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:strength_within/data_schedule_bloc/schedule_repository.dart';
import '../models/PartTargetedBodyParts.dart';
import '../models/Parts.dart';
import '../models/part_frequency.dart';
import '../utils/routine_helpers.dart';
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

// Hedef kas grupları için eventler
class UpdatePartTargets extends PartsEvent {
  final int partId;
  final List<Map<String, dynamic>> targetedBodyParts;

  const UpdatePartTargets({
    required this.partId,
    required this.targetedBodyParts,
  });

  @override
  List<Object> get props => [partId, targetedBodyParts];
}

class DeletePartTarget extends PartsEvent {
  final int partId;
  final int bodyPartId;

  const DeletePartTarget({
    required this.partId,
    required this.bodyPartId,
  });

  @override
  List<Object> get props => [partId, bodyPartId];
}

class FetchPartsWithTargetPercentage extends PartsEvent {
  final int bodyPartId;
  final int minPercentage;

  const FetchPartsWithTargetPercentage({
    required this.bodyPartId,
    required this.minPercentage,
  });

  @override
  List<Object> get props => [bodyPartId, minPercentage];
}

class FetchPartsGroupedByBodyPart extends PartsEvent {
  const FetchPartsGroupedByBodyPart();

  @override
  List<Object> get props => [];
}

class FetchPartTargets extends PartsEvent {
  final int partId;
  const FetchPartTargets({required this.partId});
  @override
  List<Object> get props => [partId];
}

class FetchRelatedParts extends PartsEvent {
  final int partId;
  const FetchRelatedParts({required this.partId});
  @override
  List<Object> get props => [partId];
}

class FetchPartsWithMultipleTargets extends PartsEvent {}

class FetchPartsWithExerciseCount extends PartsEvent {
  final int minCount;
  final int maxCount;
  const FetchPartsWithExerciseCount({
    required this.minCount,
    required this.maxCount
  });
  @override
  List<Object> get props => [minCount, maxCount];
}

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

class PartTargetsUpdated extends PartsState {
  final List<PartTargetedBodyParts> targets;

  const PartTargetsUpdated({
    required String userId,
    required PartRepository repository,
    required this.targets,
  }) : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, targets];
}

class PartsGroupedByBodyPart extends PartsState {
  final Map<int, List<Parts>> groupedParts;

  const PartsGroupedByBodyPart({
    required String userId,
    required PartRepository repository,
    required this.groupedParts,
  }) : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, groupedParts];
}

class PartTargetDeleted extends PartsState {
  final int partId;
  final int bodyPartId;

  const PartTargetDeleted({
    required String userId,
    required PartRepository repository,
    required this.partId,
    required this.bodyPartId,
  }) : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, partId, bodyPartId];
}

class PartsWithTargetPercentage extends PartsState {
  final List<Parts> parts;
  final int bodyPartId;
  final int percentage;

  const PartsWithTargetPercentage({
    required String userId,
    required PartRepository repository,
    required this.parts,
    required this.bodyPartId,
    required this.percentage,
  }) : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, parts, bodyPartId, percentage];
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

class PartDifficultyLoaded extends PartsState {
  final int difficulty;

  const PartDifficultyLoaded({
    required String userId,
    required PartRepository repository,
    required this.difficulty,
  }) : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, difficulty];
}


/// States// States// States// States
/// States// States// States// States
/// States// States// States// States
/// States// States// States// States
/// States// States// States// States
/// States// States// States// States

// States
sealed class PartsState extends Equatable {
  final String userId;
  final PartRepository repository;

  const PartsState({
    required this.userId,
    required this.repository
  });

  @override
  List<Object> get props => [userId, repository];
}

class PartsInitial extends PartsState {
  const PartsInitial({
    required String userId,
    required PartRepository repository,
  }) : super(userId: userId, repository: repository);
}

class PartsLoading extends PartsState {
  const PartsLoading({
    required String userId,
    required PartRepository repository,
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
  List<Object> get props => [userId, repository, parts];

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
  final List<Parts> parts;
  final Map<String, List<Map<String, dynamic>>> exerciseListByBodyPart;

  const PartExercisesLoaded({
    required String userId,
    required PartRepository repository,
    required this.part,
    required this.parts,
    required this.exerciseListByBodyPart,
  }) : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, part, parts, exerciseListByBodyPart];
}

class PartTargetsLoaded extends PartsState {
  final List<PartTargetedBodyParts> targets;

  const PartTargetsLoaded({
    required String userId,
    required PartRepository repository,
    required this.targets,
  }) : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, targets];
}

class RelatedPartsLoaded extends PartsState {
  final List<Parts> relatedParts;

  const RelatedPartsLoaded({
    required String userId,
    required PartRepository repository,
    required this.relatedParts,
  }) : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, relatedParts];
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

class PartsError extends PartsState {
  final String message;

  const PartsError({
    required String userId,
    required PartRepository repository,
    required this.message
  }) : super(userId: userId, repository: repository);

  @override
  List<Object> get props => [userId, repository, message];
}


/// Bloc// Bloc// Bloc// Bloc/// Bloc// Bloc// Bloc// Bloc
/// Bloc// Bloc// Bloc// Bloc/// Bloc// Bloc// Bloc// Bloc
/// Bloc// Bloc// Bloc// Bloc/// Bloc// Bloc// Bloc// Bloc
/// Bloc// Bloc// Bloc// Bloc/// Bloc// Bloc// Bloc// Bloc
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
    on<FetchPartTargets>(_onFetchPartTargets);
    on<FetchRelatedParts>(_onFetchRelatedParts);
    on<FetchPartsWithMultipleTargets>(_onFetchPartsWithMultipleTargets);
    on<FetchPartsWithExerciseCount>(_onFetchPartsWithExerciseCount);
    on<UpdatePartTargets>(_onUpdatePartTargets);
    on<DeletePartTarget>(_onDeletePartTarget);
    on<FetchPartsWithTargetPercentage>(_onFetchPartsWithTargetPercentage);
    on<FetchPartsGroupedByBodyPart>(_onFetchPartsGroupedByBodyPart);
  }

  Future<void> _onUpdatePartTargets(
      UpdatePartTargets event,
      Emitter<PartsState> emit,
      ) async {
    emit(PartsLoading(userId: state.userId, repository: state.repository));

    try {
      await repository.updatePartTargets(
        userId: state.userId,
        partId: event.partId,
        targetedBodyParts: event.targetedBodyParts,
      );

      final targets = await repository.getPartTargetedBodyParts(event.partId);
      emit(PartTargetsUpdated(
        userId: state.userId,
        repository: state.repository,
        targets: targets,
      ));

      _logger.info('Updated targets for part: ${event.partId}');
    } catch (e) {
      _logger.severe('Error updating part targets', e);
      emit(PartsError(
        userId: state.userId,
        repository: state.repository,
        message: 'Hedef güncellenirken hata oluştu: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeletePartTarget(
      DeletePartTarget event,
      Emitter<PartsState> emit,
      ) async {
    emit(PartsLoading(userId: state.userId, repository: state.repository));

    try {
      await repository.deletePartTarget(
        userId: state.userId,
        partId: event.partId,
        bodyPartId: event.bodyPartId,
      );

      emit(PartTargetDeleted(
        userId: state.userId,
        repository: state.repository,
        partId: event.partId,
        bodyPartId: event.bodyPartId,
      ));

      _logger.info('Deleted target body part ID: ${event.bodyPartId} from part ID: ${event.partId}');
    } catch (e) {
      _logger.severe('Error deleting part target', e);
      emit(PartsError(
        userId: state.userId,
        repository: state.repository,
        message: 'Hedef silinirken hata oluştu: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFetchPartsWithTargetPercentage(
      FetchPartsWithTargetPercentage event,
      Emitter<PartsState> emit,
      ) async {
    emit(PartsLoading(userId: state.userId, repository: state.repository));

    try {
      final parts = await repository.getPartsWithTargetPercentage(
        event.bodyPartId,
        event.minPercentage,
      );

      emit(PartsWithTargetPercentage(
        userId: state.userId,
        repository: state.repository,
        parts: parts,
        bodyPartId: event.bodyPartId,
        percentage: event.minPercentage,
      ));

      _logger.info('Fetched ${parts.length} parts with target percentage >= ${event.minPercentage}% for body part ID: ${event.bodyPartId}');
    } catch (e) {
      _logger.severe('Error fetching parts with target percentage', e);
      emit(PartsError(
        userId: state.userId,
        repository: state.repository,
        message: 'Hedef yüzdesi ile parçalar alınırken hata oluştu: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFetchPartsGroupedByBodyPart(
      FetchPartsGroupedByBodyPart event,
      Emitter<PartsState> emit,
      ) async {
    emit(PartsLoading(userId: state.userId, repository: state.repository));

    try {
      final groupedParts = await repository.getPartsGroupedByBodyPart();

      emit(PartsGroupedByBodyPart(
        userId: state.userId,
        repository: state.repository,
        groupedParts: groupedParts,
      ));

      _logger.info('Fetched parts grouped by body part successfully');
    } catch (e) {
      _logger.severe('Error fetching parts grouped by body part', e);
      emit(PartsError(
        userId: state.userId,
        repository: state.repository,
        message: 'Kas gruplarına göre parçalar alınırken hata oluştu: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFetchPartTargets(
      FetchPartTargets event,
      Emitter<PartsState> emit,
      ) async {
    emit(PartsLoading(userId: state.userId, repository: state.repository));

    try {
      final targets = await repository.getPartTargetedBodyParts(event.partId);

      if (targets.isNotEmpty) {
        emit(PartTargetsLoaded(
          userId: state.userId,
          repository: state.repository,
          targets: targets,
        ));
      } else {
        emit(PartsError(
          userId: state.userId,
          repository: state.repository,
          message: 'Parça hedefleri bulunamadı',
        ));
      }
    } catch (e) {
      emit(PartsError(
        userId: state.userId,
        repository: state.repository,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onFetchRelatedParts(
      FetchRelatedParts event,
      Emitter<PartsState> emit,
      ) async {
    emit(PartsLoading(userId: state.userId, repository: state.repository));

    try {
      final relatedParts = await repository.getRelatedParts(event.partId);

      if (relatedParts.isNotEmpty) {
        emit(RelatedPartsLoaded(
          userId: state.userId,
          repository: state.repository,
          relatedParts: relatedParts,
        ));
      } else {
        emit(PartsError(
          userId: state.userId,
          repository: state.repository,
          message: 'İlişkili parçalar bulunamadı',
        ));
      }
    } catch (e) {
      emit(PartsError(
        userId: state.userId,
        repository: state.repository,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onFetchPartsWithMultipleTargets(
      FetchPartsWithMultipleTargets event,
      Emitter<PartsState> emit,
      ) async {
    emit(PartsLoading(userId: state.userId, repository: state.repository));

    try {
      final parts = await repository.getPartsWithMultipleTargets();

      if (parts.isNotEmpty) {
        emit(PartsLoaded(
          userId: state.userId,
          repository: state.repository,
          parts: parts,
        ));
      } else {
        emit(PartsError(
          userId: state.userId,
          repository: state.repository,
          message: 'Çoklu hedeflere sahip parçalar bulunamadı',
        ));
      }
    } catch (e) {
      emit(PartsError(
        userId: state.userId,
        repository: state.repository,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onFetchPartsWithExerciseCount(
      FetchPartsWithExerciseCount event,
      Emitter<PartsState> emit,
      ) async {
    emit(PartsLoading(userId: state.userId, repository: state.repository));

    try {
      // Egzersiz sayısına göre parçaları al
      final parts = await repository.getPartsWithExerciseCount(
        event.minCount,
        event.maxCount,
      );

      // Parçaların egzersiz bilgilerini zenginleştir
      List<Parts> enrichedParts = [];
      for (var part in parts) {
        // Part'ın egzersizlerini al
        final exercises = await repository.getPartExercisesByPartId(part.id);

        // Part'ı zenginleştirilmiş bilgilerle güncelle
        enrichedParts.add(part.copyWith(
          exerciseIds: List<int>.from(exercises.map((e) => e.exerciseId)),
        ));
      }

      emit(PartsLoaded(
        userId: state.userId,
        repository: state.repository,
        parts: enrichedParts,
      ));

      _logger.info('Successfully fetched ${enrichedParts.length} parts with exercise count between ${event.minCount} and ${event.maxCount}');
    } catch (e) {
      _logger.severe('Error fetching parts with exercise count', e);
      emit(PartsError(
        userId: state.userId,
        repository: state.repository,
        message: 'Failed to fetch parts with exercise count: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFetchPartFrequency(
      FetchPartFrequency event,
      Emitter<PartsState> emit,
      ) async {
    emit(PartsLoading(userId: state.userId, repository: state.repository));

    try {
      // Parçanın sıklığını al
      final frequency = await repository.getPartFrequency(event.partId);

      if (frequency != null) {
        emit(PartFrequencyLoaded(
          userId: state.userId,
          repository: state.repository,
          frequency: frequency,
        ));
      } else {
        emit(PartsError(
          userId: state.userId,
          repository: state.repository,
          message: 'Parça sıklığı bulunamadı',
        ));
      }
    } catch (e) {
      _logger.severe('Error fetching part frequency', e);
      emit(PartsError(
        userId: state.userId,
        repository: state.repository,
        message: 'Sıklık alınırken hata oluştu: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFetchParts(
      FetchParts event,
      Emitter<PartsState> emit,
      ) async {
    emit(PartsLoading(userId: state.userId, repository: state.repository));

    try {
      final parts = await repository.getAllParts();

      emit(PartsLoaded(
        userId: state.userId,
        repository: state.repository,
        parts: parts,
      ));

      _logger.info('Successfully fetched ${parts.length} parts');
    } catch (e) {
      _logger.severe('Error fetching parts', e);
      emit(PartsError(
        userId: state.userId,
        repository: state.repository,
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
      // Tek SQL sorgusu ile tüm verileri al
      final groupedParts = await state.repository.getPartsGroupedByBodyPart();

      emit(PartsGroupedByBodyPart(
        userId: state.userId,
        repository: state.repository,
        groupedParts: groupedParts,
      ));

      _logger.info('Programlar başarıyla getirildi');
    } catch (e, stackTrace) {
      _logger.severe('Programlar getirilirken hata oluştu', e, stackTrace);
      emit(PartsError(
        userId: state.userId,
        repository: state.repository,
        message: 'Programlar yüklenemedi: ${e.toString()}',
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
      final part = await repository.getPartById(event.partId);
      if (part == null) {
        _logger.warning('Part not found with ID: ${event.partId}');
        emit(PartsError(
            userId: state.userId,
            repository: state.repository,
            message: "Part bulunamadı"
        ));
        return;
      }

      // Paralel olarak verileri al
      final results = await Future.wait([
        repository.buildExerciseListForPart(part),
        repository.getPartsWithUserData(state.userId)
      ]);

      final exerciseListByBodyPart = results[0] as Map<String, List<Map<String, dynamic>>>;
      final allParts = results[1] as List<Parts>;

      _logger.info('Fetched exercises for part: ${part.name} with ${exerciseListByBodyPart.length} body parts');

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
    try {
      if (state is PartsLoaded) {
        final currentState = state as PartsLoaded;
        final updatedParts = List<Parts>.from(currentState.parts);
        final partIndex = updatedParts.indexWhere((p) => p.id == event.updatedPart.id);

        if (partIndex != -1) {
          updatedParts[partIndex] = event.updatedPart;
          _logger.info('Updated part: ${event.updatedPart.name}');
          emit(currentState.copyWith(parts: updatedParts));
        } else {
          _logger.warning('Part not found for update: ${event.updatedPart.id}');
        }
      }
    } catch (e, stackTrace) {
      _logger.severe('Error in _onUpdatePart', e, stackTrace);
    }
  }

  Future<void> _onTogglePartFavorite(TogglePartFavorite event, Emitter<PartsState> emit) async {
    if (state is! PartsLoaded) {
      _logger.warning('Invalid state for TogglePartFavorite');
      return;
    }

    final currentState = state as PartsLoaded;
    final updatedParts = List<Parts>.from(currentState.parts);
    final partIndex = updatedParts.indexWhere((p) => p.id.toString() == event.partId);

    if (partIndex == -1) {
      _logger.warning('Part not found: ${event.partId}');
      return;
    }

    try {
      await repository.togglePartFavorite(event.userId, event.partId, event.isFavorite);

      updatedParts[partIndex] = updatedParts[partIndex].copyWith(isFavorite: event.isFavorite);

      emit(PartsLoaded(
        userId: currentState.userId,
        repository: currentState.repository,
        parts: updatedParts,
      ));

      _logger.info('Updated favorite status for part: ${event.partId}');
    } catch (e, stackTrace) {
      _logger.severe('Error in _onTogglePartFavorite', e, stackTrace);
      emit(PartsError(
        userId: currentState.userId,
        repository: currentState.repository,
        message: 'Favori durumu güncellenirken bir hata oluştu',
      ));
    }
  }









}
