import 'dart:math';
import 'package:logging/logging.dart';
import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import '../core/ai_data_processor.dart';
import 'base_model.dart';

enum AGDEModelState {
  uninitialized,
  initializing,
  initialized,
  training,
  trained,
  predicting,
  error
}

class AGDEModel extends BaseModel {
  final _logger = Logger('AGDEModel');
  final _dataProcessor = AIDataProcessor();

  // Model state
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

  // Momentum ve adaptif öğrenme parametreleri
  final double _beta1 = 0.9;
  final double _beta2 = 0.999;
  final double _epsilon = 1e-8;

  // Adam optimizer için momentum ve velocity
  late List<List<double>> _mWeights;
  late List<List<double>> _vWeights;

  // Training history with size limit
  final Map<String, List<double>> _trainingHistory = {
    'loss': [],
    'accuracy': [],
    'precision': [],
    'recall': [],
    'f1_score': [],
  };
  static const int MAX_HISTORY_SIZE = 1000;




  @override
  Future<double> calculateConfidence(Map<String, dynamic> input, dynamic prediction) async {
    final probabilities = prediction['probabilities'] as List<double>;
    if (probabilities.isEmpty) return 0.0;
    return probabilities.reduce(max) / probabilities.fold(0.0, (a, b) => a + b);
  }

  @override
  Future<Map<String, double>> calculateMetrics(List<Map<String, dynamic>> testData) async {
    final predictions = await Future.wait(
        testData.map((sample) => inference(sample))
    );

    return {
      'accuracy': _calculateAccuracy(predictions, testData),
      'precision': _calculatePrecision(predictions, testData),
      'recall': _calculateRecall(predictions, testData),
      'f1_score': _calculateF1Score(predictions, testData)
    };
  }
  double _calculateAccuracy(List<Map<String, dynamic>> predictions, List<Map<String, dynamic>> actual) {
    int correct = 0;
    for (var i = 0; i < predictions.length; i++) {
      if (predictions[i]['prediction_index'] == actual[i]['label']) {
        correct++;
      }
    }
    return correct / predictions.length;
  }

  double _calculatePrecision(List<Map<String, dynamic>> predictions, List<Map<String, dynamic>> actual) {
    Map<int, Map<String, int>> metrics = {};

    for (var i = 0; i < predictions.length; i++) {
      final predicted = predictions[i]['prediction_index'] as int;
      final actualLabel = actual[i]['label'] as int;

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

  double _calculateRecall(List<Map<String, dynamic>> predictions, List<Map<String, dynamic>> actual) {
    Map<int, Map<String, int>> metrics = {};

    for (var i = 0; i < predictions.length; i++) {
      final predicted = predictions[i]['prediction_index'] as int;
      final actualLabel = actual[i]['label'] as int;

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

  double _calculateF1Score(List<Map<String, dynamic>> predictions, List<Map<String, dynamic>> actual) {
    final precision = _calculatePrecision(predictions, actual);
    final recall = _calculateRecall(predictions, actual);

    return (precision + recall) > 0
        ? 2 * (precision * recall) / (precision + recall)
        : 0.0;
  }

  Future<List<double>> _calculateGradients(List<Map<String, dynamic>> batch) async {
    final gradients = List<double>.filled(_inputSize * _hiddenSize, 0.0);

    for (var sample in batch) {
      final features = _extractFeatures(sample);
      final target = sample['label'] as int;

      final hiddenOutput = _computeHiddenLayer(features);
      final prediction = _softmax(hiddenOutput);

      // Output layer gradients
      final outputGradients = List<double>.filled(_outputSize, 0.0);
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

    // Batch normalization
    return gradients.map((g) => g / batch.length).toList();
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

  @override
  Future<void> setup(List<Map<String, dynamic>> trainingData) async {
    try {
      _modelState = AGDEModelState.initializing;
      await validateData(trainingData);

      _inputSize = _calculateInputSize(trainingData.first);
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

  @override
  Future<void> fit(List<Map<String, dynamic>> trainingData) async {
    try {
      if (_modelState != AGDEModelState.initialized) {
        throw AIModelException('Model must be initialized before training');
      }

      _modelState = AGDEModelState.training;
      int currentStep = 0;

      for (var epoch = 0; epoch < AIConstants.EPOCHS; epoch++) {
        double epochLoss = 0.0;

        for (var i = 0; i < trainingData.length; i += AIConstants.BATCH_SIZE) {
          final end = min(i + AIConstants.BATCH_SIZE, trainingData.length);
          final batch = trainingData.sublist(i, end);

          final batchLoss = await _forwardPass(batch);
          epochLoss += batchLoss;

          await _updateWeightsWithOptimization(
              await _calculateGradients(batch),
              ++currentStep
          );

          _cleanupBatchMemory();
        }

        final metrics = await calculateMetrics(trainingData);
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

  @override
  Future<Map<String, dynamic>> inference(Map<String, dynamic> input) async {
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
      final predictionString = AIConstants.EXERCISE_PLAN_DESCRIPTIONS[predictionIndex] ??
          'Unknown Plan Level $predictionIndex';

      _modelState = AGDEModelState.trained;
      return {
        'prediction': predictionString,
        'prediction_index': predictionIndex,
        'probabilities': predictions,
        'confidence': _calculateConfidence(predictions)
      };
    } catch (e) {
      _modelState = AGDEModelState.error;
      throw AIModelException('AGDE inference failed: $e');
    }
  }

  @override
  Future<void> validateData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      throw AIModelException('Empty dataset provided');
    }

    final requiredKeys = ['features', 'categorical', 'label'];
    for (var sample in data) {
      if (!requiredKeys.every(sample.containsKey)) {
        throw AIModelException('Invalid data format');
      }
    }
  }

  @override
  Future<Map<String, dynamic>> getPredictionMetadata(Map<String, dynamic> input) async {
    return {
      'model_type': 'agde',
      'timestamp': DateTime.now().toIso8601String(),
      'ensemble_size': _numEnsemble,
      'input_features': input['features'],
      'model_version': '1.0.0',
    };
  }

  // Private helper methods
  void _initializeModel() {
    final random = Random();
    final double scale = sqrt(2.0 / (_inputSize + _hiddenSize));

    // Weights ve biases initialize
    _weights = List.generate(
      _hiddenSize,
          (_) => List.generate(
        _inputSize,
            (_) => (random.nextDouble() * 2 - 1) * scale,
      ),
    );

    _biases = List.generate(_hiddenSize, (_) => 0.0);

    // Adam optimizer için momentum ve velocity matrislerini initialize et
    _mWeights = List.generate(
      _hiddenSize,
          (_) => List.generate(_inputSize, (_) => 0.0),
    );

    _vWeights = List.generate(
      _hiddenSize,
          (_) => List.generate(_inputSize, (_) => 0.0),
    );

    // Ensemble için kopyala
    _ensembleWeights.add(List.from(_weights));
    _ensembleBiases.add(List.from(_biases));
  }
  int _calculateInputSize(Map<String, dynamic> sample) {
    final features = sample['features'] as Map<String, dynamic>;
    final categorical = sample['categorical'] as Map<String, dynamic>;
    return features.length + categorical.length;
  }

  Future<double> _forwardPass(List<Map<String, dynamic>> batch) async {
    double totalLoss = 0.0;

    try {
      for (var sample in batch) {
        // Numeric özellikleri normalize et
        final normalizedFeatures = await _dataProcessor.normalizeFeatures(sample['features']);

        // Categorical özellikleri double'a dönüştür
        final categoricalFeatures = (sample['categorical'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, value is num ? value.toDouble() : 0.0)
        );

        // Tüm özellikleri birleştir ve double listesine dönüştür
        final allFeatures = [
          ...normalizedFeatures.values,
          ...categoricalFeatures.values,
        ].map((value) => value.toDouble()).toList();

        // Model tahminini yap
        final hiddenOutput = _computeHiddenLayer(allFeatures);
        final prediction = _softmax(hiddenOutput);

        // Loss hesapla
        final target = sample['label'] as int;
        final loss = _crossEntropyLoss(prediction, target);

        // Batch loss'u güncelle
        totalLoss += loss;

        // Memory optimization
        _cleanupBatchMemory();
      }

      // Ortalama loss değerini döndür
      return totalLoss / batch.length;

    } catch (e) {
      _logger.severe('Forward pass error: $e');
      throw AIModelException('Forward pass failed: $e');
    }
  }


  String _getBMICase(Map<String, dynamic> categorical) {
    if (categorical['bmi_underweight'] == 1.0) return 'underweight';
    if (categorical['bmi_normal'] == 1.0) return 'normal';
    if (categorical['bmi_overweight'] == 1.0) return 'overweight';
    if (categorical['bmi_obese'] == 1.0) return 'obese';
    return 'normal';
  }

// BFP case'ini belirlemek için yardımcı metod
  String _getBFPCase(Map<String, dynamic> categorical) {
    if (categorical['bfp_low'] == 1.0) return 'low';
    if (categorical['bfp_normal'] == 1.0) return 'normal';
    if (categorical['bfp_high'] == 1.0) return 'high';
    if (categorical['bfp_very_high'] == 1.0) return 'very_high';
    return 'normal';
  }



  List<double> _extractFeatures(Map<String, dynamic> sample) {
    final features = <double>[];

    final numericFeatures = sample['features'] as Map<String, double>;
    final categoricalFeatures = sample['categorical'] as Map<String, double>;

    // DataProcessor kullanarak normalizasyon ekle
    features.addAll(
        numericFeatures.entries.map((e) =>
            _dataProcessor.normalize(
                e.value,
                AIConstants.FEATURE_RANGES[e.key]!['min']!,
                AIConstants.FEATURE_RANGES[e.key]!['max']!
            )
        )
    );

    features.addAll(categoricalFeatures.values);
    return features;
  }


  Future<void> _updateWeightsWithOptimization(List<double> gradients, int timeStep) async {
    final batchSize = gradients.length ~/ (_inputSize * _hiddenSize);

    for (var i = 0; i < _hiddenSize; i++) {
      for (var j = 0; j < _inputSize; j++) {
        final gradientIndex = i * _inputSize + j;
        final gradientValue = gradients[gradientIndex] / batchSize;

        final mWeight = _beta1 * _mWeights[i][j] + (1 - _beta1) * gradientValue;
        final vWeight = _beta2 * _vWeights[i][j] + (1 - _beta2) * pow(gradientValue, 2);

        _mWeights[i][j] = mWeight;
        _vWeights[i][j] = vWeight;

        final mHat = mWeight / (1 - pow(_beta1, timeStep));
        final vHat = vWeight / (1 - pow(_beta2, timeStep));

        _weights[i][j] -= _learningRate * mHat / (sqrt(vHat) + _epsilon);
      }
    }
  }

  void _cleanupBatchMemory() {
    _tempGradients?.clear();
    _tempOutputs?.clear();

    // Garbage collection hint
    _tempGradients = null;
    _tempOutputs = null;
  }


  List<double>? _tempGradients;
  List<double>? _tempOutputs;

  void _updateMetricsWithLimit(Map<String, double> metrics) {
    metrics.forEach((key, value) {
      _trainingHistory[key]?.add(value);
      if ((_trainingHistory[key]?.length ?? 0) > MAX_HISTORY_SIZE) {
        _trainingHistory[key]?.removeAt(0);
      }
    });
  }

  bool _shouldEarlyStop() {
    if (_trainingHistory['loss']!.length < AIConstants.EARLY_STOPPING_PATIENCE) {
      return false;
    }

    final recentLosses = _trainingHistory['loss']!
        .sublist(_trainingHistory['loss']!.length - AIConstants.EARLY_STOPPING_PATIENCE);

    // Trend analizi ekle
    double sumDiff = 0.0;
    for (var i = 1; i < recentLosses.length; i++) {
      sumDiff += recentLosses[i] - recentLosses[i-1];
    }

    return sumDiff.abs() < AIConstants.EARLY_STOPPING_THRESHOLD;
  }


  bool _checkConvergence(List<double> recentLosses) {
    if (recentLosses.length < 2) return false;

    final threshold = 1e-4;
    final currentLoss = recentLosses.last;
    final previousLoss = recentLosses[recentLosses.length - 2];

    return (previousLoss - currentLoss).abs() < threshold;
  }

  List<double> _softmax(List<double> x) {
    final exp = x.map((e) => pow(e, 2.71828)).toList();
    final sum = exp.reduce((a, b) => a + b);
    return exp.map((e) => e / sum).toList();
  }

  double _relu(double x) => max(0, x);

  int _argmax(List<double> x) => x.indexOf(x.reduce(max));

  double _calculateConfidence(List<double> probabilities) {
    if (probabilities.isEmpty) return 0.0;
    return probabilities.reduce(max);
  }

  double _crossEntropyLoss(List<double> predictions, int target) {
    if (target < 0 || target >= predictions.length) {
      return double.infinity;
    }

    final probability = predictions[target];
    if (probability <= 0) {
      return double.infinity;
    }

    return -log(probability);
  }















  @override
  Future<void> dispose() async {
    try {
      await super.dispose();
      _trainingHistory.clear();
      _weights.clear();
      _ensembleWeights.clear();
      _biases.clear();
      _ensembleBiases.clear();
      _mWeights.clear();
      _vWeights.clear();
      _modelState = AGDEModelState.uninitialized;
      _logger.info('AGDE model resources released');
    } catch (e) {
      _logger.severe('Error during AGDE model disposal: $e');
      rethrow;
    }
  }




}
