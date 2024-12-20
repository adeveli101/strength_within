import 'dart:math';
import 'package:logging/logging.dart';
import '../ai_data_bloc/dataset_provider.dart';
import 'ai_constants.dart';
import 'ai_exceptions.dart';

class AIDataProcessor {
  // Singleton pattern implementation
  static final AIDataProcessor _instance = AIDataProcessor._internal();
  factory AIDataProcessor() => _instance;
  AIDataProcessor._internal();

  final _logger = Logger('AIDataProcessor');
  final _datasetProvider = DatasetDBProvider();

  // Normalizasyon için min-max değerleri
  static const _normalizationRanges = {
    'weight': {'min': 40.0, 'max': 150.0},  // kg
    'height': {'min': 1.4, 'max': 2.2},     // m
    'bmi': {'min': 16.0, 'max': 40.0},      // BMI range
    'bfp': {'min': 5.0, 'max': 50.0},       // Body Fat Percentage
    'age': {'min': 16.0, 'max': 80.0},      // Age range
    'max_bpm': {'min': 160.0, 'max': 200.0},
    'session_duration': {'min': 0.5, 'max': 2.0},
    'workout_frequency': {'min': 1.0, 'max': 7.0},
  };

  // Ana veri işleme metodu
  Future<List<Map<String, dynamic>>> processTrainingData() async {
    try {
      // Ham verileri al
      final bmiData = await _datasetProvider.getBMIDataset();
      final bfpData = await _datasetProvider.getBFPDataset();
      final exerciseData = await _datasetProvider.getExerciseTrackingData();

      // Verileri normalize et ve birleştir
      final processedData = await _normalizeAndCombineData(
        bmiData: bmiData,
        bfpData: bfpData,
        exerciseData: exerciseData,
      );

      _logger.info('Veri işleme tamamlandı. İşlenen veri sayısı: ${processedData.length}');
      return processedData;

    } catch (e) {
      _logger.severe('Veri işleme hatası: $e');
      throw AIDataProcessingException('Veri işleme sırasında hata: $e');
    }
  }

  // Verileri normalize et ve birleştir
  Future<List<Map<String, dynamic>>> _normalizeAndCombineData({
    required List<Map<String, dynamic>> bmiData,
    required List<Map<String, dynamic>> bfpData,
    required List<Map<String, dynamic>> exerciseData,
  }) async {
    final processedData = <Map<String, dynamic>>[];

    // BMI ve BFP verilerini eşleştir ve işle
    for (var bmiRecord in bmiData) {
      final matchingBfp = _findMatchingBfpRecord(bmiRecord, bfpData);
      if (matchingBfp != null) {
        processedData.add(await _processRecord(bmiRecord, matchingBfp));
      }
    }

    // Exercise tracking verilerini işle
    for (var exerciseRecord in exerciseData) {
      processedData.add(await _processExerciseRecord(exerciseRecord));
    }

    return processedData;
  }

  // Tekil kayıt işleme
  Future<Map<String, dynamic>> _processRecord(
      Map<String, dynamic> bmiRecord,
      Map<String, dynamic> bfpRecord,
      ) async {
    return {
      // Normalize edilmiş sayısal özellikler
      'features': {
        'weight_normalized': _normalize(
          bmiRecord['Weight']?.toDouble() ?? 0.0,
          _normalizationRanges['weight']!['min']!,
          _normalizationRanges['weight']!['max']!,
        ),
        'height_normalized': _normalize(
          bmiRecord['Height']?.toDouble() ?? 0.0,
          _normalizationRanges['height']!['min']!,
          _normalizationRanges['height']!['max']!,
        ),
        'bmi_normalized': _normalize(
          bmiRecord['BMI']?.toDouble() ?? 0.0,
          _normalizationRanges['bmi']!['min']!,
          _normalizationRanges['bmi']!['max']!,
        ),
        'bfp_normalized': _normalize(
          bfpRecord['Body Fat Percentage']?.toDouble() ?? 0.0,
          _normalizationRanges['bfp']!['min']!,
          _normalizationRanges['bfp']!['max']!,
        ),
        'age_normalized': _normalize(
          bmiRecord['Age']?.toDouble() ?? 0.0,
          _normalizationRanges['age']!['min']!,
          _normalizationRanges['age']!['max']!,
        ),
      },
      // Kategorik özellikler
      'categorical': {
        ..._processGender(bmiRecord['Gender']),
        ..._processBMICase(bmiRecord['BMIcase']),
        ..._processBFPCase(bfpRecord['BFPcase']),
      },
      // Etiket (hedef değişken)
      'label': bmiRecord['Exercise Recommendation Plan'],
    };
  }

  // Exercise kayıtlarını işle
  Future<Map<String, dynamic>> _processExerciseRecord(
      Map<String, dynamic> exerciseRecord,
      ) async {
    return {
      'features': {
        'max_bpm_normalized': _normalize(
          exerciseRecord['Max_BPM']?.toDouble() ?? 0.0,
          _normalizationRanges['max_bpm']!['min']!,
          _normalizationRanges['max_bpm']!['max']!,
        ),
        'session_duration_normalized': _normalize(
          exerciseRecord['Session_Duration (hours)']?.toDouble() ?? 0.0,
          _normalizationRanges['session_duration']!['min']!,
          _normalizationRanges['session_duration']!['max']!,
        ),
        'workout_frequency_normalized': _normalize(
          exerciseRecord['Workout_Frequency (days/week)']?.toDouble() ?? 0.0,
          _normalizationRanges['workout_frequency']!['min']!,
          _normalizationRanges['workout_frequency']!['max']!,
        ),
      },
      'categorical': {
        ..._processWorkoutType(exerciseRecord['Workout_Type']),
        ..._processExperienceLevel(exerciseRecord['Experience_Level']),
      },
    };
  }

  // Yardımcı metodlar
  double _normalize(double value, double min, double max) {
    if (value.isNaN || min.isNaN || max.isNaN) return 0.0;
    if (max == min) return 0.0;
    return (value - min) / (max - min);
  }

  Map<String, double> _processGender(String? gender) {
    return {
      'gender_male': gender?.toLowerCase() == 'male' ? 1.0 : 0.0,
      'gender_female': gender?.toLowerCase() == 'female' ? 1.0 : 0.0,
    };
  }

  Map<String, double> _processBMICase(String? bmiCase) {
    final cases = ['underweight', 'normal', 'overweight', 'obese'];
    return Map.fromEntries(
      cases.map((c) => MapEntry('bmi_$c', bmiCase?.toLowerCase() == c ? 1.0 : 0.0)),
    );
  }

  Map<String, double> _processBFPCase(String? bfpCase) {
    final cases = ['low', 'normal', 'high', 'very_high'];
    return Map.fromEntries(
      cases.map((c) => MapEntry('bfp_$c', bfpCase?.toLowerCase() == c ? 1.0 : 0.0)),
    );
  }

  Map<String, double> _processWorkoutType(String? workoutType) {
    final types = ['cardio', 'strength', 'hiit', 'yoga'];
    return Map.fromEntries(
      types.map((t) => MapEntry('workout_$t', workoutType?.toLowerCase() == t ? 1.0 : 0.0)),
    );
  }

  Map<String, double> _processExperienceLevel(int? level) {
    return {
      'experience_beginner': level == 1 ? 1.0 : 0.0,
      'experience_intermediate': level == 2 ? 1.0 : 0.0,
      'experience_advanced': level == 3 ? 1.0 : 0.0,
    };
  }

  // Eşleşen BFP kaydını bul
  Map<String, dynamic>? _findMatchingBfpRecord(
      Map<String, dynamic> bmiRecord,
      List<Map<String, dynamic>> bfpData,
      ) {
    return bfpData.firstWhere(
          (bfp) =>
      bfp['Weight'] == bmiRecord['Weight'] &&
          bfp['Height'] == bmiRecord['Height'] &&
          bfp['BMI'] == bmiRecord['BMI'] &&
          bfp['Gender'] == bmiRecord['Gender'] &&
          bfp['Age'] == bmiRecord['Age'],
      orElse: () => {},
    );
  }

  // Veri seti bölme
  Future<Map<String, List<Map<String, dynamic>>>> splitDataset(
      List<Map<String, dynamic>> dataset, {
        double validationSplit = 0.2,
        double testSplit = 0.1,
      }) async {
    assert(validationSplit + testSplit < 1.0);

    dataset.shuffle(Random(42)); // Sabit seed ile karıştır

    final trainSize = (dataset.length * (1 - validationSplit - testSplit)).toInt();
    final validationSize = (dataset.length * validationSplit).toInt();

    return {
      'train': dataset.sublist(0, trainSize),
      'validation': dataset.sublist(trainSize, trainSize + validationSize),
      'test': dataset.sublist(trainSize + validationSize),
    };
  }

  // Mini-batch oluştur
  Future<List<Map<String, dynamic>>> createBatch(
      List<Map<String, dynamic>> dataset,
      int batchSize,
      ) async {
    if (dataset.length < batchSize) {
      throw AIDataProcessingException(
        'Dataset boyutu batch boyutundan küçük',
        code: AIConstants.ERROR_INSUFFICIENT_DATA,
      );
    }

    final random = Random();
    final indices = List.generate(batchSize, (_) => random.nextInt(dataset.length));
    return indices.map((i) => dataset[i]).toList();
  }
}