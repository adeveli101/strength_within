// ignore_for_file: prefer_final_fields

import 'dart:async';
import 'dart:math';
import 'package:logging/logging.dart';
import '../ai_data_bloc/datasets_models.dart';
import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import 'base_model.dart';

enum AGDEModelState {
  uninitialized,
  initializing,
  initialized,
  training,
  trained,
  predicting,
  paused,
  stopped,
  error
}

class TrainingProgress {
  final int generation;
  final double bestFitness;
  final double avgFitness;
  final Map<String, double> metrics;
  final AGDEModelState state;

  TrainingProgress({
    required this.generation,
    required this.bestFitness,
    required this.avgFitness,
    required this.metrics,
    required this.state,
  });
}

class AGDEModel extends BaseModel {
  final _logger = Logger('AGDEModel');
  AGDEModelState _modelState = AGDEModelState.uninitialized;

  // AGDE Evrim Parametreleri
  final int populationSize = 50;
  final int maxGenerations = AIConstants.EPOCHS;
  final double initialMutationRate = 0.3;
  final double initialCrossoverRate = 0.8;
  late double adaptiveMutationRate;
  late double adaptiveCrossoverRate;

  // Veri yapıları
  late List<List<double>> population;
  late List<double> fitnessValues;
  late List<double> _featureMeans;
  late List<double> _featureStds;
  late List<double> _previousFitnessValues;

  // Model boyutları
  late  int _inputSize;
  late int _outputSize;

  // Training Progress için Stream
  final _trainingProgressController = StreamController<TrainingProgress>.broadcast();
  Stream<TrainingProgress> get trainingProgress => _trainingProgressController.stream;

  // Kontrol değişkenleri
  bool _isPaused = false;
  bool _shouldStop = false;

  // Eğitim geçmişi
  final Map<String, List<double>> _trainingHistory = {
    'fitness': [],
    'mutation_rate': [],
    'crossover_rate': [],
    'best_fitness': [],
    'avg_fitness': [],
  };


  // AGDEModel sınıfında
  @override
  Future<void> setup(List<Map<String, dynamic>> trainingData) async {
    try {
      _modelState = AGDEModelState.initializing;
      _logger.info('AGDE Model setup started...');

      // Veri validasyonu
      await _validateTrainingData(trainingData);

      // Model boyutlarını belirle
      await _initializeModelDimensions(trainingData.first);

      _initializePopulation();

      // İstatistiksel değerleri hesapla
      await _initializeFeatureStats(trainingData);

      // Model parametrelerini ayarla
      _initializeModelParameters();

      // Popülasyonu oluştur
      _initializePopulation();

      _modelState = AGDEModelState.initialized;
      _logger.info('AGDE Model setup completed successfully');

    } catch (e) {
      _modelState = AGDEModelState.error;
      _logger.severe('AGDE Model setup failed: $e');
      throw AIModelException('AGDE model kurulumu başarısız: $e');
    }
  }

  Future<void> _validateTrainingData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      throw AIModelException('Boş eğitim verisi');
    }

    for (var sample in data) {
      _validateSampleFields(sample);
    }
  }

  Future<void> _initializeModelDimensions(Map<String, dynamic> firstSample) async {
    try {
      _inputSize = 16; // Toplam feature sayısı
      _outputSize = 6; // Sabit çıktı boyutu

      _featureMeans = List.filled(_inputSize, 0.0);
      _featureStds = List.filled(_inputSize, 0.0);

      _logger.info('Model dimensions initialized: Input=$_inputSize, Output=$_outputSize');
    } catch (e) {
      throw AIModelException('Model boyutları belirlenemedi: $e');
    }
  }

  void _initializeModelParameters() {
    adaptiveMutationRate = initialMutationRate;
    adaptiveCrossoverRate = initialCrossoverRate;

    _previousFitnessValues = List.filled(populationSize, 0.0);
    fitnessValues = List.filled(populationSize, 0.0);
  }

  void _initializePopulation() {
    final random = Random();
    population = List.generate(
        populationSize,
            (_) => List.generate(
            _inputSize,
                (_) => random.nextDouble() * 2 - 1 // [-1, 1] aralığında
        )
    );
  }

  void _validateNumericRange(dynamic value, num min, num max, String field) {
    if (value is! num) {
      throw AIModelException('$field sayısal bir değer olmalıdır');
    }
    if (value < min || value > max) {
      throw AIModelException('$field değeri $min ile $max arasında olmalıdır');
    }
  }

  double _parseNumericField(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;

    if (value is num) return value.toDouble();

    if (value is String) {
      // Özel format temizleme
      String cleanValue = value
          .toLowerCase()
          .replaceAll(RegExp(r'[^0-9.]'), '')
          .replaceAll(RegExp(r'\.(?=.*\.)'), '');

      return double.tryParse(cleanValue) ?? defaultValue;
    }

    return defaultValue;
  }

  void _cleanNumericFields(Map<String, dynamic> data) {
    final numericFields = [
      'height_m', 'weight_kg', 'session_duration',
      'water_intake', 'workout_frequency'
    ];
    for (var field in numericFields) {
      if (data[field] is String) {
        data[field] = _parseNumericValue(data[field], field);
      }
    }
  }

  double _getDefaultValue(String field) {
    switch (field) {
      case 'height_m':
        return 1.70;
      case 'weight_kg':
        return 70.0;
      case 'session_duration':
        return 1.0;
      case 'water_intake':
        return 2.0;
      case 'workout_frequency':
        return 3.0;
      default:
        return 0.0;
    }
  }

  List<double> _extractFeatures(GymMembersTracking sample) {
    try {
      return [
        _safeDouble(sample.id),
        _safeDouble(sample.age),
        _safeDouble(sample.avgBpm),
        sample.bmi,
        sample.caloriesBurned,
        _safeDouble(sample.experienceLevel),
        sample.fatPercentage,
        _safeDouble(sample.maxBpm),
        _safeDouble(sample.restingBpm),
        sample.sessionDuration,
        sample.waterIntake,
        _safeDouble(sample.workoutFrequency),
        _encodeGender(sample.gender),
        _encodeWorkoutType(sample.workoutType),
        _safeDouble(sample.heightM),
        _safeDouble(sample.weightKg)
      ];
    } catch (e) {
      _logger.severe('Feature extraction error: $e');
      throw AIModelException('Feature extraction hatası: $e');
    }
  }

  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
    }
    return 0.0;
  }

  double _encodeGender(String? gender) {
    if (gender == null) return 0.0;
    return gender.toLowerCase() == 'male' ? 1.0 : 0.0;
  }

  Future<void> _initializeFeatureStats(List<Map<String, dynamic>> trainingData) async {
    try {
      _logger.info('Feature stats initialization started');
      for (var data in trainingData) {
        try {
          _logger.info('Processing sample ID: ${data['id']}');
          var cleanData = _cleanSampleData(data);
          var features = _extractFeatures(GymMembersTracking.fromMap(cleanData));

          if (features.length != _inputSize) {
            throw AIModelException('Feature boyutu tutarsız: Beklenen=$_inputSize, Alınan=${features.length}');
          }

          for (int i = 0; i < _inputSize; i++) {
            _featureMeans[i] += features[i];
          }
        } catch (e) {
          _logger.severe('Error processing sample ${data['id']}: $e');
        }
      }

      _calculateMeanAndStd(trainingData.length);
    } catch (e) {
      _logger.severe('Feature stats initialization failed: $e');
      throw AIModelException('Feature istatistikleri hesaplanamadı: $e');
    }
  }

  Map<String, dynamic> _cleanSampleData(Map<String, dynamic> sample) {
    var cleanData = Map<String, dynamic>.from(sample);
    cleanData.forEach((key, value) {
      if (value is String) {
        cleanData[key] = _parseNumericValue(value, key);
      }
    });
    return cleanData;
  }

  dynamic _parseNumericValue(String value, String field) {
    if (field == 'gender' || field == 'workout_type') return value;

    try {
      return double.parse(value.replaceAll(RegExp(r'[^0-9.-]'), ''));
    } catch (e) {
      _logger.warning('Failed to parse $field: $value. Using default value.');
      return 0.0;
    }
  }

  void _validateNumericField(Map<String, dynamic> sample, String field, num min, num max) {
    try {
      var value = sample[field];
      _logger.info('Validating $field: $value (${value.runtimeType})');

      if (value == null) {
        _logger.severe('$field is null');
        throw AIModelException('$field için eksik değer');
      }

      if (value is String) {
        _logger.info('Converting string value to number for $field');
        value = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
      }

      if (value is! num) {
        _logger.severe('$field is not a number: $value (${value.runtimeType})');
        throw AIModelException('$field sayısal bir değer olmalıdır');
      }

      if (value < min || value > max) {
        _logger.severe('$field out of range: $value (min: $min, max: $max)');
        throw AIModelException('$field değeri $min ile $max arasında olmalıdır');
      }

      sample[field] = value.toDouble();

    } catch (e, stackTrace) {
      _logger.severe('Validation failed for $field');
      _logger.severe('Error: $e');
      _logger.severe('Stack trace: $stackTrace');
      throw AIModelException('$field validasyonu başarısız: $e');
    }
  }



  double _encodeWorkoutType(String? type) {
    if (type == null) return 0.0;
    switch (type.toLowerCase()) {
      case 'strength': return 0.0;
      case 'cardio': return 1.0;
      case 'hiit': return 2.0;
      case 'yoga': return 3.0;
      default: return 0.0;
    }
  }





  void _validateSampleFields(Map<String, dynamic> sample) {
    // Önce string değerleri temizle
    if (sample['height_m'] is String) {
      sample['height_m'] = _cleanStringValue(sample['height_m']);
    }
    if (sample['weight_kg'] is String) {
      sample['weight_kg'] = _cleanStringValue(sample['weight_kg']);
    }
    if (sample['session_duration'] is String) {
      sample['session_duration'] = _cleanStringValue(sample['session_duration']);
    }
    if (sample['workout_frequency'] is String) {
      sample['workout_frequency'] = _cleanStringValue(sample['workout_frequency']);
    }

    // Sonra validasyonları yap
    _validateNumericField(sample, 'height_m', 1.0, 2.5);
    _validateNumericField(sample, 'weight_kg', 30.0, 250.0);
    _validateNumericField(sample, 'session_duration', 0.25, 4.0);
    _validateNumericField(sample, 'workout_frequency', 1, 7);
  }

  double _cleanStringValue(String value) {
    if (value.contains('(')) {
      return 0.0; // Başlık satırı, varsayılan değer döndür
    }
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
  }


  double _parseHeightValue(String value) {
    // "Height (m)" formatını temizle
    String cleanValue = value
        .toLowerCase()
        .replaceAll('height', '')
        .replaceAll('(m)', '')
        .replaceAll(' ', '');

    var parsed = double.tryParse(cleanValue);
    if (parsed == null) {
      // Varsayılan değer ata
      parsed = 1.70; // Ortalama boy değeri
      _logger.warning('height_m için geçersiz değer, varsayılan değer atandı: $parsed');
    }
    return parsed;
  }

  double _parseWeightValue(String value) {
    String cleanValue = value
        .toLowerCase()
        .replaceAll('weight', '')
        .replaceAll('(kg)', '')
        .replaceAll(' ', '');

    var parsed = double.tryParse(cleanValue);
    if (parsed == null) {
      parsed = 70.0; // Ortalama kilo değeri
      _logger.warning('weight_kg için geçersiz değer, varsayılan değer atandı: $parsed');
    }
    return parsed;
  }

  double _parseTimeValue(String value) {
    String cleanValue = value
        .toLowerCase()
        .replaceAll('session_duration', '')
        .replaceAll('(hours)', '')
        .replaceAll(' ', '');

    var parsed = double.tryParse(cleanValue);
    if (parsed == null) {
      parsed = 1.0; // Ortalama seans süresi
      _logger.warning('session_duration için geçersiz değer, varsayılan değer atandı: $parsed');
    }
    return parsed;
  }

  double _parseGenericNumeric(String value) {
    String cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanValue) ?? 0.0;
  }


  void _validateStringField(Map<String, dynamic> sample, String field, List<String> allowedValues) {
    var value = sample[field]?.toString().toLowerCase();
    if (value == null || value.isEmpty) {
      throw AIModelException('Eksik alan: $field');
    }

    // Workout type için tüm değerleri ekle
    final workoutTypes = ['yoga', 'hiit', 'strength', 'cardio'];
    if (field == 'workout_type' && !workoutTypes.contains(value)) {
      throw AIModelException('Geçersiz workout_type değeri: $value. İzin verilen değerler: $workoutTypes');
    }

    if (!allowedValues.contains(value)) {
      throw AIModelException('Geçersiz $field değeri: $value. İzin verilen değerler: $allowedValues');
    }
  }

  void _validateDependentFields(Map<String, dynamic> sample) {
    // BMI kontrolü - tolerans eklenmiş
    final double tolerance = 0.5;
    double calculatedBMI = _calculateBMI(
        sample['weight_kg'],
        sample['height_m']
    );

    if ((sample['bmi'] - calculatedBMI).abs() > tolerance) {
      throw AIModelException(
          'BMI tutarsız: Hesaplanan=${calculatedBMI.toStringAsFixed(2)}, '
              'Verilen=${sample['bmi'].toStringAsFixed(2)}'
      );
    }

    // Nabız kontrolleri
  }


  // Ortalama ve standart sapma hesaplama metodu
  void _calculateMeanAndStd(int sampleSize) {
    try {
      // Ortalama hesaplama
      for (int i = 0; i < _inputSize; i++) {
        _featureMeans[i] /= sampleSize;
      }

      // Standart sapma hesaplama
      for (int i = 0; i < _inputSize; i++) {
        double sumSquaredDiff = 0.0;
        for (var individual in population) {
          sumSquaredDiff += pow(individual[i] - _featureMeans[i], 2);
        }
        _featureStds[i] = sqrt(sumSquaredDiff / sampleSize);

        // Sıfır bölme hatasını önle
        if (_featureStds[i] < 1e-10) {
          _featureStds[i] = 1.0;
        }
      }
    } catch (e) {
      throw AIModelException('Mean and std calculation failed: $e');
    }
  }

// BMI hesaplama metodu
  double _calculateBMI(double weightKg, double heightM) {
    if (heightM <= 0 || weightKg <= 0) {
      throw AIModelException('Invalid height or weight values');
    }

    try {
      return weightKg / (heightM * heightM);
    } catch (e) {
      throw AIModelException('BMI calculation failed: $e');
    }
  }

// BMI değerine göre kategori belirleme
  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

// BMI uyumluluğunu hesaplama
  double _calculateBMICompatibility(double userBMI, String targetBMICase) {
    final userCategory = _getBMICategory(userBMI);
    if (userCategory == targetBMICase) return 1.0;

    // Komşu kategoriler için kısmi uyumluluk
    final categories = ['Underweight', 'Normal', 'Overweight', 'Obese'];
    final userIndex = categories.indexOf(userCategory);
    final targetIndex = categories.indexOf(targetBMICase);

    return 1.0 - (userIndex - targetIndex).abs() * 0.25;
  }


  @override
  Future<void> fit(List<Map<String, dynamic>> trainingData) async {
    try {
      if (_modelState != AGDEModelState.initialized) {
        throw AIModelException('Model must be initialized before training');
      }

      _modelState = AGDEModelState.training;
      int generation = 0;

      // İlk fitness değerlerini hesapla
      await _evaluateInitialPopulation(trainingData);

      while (!_shouldStopTraining(generation)) {
        if (_isPaused) {
          await Future.delayed(Duration(milliseconds: 100));
          continue;
        }

        if (_shouldStop) {
          break;
        }

        // Her birey için evrim
        for (int i = 0; i < populationSize; i++) {
          // Rastgele üç birey seç (r1 ≠ r2 ≠ r3 ≠ i)
          var selectedIndices = _selectRandomIndividuals(i);

          // Mutasyon
          var mutant = _mutation(
              population[selectedIndices.$1],
              population[selectedIndices.$2],
              population[selectedIndices.$3]
          );

          // Çaprazlama
          var trial = _crossover(population[i], mutant);

          // Seçim
          double trialFitness = await _calculateFitness(trial, trainingData);
          if (trialFitness > fitnessValues[i]) {
            population[i] = trial;
            fitnessValues[i] = trialFitness;
            _previousFitnessValues[i] = fitnessValues[i];
          }
        }

        // Adaptif parametreleri güncelle
        _updateAdaptiveParameters(generation);

        // Metrik güncelleme
        final metrics = await _calculateGenerationMetrics(trainingData);
        updateMetrics(metrics);

        // İlerleme bildirimi
        _notifyProgress(generation);

        generation++;
      }

      _modelState = AGDEModelState.trained;
      _logger.info('Training completed after $generation generations');

    } catch (e) {
      _modelState = AGDEModelState.error;
      throw AIModelException('Training failed: $e');
    }
  }

// Evrim operatörleri
  List<double> _mutation(List<double> r1, List<double> r2, List<double> r3) {
    return List.generate(r1.length,
            (i) => r1[i] + adaptiveMutationRate * (r2[i] - r3[i]));
  }

  List<double> _crossover(List<double> target, List<double> donor) {
    final random = Random();
    final jRand = random.nextInt(_inputSize);

    return List.generate(_inputSize, (i) {
      if (random.nextDouble() < adaptiveCrossoverRate || i == jRand) {
        return donor[i];
      }
      return target[i];
    });
  }

  (int, int, int) _selectRandomIndividuals(int current) {
    final random = Random();
    final available = List<int>.generate(populationSize, (i) => i)
      ..removeAt(current);
    available.shuffle(random);
    return (available[0], available[1], available[2]);
  }

  Future<void> _evaluateInitialPopulation(List<Map<String, dynamic>> trainingData) async {
    for (int i = 0; i < populationSize; i++) {
      fitnessValues[i] = await _calculateFitness(population[i], trainingData);
      _previousFitnessValues[i] = fitnessValues[i];
    }
  }

  void _updateAdaptiveParameters(int generation) {
    final successRate = _calculateSuccessRate();

    // Başarı oranına göre parametre adaptasyonu
    adaptiveMutationRate *= (successRate > 0.2) ? 1.1 : 0.9;
    adaptiveCrossoverRate *= (successRate > 0.2) ? 0.9 : 1.1;

    // Sınırlar içinde tut
    adaptiveMutationRate = adaptiveMutationRate.clamp(0.1, 0.9);
    adaptiveCrossoverRate = adaptiveCrossoverRate.clamp(0.1, 0.9);
  }

  double _calculateSuccessRate() {
    int successCount = 0;
    for (int i = 0; i < populationSize; i++) {
      if (fitnessValues[i] > _previousFitnessValues[i]) {
        successCount++;
      }
    }
    return successCount / populationSize;
  }

  @override
  Future<FinalDataset> predict(GymMembersTracking input) async {
    try {
      if (_modelState != AGDEModelState.trained) {
        throw AIModelException('Model must be trained before prediction');
      }

      _modelState = AGDEModelState.predicting;
      final features = _extractFeatures(input);
      final normalizedFeatures = _normalizeFeatures(features);

      // En iyi bireyi kullanarak tahmin yap
      int bestIndividualIndex = _getBestIndividualIndex();
      final prediction = _predictWithIndividual(population[bestIndividualIndex], normalizedFeatures);

      _modelState = AGDEModelState.trained;

      return FinalDataset(
          id: 0,
          weight: input.weightKg,
          height: input.heightM,
          bmi: input.bmi,
          gender: input.gender,
          age: input.age,
          bmiCase: _getBMICase(input.bmi),
          exercisePlan: _getPlanFromPrediction(prediction)
      );
    } catch (e) {
      _modelState = AGDEModelState.error;
      throw AIModelException('Prediction failed: $e');
    }
  }

  @override
  Future<Map<String, double>> analyzeFit(int programId, GymMembersTracking profile) async {
    try {
      final prediction = await predict(profile);

      return {
        'program_match': _calculateProgramMatch(programId, prediction.exercisePlan),
        'fitness_level_match': _calculateFitnessMatch(profile.experienceLevel, prediction.exercisePlan),
        'bmi_compatibility': _calculateBMICompatibility(profile.bmi, prediction.bmiCase),
        'confidence_score': await calculateConfidence(profile, prediction)
      };
    } catch (e) {
      throw AIModelException('Fit analysis failed: $e');
    }
  }

  @override
  Future<Map<String, double>> analyzeProgress(List<GymMembersTracking> userData) async {
    if (userData.length < 2) {
      throw AIModelException('Insufficient data for progress analysis');
    }

    try {
      final first = userData.first;
      final last = userData.last;

      return {
        'bmi_change': (last.bmi - first.bmi) / first.bmi,
        'strength_improvement': _calculateStrengthImprovement(userData),
        'endurance_improvement': _calculateEnduranceImprovement(userData),
        'consistency_score': _calculateConsistencyScore(userData)
      };
    } catch (e) {
      throw AIModelException('Progress analysis failed: $e');
    }
  }

  @override
  Future<Map<String, double>> calculateMetrics(List<Map<String, dynamic>> testData) async {
    try {
      double accuracy = 0.0;
      double precision = 0.0;
      double recall = 0.0;

      for (var data in testData) {
        final actual = GymMembersTracking.fromMap(data);
        final predicted = await predict(actual);

        accuracy += predicted.exercisePlan == actual.experienceLevel ? 1.0 : 0.0;
        precision += _calculatePrecision(predicted.exercisePlan, actual.experienceLevel);
        recall += _calculateRecall(predicted.exercisePlan, actual.experienceLevel);
      }

      final n = testData.length.toDouble();
      return {
        'accuracy': accuracy / n,
        'precision': precision / n,
        'recall': recall / n,
        'f1_score': 2 * (precision * recall) / (precision + recall) / n
      };
    } catch (e) {
      throw AIModelException('Metrics calculation failed: $e');
    }
  }

  @override
  Future<double> calculateConfidence(GymMembersTracking input, FinalDataset prediction) async {
    try {
      final features = _extractFeatures(input);
      final normalizedFeatures = _normalizeFeatures(features);

      double confidenceSum = 0.0;
      for (var individual in population) {
        final individualPrediction = _predictWithIndividual(individual, normalizedFeatures);
        confidenceSum += _calculatePredictionConfidence(individualPrediction, prediction.exercisePlan);
      }

      return confidenceSum / populationSize;
    } catch (e) {
      throw AIModelException('Confidence calculation failed: $e');
    }
  }

// Yardımcı hesaplama metodları

  List<double> _normalizeFeatures(List<double> features) {
    List<double> normalized = List.filled(_inputSize, 0.0);
    for (int i = 0; i < _inputSize; i++) {
      normalized[i] = (features[i] - _featureMeans[i]) / _featureStds[i];
    }
    return normalized;
  }

  Future<double> _calculateFitness(List<double> individual, List<Map<String, dynamic>> trainingData) async {
    double totalError = 0.0;
    int correctPredictions = 0;

    for (var data in trainingData) {
      var sample = GymMembersTracking.fromMap(data);
      var features = _extractFeatures(sample);
      var normalizedFeatures = _normalizeFeatures(features);
      var prediction = _predictWithIndividual(individual, normalizedFeatures);

      // Tahmin doğruluğunu kontrol et
      if (_getPlanFromPrediction(prediction) == sample.experienceLevel) {
        correctPredictions++;
      }

      totalError += _calculatePredictionError(prediction, sample.experienceLevel);
    }

    double accuracy = correctPredictions / trainingData.length;
    double fitnessScore = 1.0 / (1.0 + totalError) * accuracy;

    return fitnessScore;
  }

  double _calculatePredictionError(List<double> prediction, int actualLevel) {
    int predictedLevel = _getPlanFromPrediction(prediction);
    return pow(predictedLevel - actualLevel, 2).toDouble();
  }

  int _getPlanFromPrediction(List<double> prediction) {
    int maxIndex = 0;
    double maxValue = prediction[0];

    for (int i = 1; i < prediction.length; i++) {
      if (prediction[i] > maxValue) {
        maxValue = prediction[i];
        maxIndex = i;
      }
    }

    return maxIndex + 1; // 1-7 arası plan seviyesi
  }

  double _calculateStrengthImprovement(List<GymMembersTracking> userData) {
    if (userData.length < 2) return 0.0;

    var first = userData.first;
    var last = userData.last;

    double strengthGain = (last.experienceLevel - first.experienceLevel) /
        max(first.experienceLevel, 1);

    return strengthGain.clamp(0.0, 1.0);
  }

  double _calculateEnduranceImprovement(List<GymMembersTracking> userData) {
    if (userData.length < 2) return 0.0;

    var first = userData.first;
    var last = userData.last;

    double bpmImprovement = (first.avgBpm - last.avgBpm) / first.avgBpm;
    double durationImprovement = (last.sessionDuration - first.sessionDuration) /
        first.sessionDuration;

    return ((bpmImprovement + durationImprovement) / 2).clamp(0.0, 1.0);
  }

  double _calculateConsistencyScore(List<GymMembersTracking> userData) {
    if (userData.length < 2) return 0.0;

    int consecutiveWorkouts = 0;
    int maxConsecutiveWorkouts = 0;

    for (int i = 1; i < userData.length; i++) {
      if (userData[i].sessionDuration > 0) {
        consecutiveWorkouts++;
        maxConsecutiveWorkouts = max(maxConsecutiveWorkouts, consecutiveWorkouts);
      } else {
        consecutiveWorkouts = 0;
      }
    }

    return (maxConsecutiveWorkouts / AIConstants.MAX_PROCESSING_HISTORY)
        .clamp(0.0, 1.0);
  }


  @override
  Future<Map<String, dynamic>> getPredictionMetadata(GymMembersTracking input) async {
    return {
      'confidence': await calculateConfidence(input, await predict(input)),
      'model_state': _modelState.toString(),
      'feature_importance': _calculateFeatureImportance(input),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<bool> validateData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      throw AIModelException('Empty dataset provided');
    }

    try {
      for (var sample in data) {
        if (!_validateSample(sample)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      _logger.severe('Data validation failed: $e');
      return false;
    }
  }

  bool _shouldStopTraining(int generation) {
    return generation >= maxGenerations ||
        _checkConvergence() ||
        _shouldStop;
  }

  Future<Map<String, double>> _calculateGenerationMetrics(List<Map<String, dynamic>> trainingData) async {
    return {
      'best_fitness': fitnessValues.reduce(max),
      'avg_fitness': fitnessValues.reduce((a, b) => a + b) / populationSize,
      'mutation_rate': adaptiveMutationRate,
      'crossover_rate': adaptiveCrossoverRate
    };
  }

  void _notifyProgress(int generation) {
    _trainingProgressController.add(
        TrainingProgress(
            generation: generation,
            bestFitness: fitnessValues.reduce(max),
            avgFitness: fitnessValues.reduce((a, b) => a + b) / populationSize,
            metrics: getMetrics(),
            state: _modelState
        )
    );
  }

  int _getBestIndividualIndex() {
    int bestIndex = 0;
    double bestFitness = fitnessValues[0];

    for (int i = 1; i < populationSize; i++) {
      if (fitnessValues[i] > bestFitness) {
        bestFitness = fitnessValues[i];
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  String _getBMICase(double bmi) {
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25.0) return 'normal';
    if (bmi < 30.0) return 'overweight';
    return 'obese';
  }

  double _calculateProgramMatch(int programId, int predictedPlan) {
    return 1.0 - (programId - predictedPlan).abs() / 6.0;
  }

  double _calculateFitnessMatch(int actualLevel, int predictedLevel) {
    return 1.0 - (actualLevel - predictedLevel).abs() / 6.0;
  }



  double _calculatePrecision(int predicted, int actual) {
    return predicted == actual ? 1.0 : 0.0;
  }

  double _calculateRecall(int predicted, int actual) {
    return predicted == actual ? 1.0 : 0.0;
  }

  double _calculatePredictionConfidence(List<double> prediction, int exercisePlan) {
    return prediction[exercisePlan - 1];
  }

  Map<String, double> _calculateFeatureImportance(GymMembersTracking input) {
    return {
      'weight': 0.2,
      'height': 0.15,
      'bmi': 0.25,
      'age': 0.15,
      'experience': 0.25
    };
  }

  bool _validateSample(Map sample) {
    final requiredFields = [
      'age',
      'gender',
      'weight_kg',
      'height_m',
      'max_bpm',
      'avg_bpm',
      'resting_bpm',
      'session_duration',
      'calories_burned',
      'workout_type',
      'fat_percentage',
      'water_intake',
      'workout_frequency',
      'experience_level',
      'bmi'
    ];

    return requiredFields.every((field) =>
    sample.containsKey(field) && sample[field] != null);
  }


// Model serializasyonu ve durum yönetimi
  @override
  Map<String, dynamic> toJson() {
    return {
      'model_state': _modelState.toString(),
      'population': population,
      'fitness_values': fitnessValues,
      'feature_means': _featureMeans,
      'feature_stds': _featureStds,
      'adaptive_mutation_rate': adaptiveMutationRate,
      'adaptive_crossover_rate': adaptiveCrossoverRate,
      'training_history': _trainingHistory,
      'metrics': getMetrics(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<void> fromJson(Map<String, dynamic> json) async {
    try {
      if (json.containsKey('population')) {
        population = (json['population'] as List).map((individual) =>
            (individual as List).map((value) => value as double).toList()
        ).toList();
      }

      if (json.containsKey('fitness_values')) {
        fitnessValues = (json['fitness_values'] as List).map((v) => v as double).toList();
      }

      if (json.containsKey('feature_means')) {
        _featureMeans = (json['feature_means'] as List).map((v) => v as double).toList();
      }

      if (json.containsKey('feature_stds')) {
        _featureStds = (json['feature_stds'] as List).map((v) => v as double).toList();
      }

      adaptiveMutationRate = json['adaptive_mutation_rate'] as double;
      adaptiveCrossoverRate = json['adaptive_crossover_rate'] as double;

      _modelState = AGDEModelState.trained;
      _logger.info('Model loaded successfully');
    } catch (e) {
      _modelState = AGDEModelState.error;
      throw AIModelException('Error loading model: $e');
    }
  }

  List<double> _predictWithIndividual(List<double> individual, List<double> features) {
    double sum = 0.0;
    for (int i = 0; i < features.length; i++) {
      sum += features[i] * individual[i];
    }
    return _softmax([sum]);
  }

  List<double> _softmax(List<double> x) {
    var exp = x.map((e) => pow(e, 2.71828)).toList();
    var sum = exp.reduce((a, b) => a + b);
    return exp.map((e) => e / sum).toList();
  }

  bool _checkConvergence() {
    if (_trainingHistory['fitness']!.length < AIConstants.EARLY_STOPPING_PATIENCE) {
      return false;
    }

    var recentFitness = _trainingHistory['fitness']!
        .sublist(_trainingHistory['fitness']!.length - AIConstants.EARLY_STOPPING_PATIENCE);

    double maxDiff = 0.0;
    for (int i = 1; i < recentFitness.length; i++) {
      maxDiff = max(maxDiff, (recentFitness[i] - recentFitness[i-1]).abs());
    }

    return maxDiff < AIConstants.EARLY_STOPPING_THRESHOLD;
  }

  String getModelSummary() {
    return '''
    AGDE Model Summary:
    - State: $_modelState
    - Population Size: $populationSize
    - Input Size: $_inputSize
    - Output Size: $_outputSize
    - Current Mutation Rate: ${adaptiveMutationRate.toStringAsFixed(4)}
    - Current Crossover Rate: ${adaptiveCrossoverRate.toStringAsFixed(4)}
    - Best Fitness: ${fitnessValues.reduce(max).toStringAsFixed(4)}
    - Training History Length: ${_trainingHistory['fitness']?.length ?? 0}
  ''';
  }

}
