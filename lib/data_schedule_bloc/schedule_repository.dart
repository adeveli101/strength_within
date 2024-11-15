import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:workout/models/RoutineExercises.dart';

import '../data_provider/firebase_provider.dart';
import '../data_provider/sql_provider.dart';
import '../firebase_class/user_schedule.dart';
import '../models/PartExercises.dart';

class ScheduleException implements Exception {
  final String message;
  ScheduleException(this.message);
  @override
  String toString() => message;
}

class ScheduleRepository {
  final FirebaseProvider _firebaseProvider;
  final SQLProvider _sqlProvider;
  final Logger _logger = Logger('ScheduleRepository');

  // Cache mekanizması
  final Map<String, Map<String, dynamic>> _scheduleCache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);
  DateTime? _lastCacheTime;

  ScheduleRepository(this._firebaseProvider, this._sqlProvider);

  // MARK: - Temel Program İşlemleri
  Future<void> addSchedule(UserSchedule schedule) async {
    try {
      await _firebaseProvider.addUserSchedule(schedule);
      _clearCache(schedule.userId);
      _logger.info('Schedule added successfully: ${schedule.id}');
    } catch (e) {
      _logger.severe('Error adding schedule', e);
      throw ScheduleException('Program eklenirken hata oluştu: $e');
    }
  }

  Future<void> updateSchedule(UserSchedule schedule) async {
    try {
      await _firebaseProvider.updateUserSchedule(schedule);
      _clearCache(schedule.userId);
      _logger.info('Schedule updated successfully: ${schedule.id}');
    } catch (e) {
      _logger.severe('Error updating schedule', e);
      throw ScheduleException('Program güncellenirken hata oluştu: $e');
    }
  }

  Future<void> deleteSchedule(String userId, String scheduleId) async {
    try {
      await _firebaseProvider.deleteUserSchedule(userId, scheduleId);
      _clearCache(userId);
      _logger.info('Schedule deleted successfully: $scheduleId');
    } catch (e) {
      _logger.severe('Error deleting schedule', e);
      throw ScheduleException('Program silinirken hata oluştu: $e');
    }
  }

  // MARK: - Program Sorgulama
  Future<List<UserSchedule>> getUserSchedules(String userId) async {
    try {
      if (_isCacheValid(userId)) {
        return _scheduleCache[userId]!['schedules'] as List<UserSchedule>;
      }
      final schedules = await _firebaseProvider.getUserSchedules(userId);
      _updateCache(userId, {'schedules': schedules});
      return schedules;
    } catch (e) {
      _logger.severe('Error getting user schedules', e);
      throw ScheduleException('Programlar yüklenirken hata oluştu: $e');
    }
  }

  Future<UserSchedule?> getScheduleById(String userId, String scheduleId) async {
    try {
      return await _firebaseProvider.getUserScheduleById(userId, scheduleId);
    } catch (e) {
      _logger.severe('Error getting schedule by id', e);
      throw ScheduleException('Program bulunamadı: $e');
    }
  }

  // MARK: - Gün Bazlı İşlemler
  Future<List<UserSchedule>> getSchedulesForDay(String userId, int weekday) async {
    try {
      if (!_isValidWeekday(weekday)) {
        throw ScheduleException('Geçersiz gün: $weekday');
      }
      final schedules = await getUserSchedules(userId);
      return schedules.where((s) => s.selectedDays.contains(weekday)).toList();
    } catch (e) {
      _logger.severe('Error getting schedules for day', e);
      throw ScheduleException('Gün programları yüklenirken hata oluştu: $e');
    }
  }

  Future<void> clearDaySchedule(String userId, int weekday) async {
    try {
      if (!_isValidWeekday(weekday)) {
        throw ScheduleException('Geçersiz gün: $weekday');
      }
      final schedules = await getSchedulesForDay(userId, weekday);
      for (var schedule in schedules) {
        var updatedDays = List<int>.from(schedule.selectedDays)..remove(weekday);
        await updateSchedule(schedule.copyWith(selectedDays: updatedDays));
      }
      _clearCache(userId);
    } catch (e) {
      _logger.severe('Error clearing day schedule', e);
      throw ScheduleException('Gün programı temizlenirken hata oluştu: $e');
    }
  }

  // MARK: - Çakışma Kontrolleri
  Future<bool> hasScheduleConflict(String userId, int weekday, String type) async {
    try {
      final daySchedules = await getSchedulesForDay(userId, weekday);
      final typeCount = daySchedules.where((s) => s.type == type).length;
      return type == 'part' ? typeCount >= 3 : typeCount >= 1;
    } catch (e) {
      _logger.severe('Error checking schedule conflict', e);
      return true;
    }
  }

  // MARK: - İstatistikler
  Future<Map<String, dynamic>> getScheduleStatistics(String userId) async {
    try {
      final schedules = await getUserSchedules(userId);
      final Map<int, int> dayCount = {};
      int totalAssignments = 0;

      for (var schedule in schedules) {
        for (var day in schedule.selectedDays) {
          dayCount[day] = (dayCount[day] ?? 0) + 1;
          totalAssignments++;
        }
      }

      return {
        'totalAssignments': totalAssignments,
        'daysScheduled': dayCount.length,
        'averagePerDay': dayCount.isEmpty ? 0 :
        (totalAssignments / dayCount.length).round(),
        'dayDistribution': dayCount,
      };
    } catch (e) {
      _logger.severe('Error getting schedule statistics', e);
      return {
        'totalAssignments': 0,
        'daysScheduled': 0,
        'averagePerDay': 0,
        'dayDistribution': {},
      };
    }
  }

  // MARK: - Cache Yönetimi
  bool _isCacheValid(String userId) {
    return _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheDuration &&
        _scheduleCache.containsKey(userId);
  }

  void _updateCache(String userId, Map<String, dynamic> data) {
    _scheduleCache[userId] = data;
    _lastCacheTime = DateTime.now();
  }

  void _clearCache(String userId) {
    _scheduleCache.remove(userId);
    _lastCacheTime = null;
  }

  // MARK: - Yardımcı Metodlar
  bool _isValidWeekday(int weekday) => weekday >= 1 && weekday <= 7;

  Future<void> validateScheduleRequest(
      String userId,
      String scheduleId,
      int weekday,
      String type,
      ) async {
    if (!_isValidWeekday(weekday)) {
      throw ScheduleException('Geçersiz gün: $weekday');
    }

    if (await hasScheduleConflict(userId, weekday, type)) {
      throw ScheduleException('Bu güne daha fazla program eklenemez');
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _buildDailyExercises(
      int itemId,
      String type,
      ) async {
    try {
      final exerciseList = type == 'part'
          ? await _sqlProvider.getPartExercisesByPartId(itemId)
          : await _sqlProvider.getRoutineExercisesByRoutineId(itemId);

      // orderIndex'e göre sırala
      if (type == 'part') {
        (exerciseList as List<PartExercise>).sort((a, b) =>
            a.orderIndex.compareTo(b.orderIndex));
      } else {
        (exerciseList as List<RoutineExercises>).sort((a, b) =>
            a.orderIndex.compareTo(b.orderIndex));
      }

      Map<String, List<Map<String, dynamic>>> dailyExercises = {};
      int exercisesPerDay = (exerciseList.length / 3).ceil();

      for (int day = 1; day <= 3; day++) {
        int startIndex = (day - 1) * exercisesPerDay;
        int endIndex = startIndex + exercisesPerDay;

        if (endIndex > exerciseList.length) {
          endIndex = exerciseList.length;
        }

        List<Map<String, dynamic>> dayExercises = [];
        for (var exercise in exerciseList.sublist(startIndex, endIndex)) {
          final exerciseDetails = await _sqlProvider.getExerciseById(
              type == 'part'
                  ? (exercise as PartExercise).exerciseId
                  : (exercise as RoutineExercises).exerciseId
          );

          if (exerciseDetails != null) {
            dayExercises.add({
              'exerciseId': exerciseDetails.id,
              'name': exerciseDetails.name,
              'sets': exerciseDetails.defaultSets,
              'reps': exerciseDetails.defaultReps,
              'weight': exerciseDetails.defaultWeight,
              'orderIndex': type == 'part'
                  ? (exercise as PartExercise).orderIndex
                  : (exercise as RoutineExercises).orderIndex,
              'type': type
            });
          }
        }

        dailyExercises['day$day'] = dayExercises;
      }

      return dailyExercises;
    } catch (e) {
      _logger.severe('Error building daily exercises', e);
      throw ScheduleException('Günlük egzersizler oluşturulurken hata: $e');
    }
  }// Egzersiz detaylarını güncelleme





  Future<void> updateExerciseDetails({
    required String userId,
    required String scheduleId,
    required String day,
    required int exerciseIndex,
    required Map<String, dynamic> newDetails,
  }) async {
    try {
      await _firebaseProvider.updateExerciseDetails(
        userId: userId,
        scheduleId: scheduleId,
        day: day,
        exerciseIndex: exerciseIndex,
        newDetails: newDetails,
      );
      _clearCache(userId);
      _logger.info('Exercise details updated successfully');
    } catch (e) {
      _logger.severe('Error updating exercise details', e);
      throw ScheduleException('Egzersiz detayları güncellenirken hata: $e');
    }
  }

// Schedule oluştururken egzersizleri de ekle
  Future<void> createScheduleWithExercises(UserSchedule schedule) async {
    try {
      final dailyExercises = await _buildDailyExercises(
        schedule.itemId,
        schedule.type,
      );

      await _firebaseProvider.createScheduleWithExercises(
        userId: schedule.userId,
        schedule: schedule,
        dailyExercises: dailyExercises,
      );

      _clearCache(schedule.userId);
      _logger.info('Schedule added with exercises: ${schedule.id}');
    } catch (e) {
      _logger.severe('Error adding schedule with exercises', e);
      throw ScheduleException('Program eklenirken hata oluştu: $e');
    }
  }

// Günlük egzersizleri getir
  Future<List<Map<String, dynamic>>> getDayExercises({
    required String userId,
    required String scheduleId,
    required String day,
  }) async {
    try {
      return await _firebaseProvider.getDayExercises(
        userId: userId,
        scheduleId: scheduleId,
        day: day,
      );
    } catch (e) {
      _logger.severe('Error getting day exercises', e);
      throw ScheduleException('Gün egzersizleri yüklenirken hata: $e');
    }
  }

}