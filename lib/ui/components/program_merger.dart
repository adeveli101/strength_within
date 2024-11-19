// program_merger_service.dart
import 'package:logging/logging.dart';
import '../../data_bloc_part/PartRepository.dart';
import '../../data_schedule_bloc/schedule_repository.dart';
import '../../firebase_class/user_schedule.dart';
import '../../models/PartExercises.dart';
import '../../models/Parts.dart';
import '../../models/exercises.dart';
import 'dart:math' as math;

enum MergeType {
  sequential,  // Sıralı program
  alternating, // Dönüşümlü program
  superset     // Süperset program
}

class ProgramMergerService {
  final PartRepository _partRepository;
  final ScheduleRepository _scheduleRepository;
  final Logger _logger = Logger('ProgramMergerService');

  ProgramMergerService(this._partRepository, this._scheduleRepository);

  Future<MergedProgram> createMergedProgram({
    required String userId,
    required List<int> selectedPartIds,
    required List<int> selectedDays,
    required MergeType mergeType,
  }) async {
    try {
      // 1. Veri doğrulama
      final selectedParts = await _validateAndGetParts(selectedPartIds);

      // 2. Program optimizasyonu
      final optimizedSchedule = await _optimizeSchedule(
        parts: selectedParts,
        selectedDays: selectedDays,
      );

      // 3. Egzersiz dağılımı
      final exerciseDistribution = await _distributeExercises(
        optimizedSchedule,
        selectedDays,
        mergeType,
      );

      // 4. Program oluştur
      final program = MergedProgram(
        userId: userId,
        name: _generateProgramName(selectedParts),
        description: _generateProgramDescription(selectedParts),
        schedule: optimizedSchedule,
        exercises: exerciseDistribution,
        difficulty: _calculateAverageDifficulty(selectedParts),
        mergeType: mergeType,
      );

      // 5. Firebase'e kaydet
      await _scheduleRepository.createScheduleWithExercises(program.toUserSchedule());

      return program;
    } catch (e) {
      _logger.severe('Program oluşturma hatası', e);
      throw ProgramMergerException('Program oluşturulamadı: $e');
    }
  }

  Future<List<Parts>> _validateAndGetParts(List<int> selectedPartIds) async {
    try {
      // Seçilen part'ları getir
      final List<Parts> selectedParts = [];
      for (var id in selectedPartIds) {
        final part = await _partRepository.getPartById(id);
        if (part != null) {
          selectedParts.add(part);
        }
      }

      if (selectedParts.isEmpty) {
        throw ProgramMergerException('Seçilen programlar bulunamadı');
      }

      // Kas grubu ilişkileri matrisi
      final Map<int, Map<String, dynamic>> muscleRelations = {
        1: { // Göğüs
          'synergistic': <int>[4, 5], // Omuz ve Triceps ile sinerjik
          'recommended_pairs': <int>[2], // Sırt ile ideal kombinasyon
          'max_per_day': 1,
          'min_rest_days': 2,
        },
        2: { // Sırt
          'synergistic': <int>[4, 5],
          'recommended_pairs': <int>[1],
          'max_per_day': 1,
          'min_rest_days': 2,
        },
        3: { // Bacak
          'synergistic': <int>[6],
          'recommended_pairs': <int>[],
          'max_per_day': 1,
          'min_rest_days': 3,
        },
        4: { // Omuz
          'synergistic': <int>[1, 2, 5],
          'recommended_pairs': <int>[5],
          'max_per_day': 2,
          'min_rest_days': 2,
        },
        5: { // Kol
          'synergistic': <int>[1, 2, 4],
          'recommended_pairs': <int>[4],
          'max_per_day': 2,
          'min_rest_days': 1,
        },
        6: { // Karın
          'synergistic': <int>[3],
          'recommended_pairs': <int>[1, 2, 3],
          'max_per_day': 2,
          'min_rest_days': 1,
        },
      };

      // Seçilen programların günlük limit kontrolü
      final bodyPartCount = <int, int>{};
      for (var part in selectedParts) {
        bodyPartCount[part.bodyPartId] = (bodyPartCount[part.bodyPartId] ?? 0) + 1;

        final maxPerDay = muscleRelations[part.bodyPartId]?['max_per_day'] as int? ?? 1;
        if (bodyPartCount[part.bodyPartId]! > maxPerDay) {
          throw ProgramMergerException(
              '${_getBodyPartName(part.bodyPartId)} için günlük maksimum program sayısına ulaşıldı'
          );
        }
      }

      // Program kombinasyonu kontrolleri
      for (var i = 0; i < selectedParts.length; i++) {
        for (var j = i + 1; j < selectedParts.length; j++) {
          final part1 = selectedParts[i];
          final part2 = selectedParts[j];

          final relations1 = muscleRelations[part1.bodyPartId];
          final relations2 = muscleRelations[part2.bodyPartId];

          if (relations1 != null && relations2 != null) {
            // Sinerjik kas grubu kontrolü
            final synergistic1 = relations1['synergistic'] as List<int>;
            final synergistic2 = relations2['synergistic'] as List<int>;

            if (!synergistic1.contains(part2.bodyPartId) &&
                !synergistic2.contains(part1.bodyPartId)) {
              // Önerilen kombinasyon kontrolü
              final recommended1 = relations1['recommended_pairs'] as List<int>;
              final recommended2 = relations2['recommended_pairs'] as List<int>;

              if (!recommended1.contains(part2.bodyPartId) &&
                  !recommended2.contains(part1.bodyPartId)) {
                throw ProgramMergerException(
                    '${_getBodyPartName(part1.bodyPartId)} ve ${_getBodyPartName(part2.bodyPartId)} kombinasyonu optimal değil'
                );
              }
            }
          }
        }
      }

      return selectedParts;
    } catch (e) {
      _logger.severe('Error validating parts', e);
      throw ProgramMergerException('Program parçaları doğrulanırken hata: $e');
    }
  }

  Future<Map<int, Parts>> _optimizeSchedule({
    required List<Parts> parts,
    required List<int> selectedDays,
  }) async {
    try {
      final optimizedParts = _optimizeWorkoutOrder(parts);
      final schedule = <int, Parts>{};

      for (var i = 0; i < optimizedParts.length; i++) {
        if (i < selectedDays.length) {
          schedule[selectedDays[i]] = optimizedParts[i];
        }
      }

      return schedule;
    } catch (e) {
      _logger.severe('Error optimizing schedule', e);
      throw ProgramMergerException('Program düzenlenirken hata: $e');
    }
  }

  List<Parts> _optimizeWorkoutOrder(List<Parts> parts) {
    // Kas gruplarını önceliğe göre sırala
    final priorityOrder = {
      1: 1, // Göğüs - Yüksek öncelik
      2: 1, // Sırt - Yüksek öncelik
      3: 1, // Bacak - Yüksek öncelik
      4: 2, // Omuz - Orta öncelik
      5: 2, // Kol - Orta öncelik
      6: 3, // Karın - Düşük öncelik
    };

    // Parçaları önceliğe göre sırala
    parts.sort((a, b) {
      final priorityA = priorityOrder[a.bodyPartId] ?? 999;
      final priorityB = priorityOrder[b.bodyPartId] ?? 999;
      return priorityA.compareTo(priorityB);
    });

    return parts;
  }

  Future<Map<int, List<PartExercise>>> _distributeExercises(
      Map<int, Parts> schedule,
      List<int> selectedDays,
      MergeType mergeType,
      ) async {
    try {
      switch (mergeType) {
        case MergeType.sequential:
          return _createSequentialDistribution(schedule, selectedDays);
        case MergeType.alternating:
          return _createAlternatingDistribution(schedule, selectedDays);
        case MergeType.superset:
          return _createSupersetDistribution(schedule, selectedDays);
      }
    } catch (e) {
      _logger.severe('Error distributing exercises', e);
      throw ProgramMergerException('Egzersizler dağıtılırken hata: $e');
    }
  }

  Future<Map<int, List<PartExercise>>> _createSequentialDistribution(
      Map<int, Parts> schedule,
      List<int> selectedDays,
      ) async {
    final distribution = <int, List<PartExercise>>{};
    int globalOrderIndex = 0;

    for (var day in selectedDays) {
      final part = schedule[day];
      if (part != null) {
        final exercises = await _getPartExercises(part, globalOrderIndex);
        distribution[day] = exercises;
        globalOrderIndex += exercises.length;
      }
    }

    return distribution;
  }

  Future<Map<int, List<PartExercise>>> _createAlternatingDistribution(
      Map<int, Parts> schedule,
      List<int> selectedDays,
      ) async {
    final distribution = <int, List<PartExercise>>{};
    final allExercises = <PartExercise>[];
    int globalOrderIndex = 0;

    // Tüm egzersizleri topla
    for (var part in schedule.values) {
      final exercises = await _getPartExercises(part, globalOrderIndex);
      allExercises.addAll(exercises);
      globalOrderIndex += exercises.length;
    }

    // Egzersizleri günlere dengeli dağıt
    final exercisesPerDay = (allExercises.length / selectedDays.length).ceil();

    for (var i = 0; i < selectedDays.length; i++) {
      final startIndex = i * exercisesPerDay;
      final endIndex = math.min(startIndex + exercisesPerDay, allExercises.length);
      distribution[selectedDays[i]] = allExercises.sublist(startIndex, endIndex);
    }

    return distribution;
  }

  Future<Map<int, List<PartExercise>>> _createSupersetDistribution(
      Map<int, Parts> schedule,
      List<int> selectedDays,
      ) async {
    final distribution = <int, List<PartExercise>>{};
    int globalOrderIndex = 0;

    // Zıt kas gruplarını eşleştir
    final opposingGroups = {
      1: 2, // Göğüs - Sırt
      4: 5, // Omuz - Kol
      3: 6, // Bacak - Core
    };

    for (var day in selectedDays) {
      final part = schedule[day];
      if (part != null) {
        final exercises = await _getPartExercises(part, globalOrderIndex);
        final opposingPartId = opposingGroups[part.bodyPartId];

        if (opposingPartId != null) {
          final opposingParts = schedule.values
              .where((p) => p.bodyPartId == opposingPartId)
              .toList();

          List<PartExercise> opposingExercises = [];
          int opposingIndex = globalOrderIndex + exercises.length;

          for (var opposingPart in opposingParts) {
            final exercises = await _getPartExercises(opposingPart, opposingIndex);
            opposingExercises.addAll(exercises);
            opposingIndex += exercises.length;
          }

          // Süperset için egzersizleri birleştir
          final supersetExercises = <PartExercise>[];
          for (var i = 0; i < exercises.length; i++) {
            supersetExercises.add(exercises[i]);
            if (i < opposingExercises.length) {
              supersetExercises.add(opposingExercises[i]);
            }
          }

          distribution[day] = supersetExercises;
          globalOrderIndex = opposingIndex;
        } else {
          distribution[day] = exercises;
          globalOrderIndex += exercises.length;
        }
      }
    }

    return distribution;
  }

  Future<List<PartExercise>> _getPartExercises(Parts part, int startIndex) async {
    int orderIndex = startIndex;
    return part.exerciseIds.map((exerciseId) {
      return PartExercise(
        id: orderIndex,
        partId: part.id,
        exerciseId: exerciseId,
        orderIndex: orderIndex++,
      );
    }).toList();
  }

  String _generateProgramName(List<Parts> parts) {
    final partNames = parts.map((p) => p.name).join(' + ');
    return 'Özel Program: $partNames';
  }

  String _generateProgramDescription(List<Parts> parts) {
    final bodyParts = parts.map((p) => _getBodyPartName(p.bodyPartId)).join(', ');
    return 'Bu program $bodyParts bölgelerini içeren özelleştirilmiş bir antrenman programıdır.';
  }

  String _getBodyPartName(int bodyPartId) {
    switch (bodyPartId) {
      case 1: return 'Göğüs';
      case 2: return 'Sırt';
      case 3: return 'Bacak';
      case 4: return 'Omuz';
      case 5: return 'Kol';
      case 6: return 'Karın';
      default: return 'Diğer';
    }
  }

  int _calculateAverageDifficulty(List<Parts> parts) {
    if (parts.isEmpty) return 1;
    final total = parts.fold<int>(0, (sum, part) => sum + part.difficulty);
    return (total / parts.length).round();
  }








}

class MergedProgram {
  final String userId;
  final String name;
  final String description;
  final Map<int, Parts> schedule;
  final Map<int, List<PartExercise>> exercises;
  final int difficulty;
  final MergeType mergeType;

  MergedProgram({
    required this.userId,
    required this.name,
    required this.description,
    required this.schedule,
    required this.exercises,
    required this.difficulty,
    required this.mergeType,
  });

  UserSchedule toUserSchedule() {
    final dailyExercises = <String, List<Map<String, dynamic>>>{};

    // Her gün için egzersizleri dönüştür
    exercises.forEach((day, exerciseList) {
      final part = schedule[day];

      dailyExercises['day$day'] = exerciseList.map((pe) {
        // Varsayılan değerleri belirle
        final defaultSets = part?.exerciseCount ?? 3;
        final defaultReps = _getDefaultReps(part?.bodyPartId ?? 0);
        final defaultWeight = _getDefaultWeight(part?.bodyPartId ?? 0);

        return {
          'exerciseId': pe.exerciseId,
          'partId': pe.partId,
          'orderIndex': pe.orderIndex,
          'isCompleted': false,
          'sets': defaultSets,
          'reps': defaultReps,
          'weight': defaultWeight,
          'restTime': _getRestTime(part?.bodyPartId ?? 0),
        };
      }).toList();
    });

    return UserSchedule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      itemId: schedule.values.first.id,
      type: 'merged',
      selectedDays: schedule.keys.toList(),
      startDate: DateTime.now(),
      isActive: true,
      isCustom: true,
      dailyExercises: dailyExercises,
    );
  }

  // Kas grubuna göre varsayılan tekrar sayısı
  int _getDefaultReps(int bodyPartId) {
    switch (bodyPartId) {
      case 1: // Göğüs
      case 2: // Sırt
      case 4: // Omuz
        return 12; // Orta tekrar
      case 3: // Bacak
        return 15; // Yüksek tekrar
      case 5: // Kol
        return 12; // Orta tekrar
      case 6: // Karın
        return 20; // Çok yüksek tekrar
      default:
        return 12;
    }
  }

  // Kas grubuna göre varsayılan ağırlık (kg)
  double _getDefaultWeight(int bodyPartId) {
    switch (bodyPartId) {
      case 1: // Göğüs
      case 2: // Sırt
        return 20.0; // Ağır
      case 3: // Bacak
        return 30.0; // Çok ağır
      case 4: // Omuz
      case 5: // Kol
        return 10.0; // Orta
      case 6: // Karın
        return 5.0; // Hafif
      default:
        return 10.0;
    }
  }

  // Kas grubuna göre dinlenme süresi (saniye)
  int _getRestTime(int bodyPartId) {
    switch (bodyPartId) {
      case 1: // Göğüs
      case 2: // Sırt
      case 3: // Bacak
        return 90; // Uzun dinlenme
      case 4: // Omuz
      case 5: // Kol
        return 60; // Orta dinlenme
      case 6: // Karın
        return 45; // Kısa dinlenme
      default:
        return 60;
    }
  }
}

class ProgramMergerException implements Exception {
  final String message;

  ProgramMergerException(this.message);

  @override
  String toString() => message;
}

class Constants {
  // Program limitleri
  static const int maxTotalDifficulty = 15;
  static const int maxPartsPerBodyPart = 1;
  static const int minRestDays = 1;

  // Varsayılan değerler
  static const int defaultSets = 3;
  static const int defaultReps = 12;
  static const double defaultWeight = 10.0;
  static const int defaultRestTime = 60;

  // Kas grubu öncelikleri
  static const Map<int, int> musclePriority = {
    1: 10, // Göğüs - En yüksek öncelik
    2: 10, // Sırt - En yüksek öncelik
    3: 9,  // Bacak - Yüksek öncelik
    4: 8,  // Omuz - Orta öncelik
    5: 7,  // Kol - Düşük öncelik
    6: 6,  // Karın - En düşük öncelik
  };

  // Kas grubu ilişkileri
  static const Map<int, Map<String, dynamic>> muscleRelations = {
    1: { // Göğüs
      'synergistic': [4, 5], // Omuz ve Triceps ile sinerjik
      'recommended_pairs': [2], // Sırt ile ideal kombinasyon
      'max_per_day': 1,
      'min_rest_days': 2,
    },
    2: { // Sırt
      'synergistic': [4, 5],
      'recommended_pairs': [1],
      'max_per_day': 1,
      'min_rest_days': 2,
    },
    3: { // Bacak
      'synergistic': [6],
      'recommended_pairs': [],
      'max_per_day': 1,
      'min_rest_days': 3,
    },
    4: { // Omuz
      'synergistic': [1, 2, 5],
      'recommended_pairs': [5],
      'max_per_day': 2,
      'min_rest_days': 2,
    },
    5: { // Kol
      'synergistic': [1, 2, 4],
      'recommended_pairs': [4],
      'max_per_day': 2,
      'min_rest_days': 1,
    },
    6: { // Karın
      'synergistic': [3],
      'recommended_pairs': [1, 2, 3],
      'max_per_day': 2,
      'min_rest_days': 1,
    },
  };
}

