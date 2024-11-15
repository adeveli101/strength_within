import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:workout/data_schedule_bloc/schedule_repository.dart';
import '../ai_services/ai_service_provider.dart';
import '../data_bloc_part/PartRepository.dart';
import '../data_bloc_routine/RoutineRepository.dart';
import '../models/Parts.dart';
import '../models/routines.dart';
import 'package:logging/logging.dart';

// Events
abstract class ForYouEvent extends Equatable {
  const ForYouEvent();

  @override
  List<Object?> get props => [];
}

class FetchForYouData extends ForYouEvent {
  final String userId;

  const FetchForYouData({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class AcceptWeeklyChallenge extends ForYouEvent {
  final String userId;
  final int routineId;

  const AcceptWeeklyChallenge({required this.userId, required this.routineId});

  @override
  List<Object?> get props => [userId, routineId];
}

// States
abstract class ForYouState extends Equatable {
  final String userId;

  const ForYouState({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class ForYouInitial extends ForYouState {
  const ForYouInitial({required super.userId});
}

class ForYouLoading extends ForYouState {
  const ForYouLoading({required super.userId});
}

class ForYouLoaded extends ForYouState {
  final List<Routines> recommendedRoutines;
  final List<Parts> recommendedParts;
  final Routines? weeklyChallenge;
  final bool hasAcceptedChallenge;

  const ForYouLoaded({
    required super.userId,
    required this.recommendedRoutines,
    required this.recommendedParts,
    this.weeklyChallenge,
    this.hasAcceptedChallenge = false,
  });

  @override
  List<Object?> get props => [userId, recommendedRoutines, recommendedParts, weeklyChallenge, hasAcceptedChallenge];
}

class ForYouError extends ForYouState {
  final String message;

  const ForYouError({required super.userId, required this.message});

  @override
  List<Object?> get props => [userId, message];
}

class ForYouBloc extends Bloc<ForYouEvent, ForYouState> {
  final PartRepository partRepository;
  final RoutineRepository routineRepository;
  final _logger = Logger('ForYouBloc');
  final bool isTestMode;

  ForYouBloc({
    required this.partRepository,
    required this.routineRepository,
    required String userId,
    this.isTestMode = false, required ScheduleRepository scheduleRepository,
  }) : super(ForYouInitial(userId: userId)) {
    on<FetchForYouData>(_onFetchForYouData);
    on<AcceptWeeklyChallenge>(_onAcceptWeeklyChallenge);
  }

  Future<void> _onFetchForYouData(FetchForYouData event,
      Emitter<ForYouState> emit) async {
    emit(ForYouLoading(userId: event.userId));
    try {
      if (isTestMode) {
        // Test verileri oluştur
        emit(ForYouLoaded(
          userId: event.userId,
          recommendedRoutines: _generateTestRoutines(),
          recommendedParts: _generateTestParts(),
          weeklyChallenge: _selectWeeklyChallenge(_generateTestRoutines()),
        ));
      } else {
        // Mevcut gerçek veri yükleme mantığı
        final parts = await partRepository.getPartsWithUserData(event.userId);
        final routines = await routineRepository.getRoutinesWithUserData(
            event.userId);

        emit(ForYouLoaded(
          userId: event.userId,
          recommendedRoutines: await _getRecommendedRoutines(routines),
          recommendedParts: await _getRecommendedParts(parts),
          weeklyChallenge: _selectWeeklyChallenge(routines),
        ));
      }
    } catch (e, stackTrace) {
      _logger.severe('Error fetching for you data', e, stackTrace);
      emit(ForYouError(userId: event.userId,
          message: 'Veri yükleme hatası: ${e.runtimeType} - ${e.toString()}'));
    }
  }

  List<Routines> _generateTestRoutines() {
    return List.generate(5, (index) =>
        Routines(
          id: index + 1,
          name: 'Test Routine ${index + 1}',
          description: 'This is a test routine',
          mainTargetedBodyPartId: (index % 3) + 1,
          workoutTypeId: (index % 2) + 1,
          difficulty: (index % 5) + 1,
          userProgress: (index * 20) % 100,
        ));
  }

  List<Parts> _generateTestParts() {
    return List.generate(5, (index) =>
        Parts(
          id: index + 1,
          name: 'Test Part ${index + 1}',
          bodyPartId: (index % 3) + 1,
          setType: SetType.values[index % SetType.values.length],
          exerciseIds: [1, 2, 3],
          additionalNotes: 'Test notes',
          difficulty: (index % 5) + 1,
          userProgress: (index * 20) % 100,
        ));
  }


// Önerilen rutinleri almak için güncellenmiş metodlar
  Future<List<Routines>> _getRecommendedRoutines(
      List<Routines> routines) async {
    if (routines.isEmpty) return [];

    try {
      return await AIServiceProvider.getOptimizedRoutineRecommendations(
          routines);
    } catch (e) {
      _logger.warning('AI recommendation failed, using fallback method', e);
      return _fallbackRecommendedRoutines(routines);
    }
  }

  Future<List<Parts>> _getRecommendedParts(List<Parts> parts) async {
    if (parts.isEmpty) return [];

    try {
      return await AIServiceProvider.getOptimizedPartRecommendations(parts);
    } catch (e) {
      _logger.warning('AI recommendation failed, using fallback method', e);
      return _fallbackRecommendedParts(parts);
    }
  }

  List<Routines> _fallbackRecommendedRoutines(List<Routines> routines) {
    return routines.where((r) => r.userProgress != null && r.userProgress! > 0)
        .take(5)
        .toList();
  }

  List<Parts> _fallbackRecommendedParts(List<Parts> parts) {
    return parts.where((p) =>
    p.lastUsedDate == null ||
        p.lastUsedDate!.isBefore(DateTime.now().subtract(Duration(days: 7))))
        .take(5)
        .toList();
  }

  Routines? _selectWeeklyChallenge(List<Routines> routines) {
    final challengingRoutines = routines.where((r) =>
    r.difficulty >= 4 && (r.userProgress ?? 0) < 70).toList();

    if (challengingRoutines.isEmpty) return null;

    challengingRoutines.shuffle();

    return challengingRoutines.first;
  }

  Future<void> _onAcceptWeeklyChallenge(AcceptWeeklyChallenge event,
      Emitter<ForYouState> emit) async {
    if (state is ForYouLoaded) {
      try {
        await routineRepository.acceptWeeklyChallenge(
            event.userId, event.routineId);
        final currentState = state as ForYouLoaded;
        emit(ForYouLoaded(
          userId: event.userId,
          recommendedRoutines: currentState.recommendedRoutines,
          recommendedParts: currentState.recommendedParts,
          weeklyChallenge: currentState.weeklyChallenge,
          hasAcceptedChallenge: true,
        ));
      } catch (e) {
        _logger.severe('Error accepting weekly challenge', e);
        emit(ForYouError(userId: event.userId,
            message: 'Meydan okuma kabul edilirken bir hata oluştu:${e
                .toString()}'));
      }
    }
  }
}