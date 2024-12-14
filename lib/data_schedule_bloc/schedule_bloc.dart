// schedule_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:strength_within/data_schedule_bloc/schedule_repository.dart';

import '../firebase_class/user_schedule.dart';


// Events
abstract class ScheduleEvent {}

class LoadUserSchedules extends ScheduleEvent {
  final String userId;
  LoadUserSchedules(this.userId);
}

class AddSchedule extends ScheduleEvent {
  final UserSchedule schedule;
  AddSchedule(this.schedule);
}

class UpdateSchedule extends ScheduleEvent {
  final UserSchedule schedule;
  UpdateSchedule(this.schedule);
}

class DeleteSchedule extends ScheduleEvent {
  final String userId;
  final String scheduleId;
  DeleteSchedule(this.userId, this.scheduleId);
}

class LoadDaySchedule extends ScheduleEvent {
  final String userId;
  final int weekday;
  LoadDaySchedule(this.userId, this.weekday);
}

// Yeni Schedule Event'leri
class UpdateDailyExercises extends ScheduleEvent {
  final String userId;
  final String scheduleId;
  final String day;
  final List<Map<String, dynamic>> exercises;

  UpdateDailyExercises({
    required this.userId,
    required this.scheduleId,
    required this.day,
    required this.exercises,
  });
}

class LoadDailyExercises extends ScheduleEvent {
  final String userId;
  final String scheduleId;
  final String day;

  LoadDailyExercises({
    required this.userId,
    required this.scheduleId,
    required this.day,
  });
}

class CreateScheduleWithExercises extends ScheduleEvent {
  final UserSchedule schedule;

  CreateScheduleWithExercises(this.schedule);
}

// States
abstract class ScheduleState {}

class ScheduleInitial extends ScheduleState {}
class ScheduleLoading extends ScheduleState {}
class ScheduleError extends ScheduleState {
  final String message;
  ScheduleError(this.message);
}

class SchedulesLoaded extends ScheduleState {
  final List<UserSchedule> schedules;
  final Map<String, dynamic>? statistics;
  SchedulesLoaded(this.schedules, {this.statistics});
}

class DayScheduleLoaded extends ScheduleState {
  final List<UserSchedule> schedules;
  final int weekday;
  DayScheduleLoaded(this.schedules, this.weekday);
}

class DailyExercisesLoaded extends ScheduleState {
  final String day;
  final List<Map<String, dynamic>> exercises;

  DailyExercisesLoaded(this.day, this.exercises);
}

class ScheduleWithExercisesCreated extends ScheduleState {
  final UserSchedule schedule;
  final Map<String, List<Map<String, dynamic>>> dailyExercises;

  ScheduleWithExercisesCreated(this.schedule, this.dailyExercises);
}

// Bloc
class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleRepository repository; // scheduleRepository yerine repository
  final String userId;
  final Logger _logger = Logger('ScheduleBloc');

  ScheduleBloc({
    required this.repository, // scheduleRepository yerine repository
    required this.userId,
  }) : super(ScheduleInitial()){
    on<LoadUserSchedules>(_onLoadUserSchedules);
    on<AddSchedule>(_onAddSchedule);
    on<UpdateSchedule>(_onUpdateSchedule);
    on<DeleteSchedule>(_onDeleteSchedule);
    on<LoadDaySchedule>(_onLoadDaySchedule);
    on<CreateScheduleWithExercises>(_onCreateScheduleWithExercises);
    on<UpdateDailyExercises>(_onUpdateDailyExercises);
    on<LoadDailyExercises>(_onLoadDailyExercises);
  }
  Future<void> _onCreateScheduleWithExercises(
      CreateScheduleWithExercises event,
      Emitter<ScheduleState> emit,
      ) async {
    try {
      emit(ScheduleLoading());
      await repository.createScheduleWithExercises(event.schedule);
      final schedules = await repository.getUserSchedules(event.schedule.userId);
      final statistics = await repository.getScheduleStatistics(event.schedule.userId);
      emit(SchedulesLoaded(schedules, statistics: statistics));
    } catch (e) {
      _logger.severe('Error creating schedule with exercises', e);
      emit(ScheduleError('Program oluşturulurken hata oluştu'));
    }
  }

  Future<void> _onUpdateDailyExercises(
      UpdateDailyExercises event,
      Emitter<ScheduleState> emit,
      ) async {
    try {
      emit(ScheduleLoading());
      await repository.updateExerciseDetails(
        userId: event.userId,
        scheduleId: event.scheduleId,
        day: event.day,
        exerciseIndex: 0, // Bu kısmı güncellemek gerekebilir
        newDetails: {'exercises': event.exercises},
      );
      emit(DailyExercisesLoaded(event.day, event.exercises));
    } catch (e) {
      _logger.severe('Error updating daily exercises', e);
      emit(ScheduleError('Günlük egzersizler güncellenirken hata oluştu'));
    }
  }

  Future<void> _onLoadDailyExercises(
      LoadDailyExercises event,
      Emitter<ScheduleState> emit,
      ) async {
    try {
      emit(ScheduleLoading());
      final exercises = await repository.getDayExercises(
        userId: event.userId,
        scheduleId: event.scheduleId,
        day: event.day,
      );
      emit(DailyExercisesLoaded(event.day, exercises));
    } catch (e) {
      _logger.severe('Error loading daily exercises', e);
      emit(ScheduleError('Günlük egzersizler yüklenirken hata oluştu'));
    }
  }


  Future<void> _onLoadUserSchedules(
      LoadUserSchedules event,
      Emitter<ScheduleState> emit,
      ) async {
    emit(ScheduleLoading());
    try {
      final schedules = await repository.getUserSchedules(event.userId);
      final statistics = await repository.getScheduleStatistics(event.userId);
      emit(SchedulesLoaded(schedules, statistics: statistics));
    } catch (e) {
      _logger.severe('Error loading schedules', e);
      emit(ScheduleError('Programlar yüklenirken hata oluştu'));
    }
  }


  Future<void> _onAddSchedule(
      AddSchedule event,
      Emitter<ScheduleState> emit,
      ) async {
    try {
      // Frequency kurallarını kontrol et
      final bool isValidFrequency = await repository.validateFrequencyRules(
        event.schedule.userId,
        event.schedule.itemId,
        event.schedule.type,
        event.schedule.selectedDays,
      );

      if (!isValidFrequency) {
        emit(ScheduleError('Seçilen günler antrenman sıklığı kurallarına uygun değil'));
        return;
      }

      await repository.addSchedule(event.schedule);
      final schedules = await repository.getUserSchedules(event.schedule.userId);
      final statistics = await repository.getScheduleStatistics(event.schedule.userId);
      emit(SchedulesLoaded(schedules, statistics: statistics));
    } catch (e) {
      _logger.severe('Error adding schedule', e);
      emit(ScheduleError('Program eklenirken hata oluştu'));
    }
  }

  Future<void> _onUpdateSchedule(
      UpdateSchedule event,
      Emitter<ScheduleState> emit,
      ) async {
    try {
      await repository.updateSchedule(event.schedule);
      final schedules = await repository.getUserSchedules(event.schedule.userId);
      final statistics = await repository.getScheduleStatistics(event.schedule.userId);
      emit(SchedulesLoaded(schedules, statistics: statistics));
    } catch (e) {
      _logger.severe('Error updating schedule', e);
      emit(ScheduleError('Program güncellenirken hata oluştu'));
    }
  }

  Future<void> _onDeleteSchedule(
      DeleteSchedule event,
      Emitter<ScheduleState> emit,
      ) async {
    try {
      await repository.deleteSchedule(event.userId, event.scheduleId);
      final schedules = await repository.getUserSchedules(event.userId);
      final statistics = await repository.getScheduleStatistics(event.userId);
      emit(SchedulesLoaded(schedules, statistics: statistics));
    } catch (e) {
      _logger.severe('Error deleting schedule', e);
      emit(ScheduleError('Program silinirken hata oluştu'));
    }
  }

  Future<void> _onLoadDaySchedule(
      LoadDaySchedule event,
      Emitter<ScheduleState> emit,
      ) async {
    emit(ScheduleLoading());
    try {
      final schedules = await repository.getSchedulesForDay(
        event.userId,
        event.weekday,
      );
      emit(DayScheduleLoaded(schedules, event.weekday));
    } catch (e) {
      _logger.severe('Error loading day schedule', e);
      emit(ScheduleError('Gün programı yüklenirken hata oluştu'));
    }
  }
}