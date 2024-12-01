// program_merger_service.dart
import 'dart:math';

import 'package:logging/logging.dart';
import '../../data_bloc_part/PartRepository.dart';
import '../../data_schedule_bloc/schedule_repository.dart';
import '../../firebase_class/user_schedule.dart';
import '../../models/PartExercises.dart';
import '../../models/PartTargetedBodyParts.dart';
import '../../models/Parts.dart';
import '../../models/exercises.dart';
import 'dart:math' as math;

import '../../models/part_frequency.dart';

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
        mergeType: mergeType, partRepository: _partRepository,
      );

      // 5. Firebase'e kaydet
      await _scheduleRepository.createScheduleWithExercises(await program.toUserSchedule());

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
      final Map<int, PartFrequency> partFrequencies = {};

      for (var id in selectedPartIds) {
        final part = await _partRepository.getPartById(id);
        if (part != null) {
          selectedParts.add(part);
          // Part'ın frekans bilgisini al
          final frequency = await _partRepository.getPartFrequency(id);
          if (frequency != null) {
            partFrequencies[id] = frequency;
          }
        }
      }

      if (selectedParts.isEmpty) {
        throw ProgramMergerException('Seçilen programlar bulunamadı');
      }

      // Kas grubu yük kontrolü
      final Map<int, double> bodyPartLoads = {};
      for (var part in selectedParts) {
        final targets = await _partRepository.getPartTargetedBodyParts(part.id);

        for (var target in targets) {
          final parentBodyPart = await _getParentBodyPart(target.bodyPartId);
          final load = target.isPrimary ? 1.0 : (target.targetPercentage / 100) * 0.5;
          bodyPartLoads[parentBodyPart] = (bodyPartLoads[parentBodyPart] ?? 0) + load;
        }
      }

      // Aşırı yüklenme kontrolü
      for (var load in bodyPartLoads.entries) {
        if (load.value > 2.0) {
          final bodyPartName = await _partRepository.getBodyPartName(load.key);
          throw ProgramMergerException(
              '$bodyPartName için günlük maksimum yük sınırı aşıldı'
          );
        }
      }

      // Dinlenme günü kontrolü
      for (var i = 0; i < selectedParts.length; i++) {
        for (var j = i + 1; j < selectedParts.length; j++) {
          final part1 = selectedParts[i];
          final part2 = selectedParts[j];

          final freq1 = partFrequencies[part1.id];
          final freq2 = partFrequencies[part2.id];

          if (freq1 != null && freq2 != null) {
            final targets1 = await _partRepository.getPartTargetedBodyParts(part1.id);
            final targets2 = await _partRepository.getPartTargetedBodyParts(part2.id);

            for (var target1 in targets1) {
              for (var target2 in targets2) {
                if (await _isSameParentBodyPart(target1.bodyPartId, target2.bodyPartId)) {
                  final maxRestDays = max(freq1.minRestDays, freq2.minRestDays);
                  if (maxRestDays > 0) {
                    throw ProgramMergerException(
                        'Bu programlar arasında en az $maxRestDays gün dinlenme olmalı'
                    );
                  }
                }
              }
            }
          }
        }
      }

      // Frekans kontrolü
      final Map<int, int> weeklyFrequencyByBodyPart = {};
      for (var part in selectedParts) {
        final targets = await _partRepository.getPartTargetedBodyParts(part.id);
        final frequency = partFrequencies[part.id];

        if (frequency != null) {
          for (var target in targets) {
            final parentBodyPart = await _getParentBodyPart(target.bodyPartId);
            weeklyFrequencyByBodyPart[parentBodyPart] =
                (weeklyFrequencyByBodyPart[parentBodyPart] ?? 0) + frequency.recommendedFrequency;
          }
        }
      }

      // Haftalık frekans limiti kontrolü
      for (var freq in weeklyFrequencyByBodyPart.entries) {
        if (freq.value > 4) { // Maksimum haftalık frekans
          final bodyPartName = await _partRepository.getBodyPartName(freq.key);
          throw ProgramMergerException(
              '$bodyPartName için haftalık maksimum antrenman sayısı aşıldı'
          );
        }
      }

      return selectedParts;
    } catch (e) {
      _logger.severe('Error validating parts', e);
      throw ProgramMergerException('Program parçaları doğrulanırken hata: $e');
    }
  }

  Future<int> _getParentBodyPart(int bodyPartId) async {

    return await _partRepository.getBodyPartById(bodyPartId).then(
            (bodyPart) => bodyPart?.parentBodyPartId ?? bodyPartId
    );
  }

  Future<bool> _isSameParentBodyPart(int bodyPartId1, int bodyPartId2) async {
    try {
      final parent1 = await _getParentBodyPart(bodyPartId1);
      final parent2 = await _getParentBodyPart(bodyPartId2);
      return parent1 == parent2;
    } catch (e) {
      _logger.severe('Error comparing parent body parts', e);
      throw ProgramMergerException('Kas grupları karşılaştırılırken hata oluştu');
    }
  }

  Future<Map<int, Parts>> _optimizeSchedule({
    required List<Parts> parts,
    required List<int> selectedDays,
  }) async {
    try {
      final optimizedParts = await _optimizeWorkoutOrder(parts);
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

  Future<List<Parts>> _optimizeWorkoutOrder(List<Parts> parts) async {
    // Ana kas gruplarının öncelik sıralaması
    final priorityOrder = {
      1: 1, // Göğüs - Yüksek öncelik
      2: 1, // Sırt - Yüksek öncelik
      3: 1, // Bacak - Yüksek öncelik
      4: 2, // Omuz - Orta öncelik
      5: 2, // Kol - Orta öncelik
      6: 3, // Karın - Düşük öncelik
    };

    // Her part için hedef kas gruplarını getir
    final partsWithTargets = <Parts, List<PartTargetedBodyParts>>{};
    for (var part in parts) {
      final targets = await _partRepository.getPartTargetedBodyParts(part.id);
      partsWithTargets[part] = targets;
    }

    // Parçaları önceliğe göre sırala
    parts.sort((a, b) {
      final targetsA = partsWithTargets[a] ?? [];
      final targetsB = partsWithTargets[b] ?? [];

      // Birincil hedefleri karşılaştır
      final primaryTargetA = targetsA.firstWhere((t) => t.isPrimary, orElse: () => targetsA.first);
      final primaryTargetB = targetsB.firstWhere((t) => t.isPrimary, orElse: () => targetsB.first);

      final priorityA = priorityOrder[primaryTargetA.bodyPartId] ?? 999;
      final priorityB = priorityOrder[primaryTargetB.bodyPartId] ?? 999;

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
          return await _createSupersetDistribution(schedule, selectedDays);
      }
    } catch (e) {
      _logger.severe('Error distributing exercises', e);
      throw ProgramMergerException('Egzersizler dağıtılırken hata: $e');
    }
  }

  Future<Map<int, List<PartExercise>>> _createSupersetDistribution(
      Map<int, Parts> schedule,
      List<int> selectedDays,
      ) async {
    final distribution = <int, List<PartExercise>>{};

    for (var day in selectedDays) {
      final part = schedule[day];
      if (part == null) continue;

      // Part'ın hedef kas gruplarını al
      final targets = await _partRepository.getPartTargetedBodyParts(part.id);
      if (targets.isEmpty) continue;

      // Birincil hedef kas grubunu bul
      final primaryTarget = targets.firstWhere(
              (t) => t.isPrimary,
          orElse: () => targets.first
      );

      // Ana kas grubunu bul
      final parentBodyPart = await _getParentBodyPart(primaryTarget.bodyPartId);

      // Zıt kas grubu egzersizlerini bul
      final opposingExercises = await _findOpposingExercises(
          parentBodyPart,
          schedule.values.where((p) => p.id != part.id).toList()
      );

      // Part'ın kendi egzersizlerini al
      final mainExercises = await _partRepository.getPartExercisesByPartId(part.id);

      // Süpersetleri oluştur
      final supersetExercises = <PartExercise>[];
      for (var i = 0; i < mainExercises.length; i++) {
        supersetExercises.add(mainExercises[i]);
        if (i < opposingExercises.length) {
          supersetExercises.add(opposingExercises[i]);
        }
      }

      distribution[day] = supersetExercises;
    }

    return distribution;
  }

  Future<List<PartExercise>> _findOpposingExercises(
      int mainBodyPartId,
      List<Parts> otherParts
      ) async {
    // Zıt kas grubu eşleştirmeleri
    final opposingGroups = {
      1: [2], // Göğüs -> Sırt
      2: [1], // Sırt -> Göğüs
      3: [6], // Bacak -> Karın
      4: [5], // Omuz -> Kol
      5: [4], // Kol -> Omuz
      6: [3], // Karın -> Bacak
    };

    final targetBodyParts = opposingGroups[mainBodyPartId] ?? [];
    final opposingExercises = <PartExercise>[];

    for (var part in otherParts) {
      final targets = await _partRepository.getPartTargetedBodyParts(part.id);
      final primaryTarget = targets.firstWhere(
              (t) => t.isPrimary,
          orElse: () => targets.first
      );

      if (targetBodyParts.contains(await _getParentBodyPart(primaryTarget.bodyPartId))) {
        final exercises = await _partRepository.getPartExercisesByPartId(part.id);
        opposingExercises.addAll(exercises);
      }
    }

    return opposingExercises;
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
        final exercises = await _partRepository.getPartExercisesByPartId(part.id);
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

    // Tüm egzersizleri ve hedef kas gruplarını topla
    for (var part in schedule.values) {
      final exercises = await _partRepository.getPartExercisesByPartId(part.id);
      final exerciseTargets = <PartExercise, List<PartTargetedBodyParts>>{};

      for (var exercise in exercises) {
        final targets = await _partRepository.getPartTargetedBodyParts(exercise.partId);
        exerciseTargets[exercise] = targets;
      }

      // Kas gruplarına göre sırala
      exercises.sort((a, b) {
        final targetsA = exerciseTargets[a] ?? [];
        final targetsB = exerciseTargets[b] ?? [];

        final primaryA = targetsA.firstWhere((t) => t.isPrimary, orElse: () => targetsA.first);
        final primaryB = targetsB.firstWhere((t) => t.isPrimary, orElse: () => targetsB.first);

        return primaryA.bodyPartId.compareTo(primaryB.bodyPartId);
      });

      allExercises.addAll(exercises);
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
    final bodyParts = parts.map((p) => _partRepository.getBodyPartNamesByIds(p.targetedBodyPartIds)).join(', ');
    return 'Bu program $bodyParts bölgelerini içeren özelleştirilmiş bir antrenman programıdır.';
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
  final PartRepository partRepository;

  MergedProgram({
    required this.userId,
    required this.name,
    required this.description,
    required this.schedule,
    required this.exercises,
    required this.difficulty,
    required this.mergeType,
    required this.partRepository,
  });

  Future<UserSchedule> toUserSchedule() async {
    final dailyExercises = <String, List<Map<String, dynamic>>>{};

    for (var entry in exercises.entries) {
      final day = entry.key;
      final exerciseList = entry.value;
      final part = schedule[day];
      if (part == null) continue;

      final targets = await partRepository.getPartTargetedBodyParts(part.id);
      final frequency = await partRepository.getPartFrequency(part.id);

      // Ana kas grubunu bul
      final primaryTarget = targets.firstWhere(
              (t) => t.isPrimary,
          orElse: () => targets.first
      );
      final parentBodyPart = await _getParentBodyPart(primaryTarget.bodyPartId);

      dailyExercises['day$day'] = await Future.wait(
          exerciseList.map((pe) async {
            final exerciseTargets = await partRepository.getPartTargetedBodyParts(pe.partId);
            final primaryExerciseTarget = exerciseTargets.firstWhere(
                    (t) => t.isPrimary,
                orElse: () => exerciseTargets.first
            );
            final parentExerciseBodyPart = await _getParentBodyPart(primaryExerciseTarget.bodyPartId);

            // Her hedef kas grubu için parent-child ilişkisini kur
            final targetedBodyPartsDetails = await Future.wait(
                exerciseTargets.map((t) async {
                  final parentId = await _getParentBodyPart(t.bodyPartId);
                  final bodyPartName = await partRepository.getBodyPartName(t.bodyPartId);

                  return {
                    'bodyPartId': t.bodyPartId,
                    'parentBodyPartId': parentId,
                    'bodyPartName': bodyPartName,
                    'targetPercentage': t.targetPercentage,
                    'isPrimary': t.isPrimary,
                  };
                })
            );

            return {
              'exerciseId': pe.exerciseId,
              'partId': pe.partId,
              'orderIndex': pe.orderIndex,
              'isCompleted': false,
              'sets': part.exerciseCount,
              'reps': await _getDefaultReps(parentExerciseBodyPart),
              'weight': await _getDefaultWeight(parentExerciseBodyPart),
              'restTime': _calculateRestTime(
                  parentExerciseBodyPart,
                  frequency?.minRestDays ?? 1,
                  primaryExerciseTarget.targetPercentage
              ),
              'targetPercentage': primaryExerciseTarget.targetPercentage,
              'isPrimary': primaryExerciseTarget.isPrimary,
              'targetedBodyParts': targetedBodyPartsDetails,
              'mainBodyPart': {
                'id': parentExerciseBodyPart,
                'name': await partRepository.getBodyPartName(parentExerciseBodyPart),
              },
              'frequency': {
                'recommendedFrequency': frequency?.recommendedFrequency ?? 3,
                'minRestDays': frequency?.minRestDays ?? 1,
              }
            };
          })
      );
    }

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

  Future<int> _getParentBodyPart(int bodyPartId) async {
    final bodyPart = await partRepository.getBodyPartById(bodyPartId);
    return bodyPart?.parentBodyPartId ?? bodyPartId;
  }

  int _calculateRestTime(int bodyPartId, int minRestDays, int targetPercentage) {
    // Dinlenme süresini hesaplarken frequency tablosundan gelen minRestDays değerini kullanmalıyız
    final baseRestTime = 60;
    final restTimeByBodyPart = {
      1: 90, // Göğüs
      2: 90, // Sırt
      3: 120, // Bacak
      4: 60, // Omuz
      5: 60, // Kol
      6: 45, // Karın
    };

    final intensity = targetPercentage / 100;
    final bodyPartRestTime = restTimeByBodyPart[bodyPartId] ?? baseRestTime;
    return (bodyPartRestTime * intensity * minRestDays).round();
  }


  Future<int> _getDefaultReps(int bodyPartId) async {
    // Önce ana kas grubunu bul
    final parentId = await _getParentBodyPart(bodyPartId);

    switch (parentId) {
      case 1: // Göğüs (Üst, Orta, Alt Göğüs)
      case 2: // Sırt (Latissimus Dorsi, Trapez, Rhomboid)
      case 4: // Omuz (Ön, Yan, Arka Deltoid)
        return 12; // Orta tekrar
      case 3: // Bacak (Quadriceps, Hamstring, Calf)
        return 15; // Yüksek tekrar
      case 5: // Kol (Biceps, Triceps, Ön Kol)
        return 12; // Orta tekrar
      case 6: // Karın (Rectus Abdominis, Obliques, Lower Back)
        return 20; // Çok yüksek tekrar
      default:
        return 12;
    }
  }

  Future<double> _getDefaultWeight(int bodyPartId) async {
    // Önce ana kas grubunu bul
    final parentId = await _getParentBodyPart(bodyPartId);

    switch (parentId) {
      case 1: // Göğüs ve alt grupları
      case 2: // Sırt ve alt grupları
        return 20.0; // Ağır
      case 3: // Bacak ve alt grupları
        return 30.0; // Çok ağır
      case 4: // Omuz ve alt grupları
      case 5: // Kol ve alt grupları
        return 10.0; // Orta
      case 6: // Karın ve alt grupları
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

