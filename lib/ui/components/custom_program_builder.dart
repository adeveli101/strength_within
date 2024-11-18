import '../../data_bloc_part/PartRepository.dart';
import '../../models/PartExercises.dart';
import '../../models/Parts.dart';
import '../../models/WorkoutType.dart';

class CustomProgramBuilder {
  final PartRepository _partRepository;

  // Kısıtlama sabitleri
  static const int MAX_TOTAL_DIFFICULTY = 15; // Maksimum toplam zorluk
  static const int MAX_PARTS_PER_BODYPART = 1; // Her bölge için maksimum program
  static const int MIN_REST_DAYS = 1; // Minimum dinlenme günü
  static const Map<int, int> MAX_DIFFICULTY_PER_LEVEL = {
    1: 2, // Başlangıç seviyesi için max zorluk
    2: 3, // Orta seviye için max zorluk
    3: 4, // İleri seviye için max zorluk
    4: 5, // Uzman seviye için max zorluk
  };

  CustomProgramBuilder(this._partRepository);

  Future<List<WorkoutDay>> createProgram(List<int> selectedPartIds) async {
    try {
      final selectedParts = await _getPartsInfo(selectedPartIds);

      // Toplam zorluk kontrolü
      final difficultyValidation = _validateTotalDifficulty(selectedParts);
      if (!difficultyValidation.isValid) {
        throw Exception(difficultyValidation.message);
      }

      // Vücut bölgesi dağılımı kontrolü
      final distributionValidation = _validateBodyPartDistribution(selectedParts);
      if (!distributionValidation.isValid) {
        throw Exception(distributionValidation.message);
      }

      // Frekans kontrolü
      final frequencyValidation = await _validateFrequency(selectedParts);
      if (!frequencyValidation.isValid) {
        throw Exception(frequencyValidation.message);
      }

      // Kas grubu çakışma kontrolü
      final conflictValidation = await _validateMuscleConflicts(selectedParts);
      if (!conflictValidation.isValid) {
        throw Exception(conflictValidation.message);
      }

      return await _buildWorkoutSchedule(selectedParts);
    } catch (e) {
      throw Exception('Program oluşturma hatası: $e');
    }
  }

  // Toplam zorluk kontrolü
  ValidationResult _validateTotalDifficulty(List<Parts> parts) {
    int totalDifficulty = parts.fold(0, (sum, part) => sum + part.difficulty);

    if (totalDifficulty > MAX_TOTAL_DIFFICULTY) {
      return ValidationResult(
          isValid: false,
          message: 'Toplam program zorluğu çok yüksek (Max: $MAX_TOTAL_DIFFICULTY, Mevcut: $totalDifficulty)'
      );
    }

    // Zorluk seviyesi dağılımı kontrolü
    Map<int, int> difficultyCount = {};
    for (var part in parts) {
      difficultyCount[part.difficulty] = (difficultyCount[part.difficulty] ?? 0) + 1;

      // Her zorluk seviyesi için maksimum limit kontrolü
      if (MAX_DIFFICULTY_PER_LEVEL.containsKey(part.difficulty) &&
          difficultyCount[part.difficulty]! > MAX_DIFFICULTY_PER_LEVEL[part.difficulty]!) {
        return ValidationResult(
            isValid: false,
            message: 'Zorluk seviyesi ${part.difficulty} için çok fazla program seçilmiş'
        );
      }
    }

    return ValidationResult(isValid: true);
  }

  // Vücut bölgesi dağılımı kontrolü
  ValidationResult _validateBodyPartDistribution(List<Parts> parts) {
    Map<int, int> bodyPartCount = {};

    for (var part in parts) {
      bodyPartCount[part.bodyPartId] = (bodyPartCount[part.bodyPartId] ?? 0) + 1;

      if (bodyPartCount[part.bodyPartId]! > MAX_PARTS_PER_BODYPART) {
        return ValidationResult(
            isValid: false,
            message: '${_getBodyPartName(part.bodyPartId)} için birden fazla program seçilemez'
        );
      }
    }

    // Dengeli dağılım kontrolü
    if (parts.length >= 3) {
      bool hasUpperBody = parts.any((p) => [1, 2, 4, 5].contains(p.bodyPartId)); // Üst vücut
      bool hasLowerBody = parts.any((p) => p.bodyPartId == 3); // Alt vücut
      bool hasCore = parts.any((p) => p.bodyPartId == 6); // Core

      if (!hasUpperBody || !hasLowerBody) {
        return ValidationResult(
            isValid: false,
            message: 'Program dengeli değil. Üst ve alt vücut egzersizleri ekleyin'
        );
      }
    }

    return ValidationResult(isValid: true);
  }

  // Program oluşturma mantığı güncellendi
  Future<List<WorkoutDay>> _buildWorkoutSchedule(List<Parts> parts) async {
    List<WorkoutDay> schedule = [];
    int currentDay = 1;

    // Önce zorluk derecesine göre sırala
    parts.sort((a, b) => b.difficulty.compareTo(a.difficulty));

    // Sonra vücut bölgesi dağılımına göre optimize et
    List<Parts> optimizedParts = _optimizeWorkoutOrder(parts);

    for (var part in optimizedParts) {
      final exercises = await _partRepository.getPartExercisesByPartId(part.id);

      schedule.add(
          WorkoutDay(
              dayIndex: currentDay,
              partId: part.id,
              exercises: exercises,
              restTimeMinutes: _calculateRestTime(part.difficulty),
              workoutType: await _getWorkoutType(part)
          )
      );

      currentDay += MIN_REST_DAYS + 1; // Minimum dinlenme günü ekle
    }

    return schedule;
  }

  // Antrenman sıralamasını optimize et
  List<Parts> _optimizeWorkoutOrder(List<Parts> parts) {
    // Büyük kas gruplarını öne al
    final upperBody = parts.where((p) => [1, 2].contains(p.bodyPartId)).toList();
    final lowerBody = parts.where((p) => p.bodyPartId == 3).toList();
    final others = parts.where((p) => ![1, 2, 3].contains(p.bodyPartId)).toList();

    return [...upperBody, ...lowerBody, ...others];
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


  Future<List<Parts>> _getPartsInfo(List<int> partIds) async {
    List<Parts> selectedParts = [];
    for (var id in partIds) {
      final part = await _partRepository.getPartById(id);
      if (part != null) {
        selectedParts.add(part);
      }
    }
    return selectedParts;
  }

  // Dinlenme süresini hesapla
  int _calculateRestTime(int difficulty) {
    // Zorluk seviyesine göre dinlenme süresi hesaplama
    switch (difficulty) {
      case 1: // Kolay
        return 60; // 60 saniye
      case 2: // Orta
        return 90; // 90 saniye
      case 3: // Zor
        return 120; // 2 dakika
      case 4: // Çok Zor
        return 150; // 2.5 dakika
      case 5: // Uzman
        return 180; // 3 dakika
      default:
        return 90; // Varsayılan
    }
  }

  // WorkoutType bilgisini getir
  Future<WorkoutTypes> _getWorkoutType(Parts part) async {
    // Part'a ait egzersizlerin WorkoutType'ını belirle
    final exercises = await _partRepository.getPartExercisesByPartId(part.id);
    if (exercises.isEmpty) {
      return WorkoutTypes(id: 1, name: 'Strength'); // Varsayılan
    }

    // En çok kullanılan WorkoutType'ı bul
    Map<int, int> typeFrequency = {};
    for (var exercise in exercises) {
      final exerciseDetails = await _partRepository.getExerciseById(exercise.exerciseId);
      if (exerciseDetails != null) {
        typeFrequency[exerciseDetails.workoutTypeId] =
            (typeFrequency[exerciseDetails.workoutTypeId] ?? 0) + 1;
      }
    }

    // En çok kullanılan WorkoutType'ı döndür
    var mostFrequentTypeId = typeFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final workoutType = await _partRepository.getWorkoutTypeById(mostFrequentTypeId);
    return workoutType ?? WorkoutTypes(id: 1, name: 'Strength');
  }

  // Frekans kontrolü
  Future<ValidationResult> _validateFrequency(List<Parts> parts) async {
    Map<int, int> weeklyFrequency = {};

    for (var part in parts) {
      final frequency = await _partRepository.getPartFrequency(part.id);
      if (frequency == null) continue;

      weeklyFrequency[part.bodyPartId] =
          (weeklyFrequency[part.bodyPartId] ?? 0) + frequency.recommendedFrequency;

      // Maksimum haftalık frekans kontrolü
      if (weeklyFrequency[part.bodyPartId]! > 3) { // Haftalık max 3 kez
        return ValidationResult(
            isValid: false,
            message: '${part.name} haftada çok fazla tekrar ediliyor'
        );
      }
    }
    return ValidationResult(isValid: true);
  }

  // Kas grubu çakışma kontrolü
  Future<ValidationResult> _validateMuscleConflicts(List<Parts> parts) async {
    Map<int, List<DateTime>> muscleGroupWorkouts = {};

    for (var part in parts) {
      if (muscleGroupWorkouts.containsKey(part.bodyPartId)) {
        // Aynı kas grubu için minimum dinlenme süresi kontrolü
        final lastWorkout = muscleGroupWorkouts[part.bodyPartId]!.last;
        final minRestHours = part.difficulty >= 4 ? 72 : 48; // Zorluk seviyesine göre dinlenme

        if (DateTime.now().difference(lastWorkout).inHours < minRestHours) {
          return ValidationResult(
              isValid: false,
              message: '${part.name} için yeterli dinlenme süresi yok'
          );
        }
      }
      muscleGroupWorkouts[part.bodyPartId] = [DateTime.now()];
    }
    return ValidationResult(isValid: true);
  }

  // Program oluşturma
}

class ValidationResult {
  final bool isValid;
  final String? message;

  ValidationResult({required this.isValid, this.message});
}

class WorkoutDay {
  final int dayIndex;
  final int partId;
  final List<PartExercise> exercises;
  final int restTimeMinutes;
  final WorkoutTypes workoutType;

  WorkoutDay({
    required this.dayIndex,
    required this.partId,
    required this.exercises,
    required this.restTimeMinutes,
    required this.workoutType,
  });
}