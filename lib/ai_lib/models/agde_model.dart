import 'dart:math';
import 'package:logging/logging.dart';
import '../ai_data_bloc/datasets_models.dart';
import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import '../core/ai_data_processor.dart';
import 'base_model.dart';

enum AGDEModelState { uninitialized,
  initializing,
  initialized,
  training,
  trained,
  predicting,
  error }

class AGDEModel extends BaseModel {
  final _logger = Logger('AGDEModel');

  AGDEModelState _modelState = AGDEModelState.uninitialized;
  AGDEModelState get modelState => _modelState;

  // Model parametreleri
  late List<List<double>> _weights;
  late List<double> _biases;
  final double _learningRate = AIConstants.LEARNING_RATE;

  // Ensemble parametreleri
  final int _numEnsemble = 3;
  final List<List<List<double>>> _ensembleWeights = [];
  final List<List<double>> _ensembleBiases = [];

  // Katman boyutları
  late final int _inputSize;
  late final int _hiddenSize;
  late final int _outputSize;

  // Adam optimizer parametreleri
  final double _beta1 = 0.9;
  final double _beta2 = 0.999;
  final double _epsilon = 1e-8;

  late List<List<double>> _mWeights;
  late List<List<double>> _vWeights;

  final Map<String, List<double>> _trainingHistory = {
    'loss': [],
    'accuracy': [],
    'precision': [],
    'recall': [],
    'f1_score': [],
  };
  static const int MAX_HISTORY_SIZE = 1000;

  void _updateState(AGDEModelState newState) {
    if (_modelState == AGDEModelState.error && newState != AGDEModelState.uninitialized) {
      throw AIException('Cannot transition from error state');
    }
    _modelState = newState;
  }

  @override
  Future<Map<String, double>> calculateMetrics(List testData) async {
    if (testData.isEmpty) throw AIException('Empty test data');

    final typedData = testData.cast<GymMembersTracking>();
    final predictions = await Future.wait(typedData.map((sample) => predict(sample)));

    return {
      'accuracy': _calculateAccuracy(predictions, typedData),
      'precision': _calculatePrecision(predictions, typedData),
      'recall': _calculateRecall(predictions, typedData),
      'f1_score': _calculateF1Score(predictions, typedData)
    };
  }

  double _calculateAccuracy(List predictions, List actual) {
    int correct = 0;
    for (var i = 0; i < predictions.length; i++) {
      if (predictions[i].exercisePlan == actual[i].experienceLevel) {
        correct++;
      }
    }
    return correct / predictions.length;
  }


  double _calculatePrecision(List<FinalDataset> predictions, List<GymMembersTracking> actual) {
    Map<int, Map<String, int>> metrics = {};

    for (var i = 0; i < predictions.length; i++) {
      final predicted = predictions[i].exercisePlan;
      final actualLabel = actual[i].experienceLevel;

      metrics.putIfAbsent(predicted, () => {'tp': 0, 'fp': 0});

      if (predicted == actualLabel) {
        metrics[predicted]!['tp'] = metrics[predicted]!['tp']! + 1;
      } else {
        metrics[predicted]!['fp'] = metrics[predicted]!['fp']! + 1;
      }
    }

    double totalPrecision = 0.0;
    int classCount = 0;

    metrics.forEach((key, value) {
      final tp = value['tp']!;
      final fp = value['fp']!;
      if (tp + fp > 0) {
        totalPrecision += tp / (tp + fp);
        classCount++;
      }
    });

    return classCount > 0 ? totalPrecision / classCount : 0.0;
  }

  double _calculateRecall(List<FinalDataset> predictions, List<GymMembersTracking> actual) {
    Map<int, Map<String, int>> metrics = {};

    for (var i = 0; i < predictions.length; i++) {
      final predicted = predictions[i].exercisePlan;
      final actualLabel = actual[i].experienceLevel;

      metrics.putIfAbsent(actualLabel, () => {'tp': 0, 'fn': 0});

      if (predicted == actualLabel) {
        metrics[actualLabel]!['tp'] = metrics[actualLabel]!['tp']! + 1;
      } else {
        metrics[actualLabel]!['fn'] = metrics[actualLabel]!['fn']! + 1;
      }
    }

    double totalRecall = 0.0;
    int classCount = 0;

    metrics.forEach((key, value) {
      final tp = value['tp']!;
      final fn = value['fn']!;
      if (tp + fn > 0) {
        totalRecall += tp / (tp + fn);
        classCount++;
      }
    });

    return classCount > 0 ? totalRecall / classCount : 0.0;
  }

  double _calculateF1Score(List<FinalDataset> predictions, List<GymMembersTracking> actual) {
    final precision = _calculatePrecision(predictions, actual);
    final recall = _calculateRecall(predictions, actual);
    return (precision + recall) > 0 ? 2 * (precision * recall) / (precision + recall) : 0.0;
  }

  @override
  Future<void> setup(List<dynamic> trainingData) async {
    try {
      _modelState = AGDEModelState.initializing;
      await validateData(trainingData);

      final typedData = trainingData.cast<GymMembersTracking>();
      _inputSize = _calculateInputSize(typedData.first);
      _hiddenSize = AIConstants.HIDDEN_LAYER_UNITS;
      _outputSize = AIConstants.OUTPUT_CLASSES;

      for (var i = 0; i < _numEnsemble; i++) {
        _initializeModel();
      }

      _modelState = AGDEModelState.initialized;
      _logger.info('AGDE model setup completed');
    } catch (e) {
      _modelState = AGDEModelState.error;
      throw AIModelException('AGDE model setup failed: $e');
    }
  }

  void _initializeModel() {
    final random = Random();
    final double scale = sqrt(2.0 / (_inputSize + _hiddenSize));

    _weights = List.generate(
      _hiddenSize,
          (_) => List.generate(
        _inputSize,
            (_) => (random.nextDouble() * 2 - 1) * scale,
      ),
    );

    _biases = List.generate(_hiddenSize, (_) => 0.0);

    _mWeights = List.generate(
      _hiddenSize,
          (_) => List.generate(_inputSize, (_) => 0.0),
    );

    _vWeights = List.generate(
      _hiddenSize,
          (_) => List.generate(_inputSize, (_) => 0.0),
    );

    _ensembleWeights.add(List.from(_weights));
    _ensembleBiases.add(List.from(_biases));
  }

  int _calculateInputSize(GymMembersTracking sample) {
    return 15; // Toplam özellik sayısı (numerik + kategorik)
  }

  Future<void> _updateWeightsWithOptimization(List<double> gradients, int timeStep) async {
    final batchSize = gradients.length ~/ (_inputSize * _hiddenSize);

    for (var i = 0; i < _hiddenSize; i++) {
      for (var j = 0; j < _inputSize; j++) {
        final gradientIndex = i * _inputSize + j;
        final gradientValue = gradients[gradientIndex] / batchSize;

        _mWeights[i][j] = _beta1 * _mWeights[i][j] + (1 - _beta1) * gradientValue;
        _vWeights[i][j] = _beta2 * _vWeights[i][j] +
            (1 - _beta2) * pow(gradientValue, 2);

        final mHat = _mWeights[i][j] / (1 - pow(_beta1, timeStep));
        final vHat = _vWeights[i][j] / (1 - pow(_beta2, timeStep));

        _weights[i][j] -= _learningRate * mHat / (sqrt(vHat) + _epsilon);
      }
    }
  }

  @override
  Future<void> fit(List<dynamic> trainingData) async {
    try {
      if (_modelState != AGDEModelState.initialized) {
        throw AIModelException('Model must be initialized before training');
      }

      _modelState = AGDEModelState.training;
      final typedData = trainingData.cast<GymMembersTracking>();

      for (var epoch = 0; epoch < AIConstants.EPOCHS; epoch++) {
        double epochLoss = 0.0;
        for (var i = 0; i < typedData.length; i += AIConstants.BATCH_SIZE) {
          final end = min(i + AIConstants.BATCH_SIZE, typedData.length);
          final batch = typedData.sublist(i, end);
          final batchLoss = await _forwardPass(batch);
          epochLoss += batchLoss;

          final gradients = await _calculateGradients(batch);
          await _updateWeightsWithOptimization(
              gradients,
              epoch * typedData.length + i
          );
        }

        final metrics = await calculateMetrics(typedData);
        _updateMetricsWithLimit(metrics);

        if (_shouldEarlyStop()) {
          _logger.info('Early stopping at epoch $epoch');
          break;
        }
      }

      _modelState = AGDEModelState.trained;
    } catch (e) {
      _modelState = AGDEModelState.error;
      throw AIModelException('AGDE training failed: $e');
    }
  }



  Future<List<double>> _calculateGradients(List<GymMembersTracking> batch) async {
    final gradients = List.filled(_inputSize * _hiddenSize, 0.0);

    for (var sample in batch) {
      final features = _extractFeatures(sample);
      final target = sample.experienceLevel;

      final hiddenOutput = _computeHiddenLayer(features);
      final prediction = _softmax(hiddenOutput);

      // Output layer gradients
      final outputGradients = List.filled(_outputSize, 0.0);
      for (var i = 0; i < _outputSize; i++) {
        outputGradients[i] = prediction[i] - (i == target ? 1.0 : 0.0);
      }

      // Hidden layer gradients
      for (var i = 0; i < _hiddenSize; i++) {
        for (var j = 0; j < _inputSize; j++) {
          gradients[i * _inputSize + j] += outputGradients[i] * features[j];
        }
      }
    }

    return gradients.map((g) => g / batch.length).toList();
  }


  @override
  Future<Map<String, double>> analyzeFit(int programId, GymMembersTracking profile) async {
    try {
      final prediction = await predict(profile);
      return {
        'confidence': await calculateConfidence(profile, prediction),
        'program_match': prediction.exercisePlan == programId ? 1.0 : 0.0,
        'bmi_similarity': 1.0 - (prediction.bmi - profile.bmi).abs() / profile.bmi,
      };
    } catch (e) {
      throw AIModelException('Fit analysis failed: $e');
    }
  }

  @override
  Future<Map<String, double>> analyzeProgress(List<GymMembersTracking> userData) async {
    try {
      if (userData.length < 2) {
        throw AIModelException('Insufficient data for progress analysis');
      }
      final initial = userData.first;
      final current = userData.last;

      return {
        'bmi_change': current.bmi - initial.bmi,
        'weight_change': current.weightKg - initial.weightKg,
        'fitness_improvement': _calculateFitnessImprovement(userData),
        'consistency_score': _calculateConsistencyScore(userData),
      };
    } catch (e) {
      throw AIModelException('Progress analysis failed: $e');
    }
  }

  @override
  Future<double> calculateConfidence(GymMembersTracking input, FinalDataset prediction) async {
    return prediction.exercisePlan / 7.0; // Normalize to 0-1 range
  }

  @override
  Future<Map<String, dynamic>> getPredictionMetadata(GymMembersTracking input) async {
    return {
      'model_type': 'agde',
      'timestamp': DateTime.now().toIso8601String(),
      'ensemble_size': _numEnsemble,
      'input_features': _extractFeatures(input),
      'model_state': _modelState.toString(),
      'model_version': '1.0.0',
    };
  }

  Future<double> _forwardPass(List<GymMembersTracking> batch) async {
    double totalLoss = 0.0;
    try {
      for (var sample in batch) {
        final features = _extractFeatures(sample);
        final prediction = await _modelInference(features, 0);
        final loss = _crossEntropyLoss(
            prediction['output'] as List<double>,
            sample.experienceLevel
        );
        totalLoss += loss;
      }
      return totalLoss / batch.length;
    } catch (e) {
      throw AIModelException('Forward pass failed: $e');
    }
  }

  @override
  Future<FinalDataset> predict(GymMembersTracking input) async {
    try {
      if (_modelState != AGDEModelState.trained) {
        throw AIModelException('Model is not trained for inference');
      }
      _modelState = AGDEModelState.predicting;

      final features = _extractFeatures(input);
      List<double> predictions = List.filled(_outputSize, 0.0);

      for (var i = 0; i < _numEnsemble; i++) {
        final modelPrediction = await _modelInference(features, i);
        final output = modelPrediction['output'] as List<double>;
        for (var j = 0; j < _outputSize; j++) {
          predictions[j] += output[j] / _numEnsemble;
        }
      }

      final predictionIndex = _argmax(predictions);
      _modelState = AGDEModelState.trained;

      return FinalDataset(
          weight: input.weightKg,
          height: input.heightM,
          bmi: input.bmi,
          gender: input.gender,
          age: input.age,
          bmiCase: _getBMICase(input.bmi),
          exercisePlan: predictionIndex + 1
      );
    } catch (e) {
      _modelState = AGDEModelState.error;
      throw AIModelException('AGDE inference failed: $e');
    }
  }

  double _calculateFitnessImprovement(List<GymMembersTracking> userData) {
    if (userData.length < 2) return 0.0;

    final initial = userData.first;
    final current = userData.last;

    final bmiImprovement = (current.bmi - initial.bmi).abs() / initial.bmi;
    final strengthImprovement = (current.experienceLevel - initial.experienceLevel) / 5.0;
    final enduranceImprovement = (current.maxBpm - initial.maxBpm).abs() / initial.maxBpm;

    return (bmiImprovement + strengthImprovement + enduranceImprovement) / 3.0;
  }

  double _calculateConsistencyScore(List<GymMembersTracking> userData) {
    if (userData.length < 2) return 0.0;

    int consecutiveWorkouts = 0;
    int maxConsecutiveWorkouts = 0;
    double totalIntensity = 0.0;

    for (var i = 1; i < userData.length; i++) {
      final timeDiff = userData[i].sessionDuration - userData[i-1].sessionDuration;
      final intensityScore = userData[i].caloriesBurned / userData[i].sessionDuration;

      totalIntensity += intensityScore;

      if (timeDiff <= 2.0) { // 2 gün içinde tekrar antrenman
        consecutiveWorkouts++;
        maxConsecutiveWorkouts = max(maxConsecutiveWorkouts, consecutiveWorkouts);
      } else {
        consecutiveWorkouts = 0;
      }
    }

    final consistencyScore = maxConsecutiveWorkouts / 30.0; // Normalize to 0-1
    final intensityScore = totalIntensity / (userData.length * 1000); // Normalize calories

    return (consistencyScore + intensityScore) / 2.0;
  }

  double _crossEntropyLoss(List<double> predictions, int target) {
    if (target < 0 || target >= predictions.length) {
      return double.infinity;
    }

    double loss = 0.0;
    final targetOneHot = List.filled(predictions.length, 0.0);
    targetOneHot[target] = 1.0;

    for (var i = 0; i < predictions.length; i++) {
      if (targetOneHot[i] > 0) {
        loss -= targetOneHot[i] * log(max(predictions[i], 1e-7));
      }
    }

    return loss;
  }



  List<double> _extractFeatures(GymMembersTracking sample) {
    return [
      sample.weightKg,
      sample.heightM,
      sample.bmi,
      sample.age.toDouble(),
      sample.maxBpm.toDouble(),
      sample.avgBpm.toDouble(),
      sample.restingBpm.toDouble(),
      sample.sessionDuration,
      sample.caloriesBurned,
      sample.fatPercentage,
      sample.waterIntake,
      sample.workoutFrequency.toDouble(),
      sample.experienceLevel.toDouble(),
      sample.gender == 'male' ? 1.0 : 0.0,
      sample.gender == 'female' ? 1.0 : 0.0,
    ];
  }



  Future<Map<String, dynamic>> _modelInference(List<double> features, int modelIndex) async {
    final weights = _ensembleWeights[modelIndex];
    final biases = _ensembleBiases[modelIndex];

    final hiddenOutput = _computeHiddenLayer(features);
    final output = _softmax(hiddenOutput);

    return {
      'output': output,
      'hidden': hiddenOutput,
    };
  }

  List<double> _computeHiddenLayer(List<double> features) {
    final hiddenOutput = List<double>.filled(_hiddenSize, 0.0);
    for (var i = 0; i < _hiddenSize; i++) {
      double sum = _biases[i];
      for (var j = 0; j < _inputSize; j++) {
        sum += features[j] * _weights[i][j];
      }
      hiddenOutput[i] = _relu(sum);
    }
    return hiddenOutput;
  }

  List<double> _softmax(List<double> x) {
    final exp = x.map((e) => pow(e, 2.71828)).toList();
    final sum = exp.reduce((a, b) => a + b);
    return exp.map((e) => e / sum).toList();
  }

  double _relu(double x) => max(0, x);

  int _argmax(List<double> x) {
    int maxIndex = 0;
    double maxValue = x[0];

    for (var i = 1; i < x.length; i++) {
      if (x[i] > maxValue) {
        maxValue = x[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  String _getBMICase(double bmi) {
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25.0) return 'normal';
    if (bmi < 30.0) return 'overweight';
    return 'obese';
  }

  void _updateMetricsWithLimit(Map<String, double> metrics) {
    for (var key in metrics.keys) {
      _trainingHistory[key]?.add(metrics[key] ?? 0.0);
      if (_trainingHistory[key]!.length > MAX_HISTORY_SIZE) {
        _trainingHistory[key]?.removeAt(0);
      }
    }
  }

  bool _shouldEarlyStop() {
    if (_trainingHistory['loss']!.length < 5) return false;

    final recentLosses = _trainingHistory['loss']!.sublist(
        _trainingHistory['loss']!.length - 5
    );

    final variance = _calculateVariance(recentLosses);
    return variance < 1e-6;
  }

  double _calculateVariance(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((x) => pow(x - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  @override
  Future<bool> validateData(List<dynamic> data) async {
    if (data.isEmpty) {
      throw AIModelException('Empty dataset provided');
    }
    return true;
  }
}

