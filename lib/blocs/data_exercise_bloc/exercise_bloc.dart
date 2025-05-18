import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/sql_models/BodyPart.dart';
import '../../models/sql_models/PartExercises.dart';
import '../../models/sql_models/exercises.dart';
import '../../models/sql_models/workoutGoals.dart';
import '../data_provider/firebase_provider.dart';
import '../data_provider/sql_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';

import 'ExerciseRepository.dart';

// Event Sınıfları
abstract class ExerciseEvent {}

class FetchExercises extends ExerciseEvent {}

class FetchExercisesByPartId extends ExerciseEvent {
  final int partId;
  FetchExercisesByPartId(this.partId);
}

class SearchExercises extends ExerciseEvent {
  final String query;
  SearchExercises(this.query);
}

class FetchExercisesByWorkoutType extends ExerciseEvent {
  final int workoutTypeId;
  FetchExercisesByWorkoutType(this.workoutTypeId);
}

class ToggleExerciseFavorite extends ExerciseEvent {
  final String userId;
  final int exerciseId;
  final bool isFavorite;
  ToggleExerciseFavorite(this.userId, this.exerciseId, this.isFavorite);
}

class UpdateExerciseCompletion extends ExerciseEvent {
  final String userId;
  final int exerciseId;
  final bool isCompleted;
  UpdateExerciseCompletion(this.userId, this.exerciseId, this.isCompleted);
}

class UpdateExerciseOrder extends ExerciseEvent {
  final int partId;
  final List<PartExercise> newOrder;
  UpdateExerciseOrder(this.partId, this.newOrder);
}

class FetchBodyParts extends ExerciseEvent {}

class FetchWorkoutGoals extends ExerciseEvent {}

// State Sınıfları
abstract class ExerciseState {}

class ExerciseInitial extends ExerciseState {}

class ExerciseLoading extends ExerciseState {}

class ExerciseLoaded extends ExerciseState {
  final List<Exercises> exercises;
  final Map<int, bool> completionStatus; // Egzersiz tamamlanma durumları

  ExerciseLoaded(this.exercises, {this.completionStatus = const {}});
}

class ExerciseListByBodyPartLoaded extends ExerciseState {
  final Map<String, List<Map<String, dynamic>>> exercisesByBodyPart;
  final Map<int, bool> completionStatus;

  ExerciseListByBodyPartLoaded(this.exercisesByBodyPart, {this.completionStatus = const {}});
}

class ExerciseError extends ExerciseState {
  final String message;
  ExerciseError(this.message);
}

class BodyPartsLoaded extends ExerciseState {
  final List<BodyParts> bodyParts;
  BodyPartsLoaded(this.bodyParts);
}

class WorkoutGoalsLoaded extends ExerciseState {
  final List<WorkoutGoals> goals;
  WorkoutGoalsLoaded(this.goals);
}

// Bloc Sınıfı
class ExerciseBloc extends Bloc<ExerciseEvent, ExerciseState> {
  final ExerciseRepository exerciseRepository;
  final SQLProvider sqlProvider;
  final FirebaseProvider firebaseProvider;

  ExerciseBloc({
    required this.exerciseRepository,
    required this.sqlProvider,
    required this.firebaseProvider,
  }) : super(ExerciseInitial()) {
    on<FetchExercises>(_onFetchExercises);
    on<FetchExercisesByPartId>(_onFetchExercisesByPartId);
    on<SearchExercises>(_onSearchExercises);
    on<FetchExercisesByWorkoutType>(_onFetchExercisesByWorkoutType);
    on<UpdateExerciseCompletion>(_onUpdateExerciseCompletion);
    on<UpdateExerciseOrder>(_onUpdateExerciseOrder);
    on<FetchBodyParts>(_onFetchBodyParts);
    on<FetchWorkoutGoals>(_onFetchWorkoutGoals);
  }

  Future<void> _onFetchExercises(
      FetchExercises event,
      Emitter<ExerciseState> emit,
      ) async {
    emit(ExerciseLoading());
    try {
      final exercises = await exerciseRepository.getAllExercises();
      emit(ExerciseLoaded(exercises));
    } catch (e) {
      emit(ExerciseError("Egzersizler yüklenirken hata oluştu: $e"));
    }
  }

  Future<void> _onFetchExercisesByPartId(
      FetchExercisesByPartId event,
      Emitter<ExerciseState> emit,
      ) async {
    emit(ExerciseLoading());
    try {
      final exercises = await exerciseRepository.getExercisesByPartId(event.partId);
      emit(ExerciseLoaded(exercises));
    } catch (e) {
      emit(ExerciseError("Part ID'sine göre egzersizler yüklenirken hata: $e"));
    }
  }

  Future<void> _onSearchExercises(
      SearchExercises event,
      Emitter<ExerciseState> emit,
      ) async {
    emit(ExerciseLoading());
    try {
      final exercises = await exerciseRepository.searchExercisesByName(event.query);
      emit(ExerciseLoaded(exercises));
    } catch (e) {
      emit(ExerciseError("Egzersiz arama hatası: $e"));
    }
  }

  Future<void> _onFetchExercisesByWorkoutType(
      FetchExercisesByWorkoutType event,
      Emitter<ExerciseState> emit,
      ) async {
    emit(ExerciseLoading());
    try {
      final exercises = await exerciseRepository.getExercisesByWorkoutType(event.workoutTypeId);
      emit(ExerciseLoaded(exercises));
    } catch (e) {
      emit(ExerciseError("Antrenman tipine göre egzersizler yüklenirken hata: $e"));
    }
  }

  Future<void> _onUpdateExerciseCompletion(
      UpdateExerciseCompletion event,
      Emitter<ExerciseState> emit,
      ) async {
    try {
      await exerciseRepository.updateExerciseCompletion(
        event.userId,
        event.exerciseId,
        event.isCompleted,
      );
      // Tamamlanma durumu güncellendikten sonra mevcut durumu güncelle
      if (state is ExerciseLoaded) {
        final currentState = state as ExerciseLoaded;
        final updatedStatus = Map<int, bool>.from(currentState.completionStatus);
        updatedStatus[event.exerciseId] = event.isCompleted;
        emit(ExerciseLoaded(currentState.exercises, completionStatus: updatedStatus));
      }
    } catch (e) {
      emit(ExerciseError("Tamamlanma durumu güncellenirken hata: $e"));
    }
  }

  Future<void> _onUpdateExerciseOrder(
      UpdateExerciseOrder event,
      Emitter<ExerciseState> emit,
      ) async {
    try {
      await exerciseRepository.updateExerciseOrder(event.partId, event.newOrder);
      // Sıralama güncellendikten sonra egzersizleri yeniden yükle
      add(FetchExercisesByPartId(event.partId));
    } catch (e) {
      emit(ExerciseError("Egzersiz sıralaması güncellenirken hata: $e"));
    }
  }

  Future<void> _onFetchBodyParts(
      FetchBodyParts event,
      Emitter<ExerciseState> emit,
      ) async {
    emit(ExerciseLoading());
    try {
      final bodyParts = await exerciseRepository.getAllBodyParts();
      emit(BodyPartsLoaded(bodyParts));
    } catch (e) {
      emit(ExerciseError("Vücut bölgeleri yüklenirken hata oluştu: $e"));
    }
  }

  Future<void> _onFetchWorkoutGoals(
      FetchWorkoutGoals event,
      Emitter<ExerciseState> emit,
      ) async {
    emit(ExerciseLoading());
    try {
      final goals = await exerciseRepository.getAllWorkoutGoals();
      emit(WorkoutGoalsLoaded(goals));
    } catch (e) {
      emit(ExerciseError("Antrenman hedefleri yüklenirken hata oluştu: $e"));
    }
  }
}