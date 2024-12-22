import 'dart:math';
import 'package:logging/logging.dart';
import '../ai_data_bloc/ai_state.dart';
import '../ai_data_bloc/datasets_models.dart';
import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import 'base_model.dart';

enum KNNModelState {
  uninitialized,
  initializing,
  initialized,
  training,
  trained,
  predicting,
  error
}

class KNNModel extends BaseModel {
  final _logger = Logger('KNNModel');
  KNNModelState _modelState = KNNModelState.uninitialized;

  // Model Parametreleri
  final List<int> kValues = [1, 3, 5, 7, 9, 11, 13, 15];
  late int bestK;
  late List<List<double>> _normalizedFeatures;
  late List<int> _labels;

  // Özellik istatistikleri
  late List<double> _featureMeans;
  late List<double> _featureStds;

  // Model boyutları
  late final int _inputSize;
  late final int _numClasses;


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

      // Deneyim seviyelerinin geçerli aralıkta olup olmadığını kontrol et
      for (var sample in data) {
        var experienceLevel = GymMembersTracking.fromMap(sample).experienceLevel;
        if (experienceLevel < 1 || experienceLevel > _numClasses) {
          _logger.warning('Invalid experience level: $experienceLevel');
          return false;
        }
      }

      return true;
    } catch (e) {
      _logger.severe('Data validation failed: $e');
      return false;
    }
  }

  bool _validateSample(Map<String, dynamic> sample) {
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

    try {
      // Tüm gerekli alanların var olup olmadığını kontrol et
      if (!requiredFields.every((field) => sample.containsKey(field))) {
        return false;
      }

      // Sayısal değerlerin geçerliliğini kontrol et
      if (sample['age'] < 0 ||
          sample['weight_kg'] <= 0 ||
          sample['height_m'] <= 0 ||
          sample['experience_level'] < 1 ||
          sample['experience_level'] > _numClasses) {
        return false;
      }

      // Gender alanının geçerliliğini kontrol et
      if (!['male', 'female'].contains(sample['gender'])) {
        return false;
      }

      return true;
    } catch (e) {
      _logger.warning('Sample validation failed: $e');
      return false;
    }
  }



  @override
  Future<void> setup(List<Map<String, dynamic>> trainingData) async {
    try {
      _modelState = KNNModelState.initializing;

      if (!await validateData(trainingData)) {
        throw AIModelException('Invalid training data');
      }

      _inputSize = _calculateInputSize();
      _numClasses = 7; // Experience level 1-7 arası

      await _initializeFeatureStats(trainingData);
      await _prepareTrainingData(trainingData);

      _modelState = KNNModelState.initialized;
      _logger.info('KNN model setup completed');
    } catch (e) {
      _modelState = KNNModelState.error;
      throw AIModelException('KNN model setup failed: $e');
    }
  }

  Future<void> _initializeFeatureStats(List<Map<String, dynamic>> trainingData) async {
    _featureMeans = List.filled(_inputSize, 0.0);
    _featureStds = List.filled(_inputSize, 0.0);

    for (var data in trainingData) {
      var features = _extractFeatures(GymMembersTracking.fromMap(data));
      for (int i = 0; i < _inputSize; i++) {
        _featureMeans[i] += features[i];
      }
    }

    // Ortalama hesaplama
    for (int i = 0; i < _inputSize; i++) {
      _featureMeans[i] /= trainingData.length;
    }

    // Standart sapma hesaplama
    for (var data in trainingData) {
      var features = _extractFeatures(GymMembersTracking.fromMap(data));
      for (int i = 0; i < _inputSize; i++) {
        _featureStds[i] += pow(features[i] - _featureMeans[i], 2);
      }
    }

    for (int i = 0; i < _inputSize; i++) {
      _featureStds[i] = sqrt(_featureStds[i] / trainingData.length);
      if (_featureStds[i] == 0) _featureStds[i] = 1.0;
    }
  }

  List<double> _extractFeatures(GymMembersTracking sample) {
    return [
      sample.age.toDouble(),
      sample.gender == 'male' ? 1.0 : 0.0,
      sample.weightKg,
      sample.heightM,
      sample.bmi,
      sample.maxBpm.toDouble(),
      sample.avgBpm.toDouble(),
      sample.restingBpm.toDouble(),
      sample.sessionDuration,
      sample.caloriesBurned,
      sample.fatPercentage,
      sample.waterIntake,
      sample.workoutFrequency.toDouble(),
      sample.workoutType == 'strength' ? 1.0 : 0.0
    ];
  }

  int _calculateInputSize() {
    return 14; // Toplam özellik sayısı
  }

  @override
  Future<void> fit(List<Map<String, dynamic>> trainingData) async {
    try {
      _modelState = KNNModelState.training;
      AIStateManager().updateModelState(AIModelState.training);

      await _prepareTrainingData(trainingData);
      await _optimizeK();

      _modelState = KNNModelState.trained;
      AIStateManager().updateModelState(AIModelState.initialized);
      _logger.info('KNN model training completed');
    } catch (e) {
      _modelState = KNNModelState.error;
      AIStateManager().handleError(AIError('KNN model training failed: $e', type: AIErrorType.training));
      throw AIModelException('KNN model training failed: $e');
    }
  }

  Future<void> _prepareTrainingData(List<Map<String, dynamic>> trainingData) async {
    _normalizedFeatures = [];
    _labels = [];

    for (var data in trainingData) {
      var sample = GymMembersTracking.fromMap(data);
      var features = _extractFeatures(sample);
      var normalizedFeatures = _normalizeFeatures(features);
      _normalizedFeatures.add(normalizedFeatures);
      _labels.add(sample.experienceLevel);
    }
  }

  List<double> _normalizeFeatures(List<double> features) {
    return List.generate(_inputSize, (i) =>
    (features[i] - _featureMeans[i]) / _featureStds[i]);
  }

  Future<void> _optimizeK() async {
    double bestAccuracy = 0.0;
    for (var k in kValues) {
      double accuracy = await _crossValidate(k);
      if (accuracy > bestAccuracy) {
        bestAccuracy = accuracy;
        bestK = k;
      }
      AIStateManager().updateProgress(k / kValues.last);
    }
    _logger.info('Best K value: $bestK with accuracy: ${bestAccuracy.toStringAsFixed(4)}');
  }

  Future<double> _crossValidate(int k) async {
    const int folds = 5;
    int foldSize = _normalizedFeatures.length ~/ folds;
    double totalAccuracy = 0.0;

    for (int i = 0; i < folds; i++) {
      var testStart = i * foldSize;
      var testEnd = (i + 1) * foldSize;

      var testFeatures = _normalizedFeatures.sublist(testStart, testEnd);
      var testLabels = _labels.sublist(testStart, testEnd);

      var trainFeatures = [
        ..._normalizedFeatures.sublist(0, testStart),
        ..._normalizedFeatures.sublist(testEnd)
      ];
      var trainLabels = [
        ..._labels.sublist(0, testStart),
        ..._labels.sublist(testEnd)
      ];

      int correctPredictions = 0;
      for (int j = 0; j < testFeatures.length; j++) {
        int prediction = _predict(testFeatures[j], trainFeatures, trainLabels, k);
        if (prediction == testLabels[j]) {
          correctPredictions++;
        }
      }
      totalAccuracy += correctPredictions / testFeatures.length;
    }

    return totalAccuracy / folds;
  }

  int _predict(List<double> input, List<List<double>> features, List<int> labels, int k) {
    var distances = List.generate(features.length, (i) =>
        MapEntry(i, _calculateDistance(input, features[i])));

    distances.sort((a, b) => a.value.compareTo(b.value));
    var nearestNeighbors = distances.take(k).map((e) => labels[e.key]).toList();

    return _getMostFrequent(nearestNeighbors);
  }

  double _calculateDistance(List<double> a, List<double> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += pow(a[i] - b[i], 2);
    }
    return sqrt(sum);
  }

  int _getMostFrequent(List<int> list) {
    var counts = <int, int>{};
    for (var element in list) {
      counts[element] = (counts[element] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  Future<FinalDataset> predict(GymMembersTracking input) async {
    try {
      if (_modelState != KNNModelState.trained) {
        throw AIModelException('Model must be trained before prediction');
      }

      _modelState = KNNModelState.predicting;

      final features = _extractFeatures(input);
      final normalizedFeatures = _normalizeFeatures(features);

      final predictedLevel = _predict(
          normalizedFeatures,
          _normalizedFeatures,
          _labels,
          bestK
      );

      _modelState = KNNModelState.trained;

      return FinalDataset(
          id: 0,
          weight: input.weightKg,
          height: input.heightM,
          bmi: input.bmi,
          gender: input.gender,
          age: input.age,
          bmiCase: _getBMICase(input.bmi),
          exercisePlan: predictedLevel
      );
    } catch (e) {
      _modelState = KNNModelState.error;
      throw AIModelException('Prediction failed: $e');
    }
  }

  @override
  Future<Map<String, double>> analyzeFit(int programId, GymMembersTracking profile) async {
    try {
      final prediction = await predict(profile);

      return {
        'program_match': _calculateProgramMatch(programId, prediction.exercisePlan),
        'level_match': _calculateLevelMatch(profile.experienceLevel, prediction.exercisePlan),
        'bmi_compatibility': _calculateBMICompatibility(profile.bmi, prediction.bmiCase),
        'confidence': await calculateConfidence(profile, prediction)
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
        'level_improvement': (last.experienceLevel - first.experienceLevel) / 6.0,
        'bmi_change': (last.bmi - first.bmi) / first.bmi,
        'endurance_improvement': _calculateEnduranceImprovement(first, last),
        'consistency_score': _calculateConsistencyScore(userData)
      };
    } catch (e) {
      throw AIModelException('Progress analysis failed: $e');
    }
  }

  @override
  Future<Map<String, double>> calculateMetrics(List<Map<String, dynamic>> testData) async {
    try {
      int correctPredictions = 0;
      double totalError = 0.0;

      for (var data in testData) {
        final actual = GymMembersTracking.fromMap(data);
        final predicted = await predict(actual);

        if (predicted.exercisePlan == actual.experienceLevel) {
          correctPredictions++;
        }
        totalError += (predicted.exercisePlan - actual.experienceLevel).abs();
      }

      final accuracy = correctPredictions / testData.length;
      final mae = totalError / testData.length;

      return {
        'accuracy': accuracy,
        'mae': mae,
        'k_value': bestK.toDouble()
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

      // En yakın k komşunun uzaklıklarını hesapla
      var distances = List.generate(_normalizedFeatures.length, (i) =>
          MapEntry(i, _calculateDistance(normalizedFeatures, _normalizedFeatures[i])));

      distances.sort((a, b) => a.value.compareTo(b.value));
      var kNearest = distances.take(bestK);

      // Uzaklığa dayalı güven skoru hesapla
      double confidence = kNearest.where((e) =>
      _labels[e.key] == prediction.exercisePlan).length / bestK;

      return confidence;
    } catch (e) {
      throw AIModelException('Confidence calculation failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getPredictionMetadata(GymMembersTracking input) async {
    final prediction = await predict(input);
    final confidence = await calculateConfidence(input, prediction);

    return {
      'k_value': bestK,
      'confidence': confidence,
      'model_state': _modelState.toString(),
      'nearest_neighbors': await _getNearestNeighborsInfo(input),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> _getNearestNeighborsInfo(GymMembersTracking input) async {
    final features = _extractFeatures(input);
    final normalizedFeatures = _normalizeFeatures(features);

    var distances = List.generate(_normalizedFeatures.length, (i) =>
        MapEntry(i, _calculateDistance(normalizedFeatures, _normalizedFeatures[i])));

    distances.sort((a, b) => a.value.compareTo(b.value));

    return distances.take(bestK).map((e) => {
      'distance': e.value,
      'label': _labels[e.key],
    }).toList();
  }

  double _calculateBMICompatibility(double bmi, String bmiCase) {
    final targetBMI = {
      'underweight': 18.5,
      'normal': 22.0,
      'overweight': 27.0,
      'obese': 30.0
    }[bmiCase] ?? 22.0;

    return 1.0 - (bmi - targetBMI).abs() / 10.0;
  }

  double _calculateEnduranceImprovement(
      GymMembersTracking first,
      GymMembersTracking last
      ) {
    double bpmImprovement = (first.avgBpm - last.avgBpm) / first.avgBpm;
    double durationImprovement = (last.sessionDuration - first.sessionDuration) /
        first.sessionDuration;

    return ((bpmImprovement + durationImprovement) / 2).clamp(0.0, 1.0);
  }

  double _calculateConsistencyScore(List<GymMembersTracking> userData) {
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

    return (maxConsecutiveWorkouts / userData.length).clamp(0.0, 1.0);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'model_state': _modelState.toString(),
      'best_k': bestK,
      'feature_means': _featureMeans,
      'feature_stds': _featureStds,
      'normalized_features': _normalizedFeatures,
      'labels': _labels,
      'metrics': getMetrics(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<void> fromJson(Map<String, dynamic> json) async {
    try {
      bestK = json['best_k'] as int;

      _featureMeans = (json['feature_means'] as List)
          .map((e) => e as double)
          .toList();

      _featureStds = (json['feature_stds'] as List)
          .map((e) => e as double)
          .toList();

      _normalizedFeatures = (json['normalized_features'] as List)
          .map((list) => (list as List).map((e) => e as double).toList())
          .toList();

      _labels = (json['labels'] as List)
          .map((e) => e as int)
          .toList();

      if (json.containsKey('metrics')) {
        updateMetrics(json['metrics'] as Map<String, double>);
      }

      _modelState = KNNModelState.trained;
      _logger.info('KNN model loaded from JSON successfully');
    } catch (e) {
      _modelState = KNNModelState.error;
      throw AIModelException('Error loading KNN model from JSON: $e');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      _normalizedFeatures.clear();
      _labels.clear();
      _featureMeans.clear();
      _featureStds.clear();
      _modelState = KNNModelState.uninitialized;
      _logger.info('KNN model resources released');
    } catch (e) {
      _logger.severe('Error during KNN model disposal: $e');
      throw AIModelException('KNN model disposal failed: $e');
    }
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

  double _calculateLevelMatch(int actualLevel, int predictedLevel) {
    return 1.0 - (actualLevel - predictedLevel).abs() / 6.0;
  }

}
