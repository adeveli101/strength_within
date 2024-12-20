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

  // Cache için map
  final Map<String, List<Map<String, dynamic>>> _processedDataCache = {};

  // Performans izleme için map
  final Map<String, List<double>> _processingTimes = {};

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

  double normalize(double value, double min, double max) {
    // Girdi kontrolü
    if (value.isNaN || min.isNaN || max.isNaN) {
      _logger.warning('Invalid input for normalization: value=$value, min=$min, max=$max');
      return 0.0;
    }

    // Min-max aynı ise sıfır döndür
    if (max == min) {
      _logger.warning('Min and max values are equal in normalization');
      return 0.0;
    }

    try {
      // Normalizasyon formülü: (x - min) / (max - min)
      double normalized = (value - min) / (max - min);

      // 0-1 aralığına sınırla
      normalized = normalized.clamp(0.0, 1.0);

      return normalized;
    } catch (e) {
      _logger.severe('Normalization error: $e');
      return 0.0;
    }
  }

  // Denormalize metodu (gerekirse kullanılabilir)
  double denormalize(double normalizedValue, double min, double max) {
    if (normalizedValue.isNaN || min.isNaN || max.isNaN) {
      return min;
    }
    return normalizedValue * (max - min) + min;
  }

  Future<Map<String, double>> normalizeFeatures(Map<String, dynamic> features) async {
    final normalizedFeatures = <String, double>{};

    features.forEach((key, value) {
      if (_normalizationRanges.containsKey(key.toLowerCase())) {
        final range = _normalizationRanges[key.toLowerCase()]!;
        normalizedFeatures[key] = normalize(
            value is num ? value.toDouble() : 0.0,
            range['min']!,
            range['max']!
        );
      }
    });

    return normalizedFeatures;
  }

  // Ana veri işleme metodu
  Future<List<Map<String, dynamic>>> processTrainingData() async {
    int retryCount = 0;

    while (retryCount < AIConstants.MAX_RETRIES) {
      try {
        // Cache kontrolü ve validasyonu
        if (_processedDataCache.containsKey('training_data')) {
          if (_processedDataCache['training_data']!.isEmpty) {
            _logger.warning('Cache contains empty data');
            _processedDataCache.remove('training_data');
          } else {
            _logger.info('Returning validated cached training data');
            return _processedDataCache['training_data']!;
          }
        }

        final startTime = DateTime.now();

        // Ham verileri al
        final bmiData = await _datasetProvider.getBMIDataset();
        final bfpData = await _datasetProvider.getBFPDataset();
        final exerciseData = await _datasetProvider.getExerciseTrackingData();

        // Veri validasyonu
        if (bmiData.isEmpty || bfpData.isEmpty || exerciseData.isEmpty) {
          throw AIDataProcessingException(
              'Empty dataset provided',
              code: AIConstants.ERROR_INSUFFICIENT_DATA
          );
        }

        // Verileri valide et
        await _validateDatasets(bmiData, bfpData, exerciseData);

        // Verileri batch'ler halinde işle
        final processedData = await _processInBatches(
            bmiData: bmiData,
            bfpData: bfpData,
            exerciseData: exerciseData,
            batchSize: AIConstants.MAX_BATCH_SIZE
        );

        // Veri tutarlılığını kontrol et
        if (!await _validateDataConsistency(processedData)) {
          throw AIDataProcessingException(
              'Data consistency check failed',
              code: AIConstants.ERROR_INVALID_STATE
          );
        }

        // Cache boyutunu kontrol et ve güncelle
        await _checkCacheSize();
        _processedDataCache['training_data'] = processedData;

        // Performans izleme
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        await _trackProcessingTime('process_training_data', duration.toDouble());

        _logPerformanceMetrics();
        _logger.info('Veri işleme tamamlandı. İşlenen veri sayısı: ${processedData.length}');

        return processedData;

      } catch (e) {
        retryCount++;
        _logger.warning('Processing attempt $retryCount failed: $e');

        if (retryCount == AIConstants.MAX_RETRIES) {
          _logger.severe('Max retry attempts reached');
          throw AIDataProcessingException('Veri işleme başarısız: $e');
        }

        await Future.delayed(Duration(seconds: AIConstants.RETRY_DELAY_SECONDS));
      }
    }

    throw AIDataProcessingException('Unexpected error in data processing');
  }

  Future<List<Map<String, dynamic>>> _processInBatches({
    required List<Map<String, dynamic>> bmiData,
    required List<Map<String, dynamic>> bfpData,
    required List<Map<String, dynamic>> exerciseData,
    required int batchSize
  }) async {
    final allProcessedData = <Map<String, dynamic>>[];

    // BMI ve BFP verilerini batch'ler halinde işle
    for (var i = 0; i < bmiData.length; i += batchSize) {
      final end = (i + batchSize < bmiData.length) ? i + batchSize : bmiData.length;
      final bmiBatch = bmiData.sublist(i, end);

      for (var bmiRecord in bmiBatch) {
        final matchingBfp = _findMatchingBfpRecord(bmiRecord, bfpData);
        if (matchingBfp != null && matchingBfp.isNotEmpty) {
          try {
            final processedRecord = await _processRecord(bmiRecord, matchingBfp);
            allProcessedData.add(processedRecord);
          } catch (e) {
            _logger.warning('Error processing record: $e');
          }
        }
      }
    }

    // Exercise verilerini batch'ler halinde işle
    for (var i = 0; i < exerciseData.length; i += batchSize) {
      final end = (i + batchSize < exerciseData.length) ? i + batchSize : exerciseData.length;
      final exerciseBatch = exerciseData.sublist(i, end);

      for (var exerciseRecord in exerciseBatch) {
        try {
          final processedRecord = await _processExerciseRecord(exerciseRecord);
          allProcessedData.add(processedRecord);
        } catch (e) {
          _logger.warning('Error processing exercise record: $e');
        }
      }
    }

    return allProcessedData;
  }

// 3. _validateDataConsistency metodunun eklenmesi
  Future<bool> _validateDataConsistency(List<Map<String, dynamic>> processedData) async {
    if (processedData.isEmpty) {
      _logger.warning('Empty processed data');
      return false;
    }

    try {
      final firstRecord = processedData.first;
      final requiredKeys = {'features', 'categorical'};
      final featureKeys = (firstRecord['features'] as Map).keys.toSet();
      final categoricalKeys = (firstRecord['categorical'] as Map).keys.toSet();

      final validRecords = processedData.where((record) {
        return requiredKeys.every((key) => record.containsKey(key)) &&
            record['features'].keys.toSet().containsAll(featureKeys) &&
            record['categorical'].keys.toSet().containsAll(categoricalKeys);
      }).length;

      final validRatio = validRecords / processedData.length;
      return validRatio >= AIConstants.MIN_VALID_DATA_RATIO;
    } catch (e) {
      _logger.severe('Data consistency validation error: $e');
      return false;
    }
  }

// 4. _checkCacheSize metodunun eklenmesi
  Future<void> _checkCacheSize() async {
    if (_processedDataCache.length > AIConstants.MAX_CACHE_SIZE) {
      _logger.warning('Cache size exceeded limit, clearing cache');
      await clearCache();
    }
  }

// 5. dispose metodunun eklenmesi
  Future<void> dispose() async {
    try {
      await clearCache();
      await clearProcessingTimes();
      _logger.info('Resources disposed successfully');
    } catch (e) {
      _logger.severe('Error during resource disposal: $e');
    }
  }

// 6. _logPerformanceMetrics metodunun eklenmesi
  void _logPerformanceMetrics() {
    try {
      final metrics = getAverageProcessingTimes();
      _logger.info('Performance metrics: ${metrics.toString()}');

      // Log memory usage
      final cacheSize = _processedDataCache.length;
      _logger.info('Current cache size: $cacheSize records');
    } catch (e) {
      _logger.warning('Error logging performance metrics: $e');
    }
  }

  // Veri validasyonu
  Future<void> _validateDatasets(
      List<Map<String, dynamic>> bmiData,
      List<Map<String, dynamic>> bfpData,
      List<Map<String, dynamic>> exerciseData,
      ) async {
    for (var data in bmiData) {
      if (!await validateFeatures(data)) {
        throw AIDataProcessingException('Invalid BMI data format');
      }
    }

    for (var data in bfpData) {
      if (!await validateFeatures(data)) {
        throw AIDataProcessingException('Invalid BFP data format');
      }
    }

    for (var data in exerciseData) {
      if (!await validateFeatures(data)) {
        throw AIDataProcessingException('Invalid exercise data format');
      }
    }
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

  // Tekil kayıt işleme
  Future<Map<String, dynamic>> _processRecord(
      Map<String, dynamic> bmiRecord,
      Map<String, dynamic> bfpRecord,
      ) async {
    return {
      // Normalize edilmiş sayısal özellikler
      'features': {
        'weight_normalized': normalize(
          bmiRecord['Weight']?.toDouble() ?? 0.0,
          _normalizationRanges['weight']!['min']!,
          _normalizationRanges['weight']!['max']!,
        ),
        'height_normalized': normalize(
          bmiRecord['Height']?.toDouble() ?? 0.0,
          _normalizationRanges['height']!['min']!,
          _normalizationRanges['height']!['max']!,
        ),
        'bmi_normalized': normalize(
          bmiRecord['BMI']?.toDouble() ?? 0.0,
          _normalizationRanges['bmi']!['min']!,
          _normalizationRanges['bmi']!['max']!,
        ),
        'bfp_normalized': normalize(
          bfpRecord['Body Fat Percentage']?.toDouble() ?? 0.0,
          _normalizationRanges['bfp']!['min']!,
          _normalizationRanges['bfp']!['max']!,
        ),
        'age_normalized': normalize(
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
        'max_bpm_normalized': normalize(
          exerciseRecord['Max_BPM']?.toDouble() ?? 0.0,
          _normalizationRanges['max_bpm']!['min']!,
          _normalizationRanges['max_bpm']!['max']!,
        ),
        'session_duration_normalized': normalize(
          exerciseRecord['Session_Duration (hours)']?.toDouble() ?? 0.0,
          _normalizationRanges['session_duration']!['min']!,
          _normalizationRanges['session_duration']!['max']!,
        ),
        'workout_frequency_normalized': normalize(
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

  // Yardımcı metodlar için gerekli
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


  // Verileri normalize et ve birleştir
  Future<List<Map<String, dynamic>>> _normalizeAndCombineData({
    required List<Map<String, dynamic>> bmiData,
    required List<Map<String, dynamic>> bfpData,
    required List<Map<String, dynamic>> exerciseData,
  }) async {
    final startTime = DateTime.now();
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

    // Veri augmentasyonu uygula
    final augmentedData = await augmentData(processedData);
    processedData.addAll(augmentedData);

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    await _trackProcessingTime('normalize_and_combine', duration.toDouble());

    return processedData;
  }

  // Veri augmentasyonu
  Future<List<Map<String, dynamic>>> augmentData(
      List<Map<String, dynamic>> data,
      {double noise = 0.05}
      ) async {
    final augmentedData = <Map<String, dynamic>>[];
    final random = Random();

    for (var record in data) {
      final features = record['features'] as Map<String, dynamic>;
      final noisyFeatures = Map<String, dynamic>.from(features);

      // Add random noise to numeric features
      for (var key in features.keys) {
        if (features[key] is double) {
          final value = features[key] as double;
          final noiseAmount = value * noise * (random.nextDouble() * 2 - 1);
          noisyFeatures[key] = (value + noiseAmount).clamp(0.0, 1.0);
        }
      }

      augmentedData.add({
        ...record,
        'features': noisyFeatures,
      });
    }

    return augmentedData;
  }

  // Performans izleme
  Future<void> _trackProcessingTime(String operation, double milliseconds) async {
    _processingTimes[operation] ??= [];
    _processingTimes[operation]!.add(milliseconds);

    if (_processingTimes[operation]!.length > AIConstants.MAX_PROCESSING_HISTORY) {
      _processingTimes[operation]!.removeAt(0);
    }
  }

  // Performans metriklerini al
  Map<String, double> getAverageProcessingTimes() {
    return Map.fromEntries(
        _processingTimes.entries.map((e) => MapEntry(
            e.key,
            e.value.reduce((a, b) => a + b) / e.value.length
        ))
    );
  }

  // Veri doğrulama
  Future<bool> validateFeatures(Map<String, dynamic> data) async {
    final requiredFeatures = [
      'Weight',
      'Height',
      'BMI',
      'Age',
      'Gender',
      'Exercise Recommendation Plan'
    ];

    if (!requiredFeatures.every((feature) =>
    data.containsKey(feature) && data[feature] != null)) {
      return false;
    }

    // Numeric değerlerin range kontrolü
    for (var feature in ['Weight', 'Height', 'BMI', 'Age']) {
      if (!await validateNumericRange(
          feature.toLowerCase(),
          data[feature]?.toDouble() ?? 0.0
      )) {
        return false;
      }
    }

    return true;
  }

  // Sayısal değer doğrulama
  Future<bool> validateNumericRange(String feature, double value) async {
    if (!_normalizationRanges.containsKey(feature)) return false;

    final range = _normalizationRanges[feature]!;
    return value >= range['min']! && value <= range['max']!;
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

  // Cache temizleme
  Future<void> clearCache() async {
    _processedDataCache.clear();
    _logger.info('Cache cleared');
  }

  // Performans metrikleri temizleme
  Future<void> clearProcessingTimes() async {
    _processingTimes.clear();
    _logger.info('Processing times cleared');
  }
}