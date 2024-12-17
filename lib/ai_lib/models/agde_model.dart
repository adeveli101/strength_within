import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:strength_within/ai_lib/core/ai_constants.dart';
import '../core/ai_data_processor.dart';
import '../core/ai_exceptions.dart';

/// Adaptive Gradient Descent Ensemble Model
class AGDEModel {



  final StreamController<Map<String, double>> _metricsController = StreamController.broadcast();
  Stream<Map<String, double>> get metricsStream => _metricsController.stream;


  // Singleton pattern
  static final AGDEModel _instance = AGDEModel._internal();
  factory AGDEModel() => _instance;

  AGDEModel._internal();

  final AIDataProcessor _dataProcessor = AIDataProcessor();

  // Model parametreleri
  late List<List<double>> _weights; // Input -> Hidden weights
  late List<List<double>> _hiddenWeights; // Hidden -> Output weights
  late List<double> _biases; // Output layer biases
  late double _learningRate; // Öğrenme oranı

  // Model durumu
  bool _isInitialized = false;
  bool _isTrained = false;

  // Model metrikleri
  final Map<String, double> _metrics = {
    'accuracy': 0.0,
    'precision': 0.0,
    'recall': 0.0,
    'f1_score': 0.0,
  };

  /// Modeli initialize eder
  Future<void> initialize() async {
    try {
      // Input -> Hidden layer weights
      _weights = List.generate(
        AIConstants.HIDDEN_LAYER_UNITS,
            (_) => List.generate(
          AIConstants.INPUT_FEATURES,
              (_) => Random().nextDouble() * 2 - 1,
        ),
      );

      // Hidden -> Output layer weights
      _hiddenWeights = List.generate(
        AIConstants.OUTPUT_CLASSES,
            (_) => List.generate(
          AIConstants.HIDDEN_LAYER_UNITS,
              (_) => Random().nextDouble() * 2 - 1,
        ),
      );

      // Output layer biases
      _biases = List.generate(
        AIConstants.OUTPUT_CLASSES,
            (_) => Random().nextDouble(),
      );

      _learningRate = AIConstants.LEARNING_RATE; // Öğrenme oranını ayarla
      _isInitialized = true; // Modelin başlatıldığını belirt

    } catch (e) {
      throw AITrainingException(
        'Model initialization failed: $e',
        code: AIConstants.ERROR_TRAINING_FAILED,
      );
    }
  }



  /// Modeli eğitir
  Future<void> train(List<Map<String, dynamic>> trainingData) async {
    if (!_isInitialized) await initialize(); // Modeli başlat

    try {
      int epoch = 0;
      double bestLoss = double.infinity;
      int patienceCounter = 0;

      while (epoch < AIConstants.EPOCHS) {
        double epochLoss = 0.0;

        // Batch işleme
        for (int i = 0; i < trainingData.length; i += AIConstants.BATCH_SIZE) {
          final batch = trainingData.sublist(
            i,
            min(i + AIConstants.BATCH_SIZE, trainingData.length),
          );
          final batchLoss = await _processBatch(batch);
          epochLoss += batchLoss;
        }

        // Performans metriklerini hesapla ve yayınla
        final metrics = await calculateMetrics(trainingData);
        metrics['loss'] = epochLoss / trainingData.length; // Epoch kaybını ekle

        _metricsController.add(metrics); // Metrikleri yayınla

        // Early stopping kontrolü
        if (epochLoss < bestLoss) {
          bestLoss = epochLoss;
          patienceCounter = 0;
        } else {
          patienceCounter++;
          if (patienceCounter >= AIConstants.EARLY_STOPPING_PATIENCE) break;
        }

        epoch++; // Epoch sayısını artır
      }

      _isTrained = true; // Eğitim tamamlandı

    } catch (e) {
      throw AITrainingException(
        'Model training failed: $e',
        code: AIConstants.ERROR_TRAINING_FAILED,
      );
    }
  }

  void dispose() {
    _metricsController.close(); // Stream'i kapat
  }

  /// Tahmin yapar
  Future<int> predict(Map<String, dynamic> input) async {
    if (!_isTrained) {
      throw AIPredictionException(
        'Model is not trained',
        code: AIConstants.ERROR_PREDICTION_FAILED,
      );
    }

    try {
      final processedInput = await _dataProcessor.processRawData(input); // Giriş verilerini işle
      final features = processedInput['features'] as Map<String, dynamic>;

      // İleri besleme (forward pass)
      final output = _forwardPass(features);

      // Softmax aktivasyonu ile olasılıkları hesapla
      final probabilities = _softmax(output);

      // En yüksek olasılığa sahip sınıfı döndür
      return probabilities.indexOf(probabilities.reduce(max)) + 1;

    } catch (e) {
      throw AIPredictionException(
        'Prediction failed: $e',
        code: AIConstants.ERROR_PREDICTION_FAILED,
      );
    }
  }

  /// Batch işleme fonksiyonu
  Future<double> _processBatch(List<Map<String, dynamic>> batch) async {
    double batchLoss = 0.0;

    for (final sample in batch) {
      final processed = await _dataProcessor.processRawData(sample); // Giriş verilerini işle
      final features = processed['features'] as Map<String, dynamic>;
      final label = processed['label'] as int;

      // Tahmin yap ve kaybı hesapla
      final prediction = await predict(sample);
      batchLoss += _calculateLoss(prediction, label);

      // Ağırlıkları ve biasları güncelle
      _updateParameters(features, label, prediction);
    }

    return batchLoss / batch.length; // Batch kaybını döndür
  }


  /// Kayıp hesaplama fonksiyonu
  double _calculateLoss(int prediction, int actual) {
    final oneHot =
    List.generate(AIConstants.OUTPUT_CLASSES, (i) => i == actual - 1 ? 1.0 : 0.0);

    final predicted =
    List.generate(AIConstants.OUTPUT_CLASSES, (i) => i == prediction - 1 ? math.exp(1.0) : math.exp(0.01));

    double loss = oneHot.asMap().entries.fold(0.0, (sum, entry) {
      if (entry.value != 0) sum -= entry.value * log(predicted[entry.key]);
      return sum;
    });

    return loss; // Kayıp değerini döndür
  }


  /// Model parametrelerini günceller
  void _updateParameters(Map<String, dynamic> features, int label, int prediction) {
    final learningRate = _learningRate;
    final error = prediction - label;
    final inputValues = features.values.toList();

    // Input -> Hidden weights güncelleme
    for (int i = 0; i < AIConstants.HIDDEN_LAYER_UNITS; i++) {
      for (int j = 0; j < AIConstants.INPUT_FEATURES; j++) {
        _weights[i][j] -= learningRate * error * inputValues[j];
      }
    }

    // Hidden -> Output weights güncelleme
    for (int i = 0; i < AIConstants.OUTPUT_CLASSES; i++) {
      for (int j = 0; j < AIConstants.HIDDEN_LAYER_UNITS; j++) {
        _hiddenWeights[i][j] -= learningRate * error * inputValues[j];
      }
    }

    // Biasları güncelleme
    for (int i = 0; i < _biases.length; i++) {
      _biases[i] -= learningRate * error;
    }
  }

  /// İleri besleme hesaplama fonksiyonu
  List<double> _forwardPass(Map<String, dynamic> features) {
    final List<double> hidden =
    List.filled(AIConstants.HIDDEN_LAYER_UNITS, 0.0);
    final inputValues = features.values.toList();

    for (int i = 0; i < AIConstants.HIDDEN_LAYER_UNITS; i++) {
      for (int j = 0; j < inputValues.length; j++) {
        hidden[i] += inputValues[j] * _weights[i][j];
      }
      hidden[i] = _relu(hidden[i] + _biases[i]); // ReLU aktivasyonu uygula
    }

    // Hidden layer'dan Output layer'a geçiş yapma
    final output =
    List.filled(AIConstants.OUTPUT_CLASSES, 0.0);

    for (int i = 0; i < AIConstants.OUTPUT_CLASSES; i++) {
      for (int j = 0; j < AIConstants.HIDDEN_LAYER_UNITS; j++) {
        output[i] += hidden[j] * _hiddenWeights[i][j];
      }
    }

    return output;
  }

  /// ReLU aktivasyon fonksiyonu
  double _relu(double x) => max(0, x);

  /// Softmax aktivasyon fonksiyonu
  List<double> _softmax(List<double> x) {
    final maxVal = x.reduce(math.max);
    final exp =
    x.map((e) => math.exp(e - maxVal)).toList();

    final sum =
    exp.reduce((a, b) => a + b);

    return exp.map((e) => e / sum).toList();
  }

  Future<Map<String, double>> calculateMetrics(List<Map<String, dynamic>> validationData) async {
    int correctPredictions = 0;

    List<int> truePositives = List.filled(AIConstants.OUTPUT_CLASSES, 0);
    List<int> falsePositives = List.filled(AIConstants.OUTPUT_CLASSES, 0);
    List<int> falseNegatives = List.filled(AIConstants.OUTPUT_CLASSES, 0);

    for (final sample in validationData) {
      final prediction = await predict(sample);
      final actual = sample['Exercise Recommendation Plan'] as int;

      if (prediction == actual) {
        correctPredictions++;
        truePositives[actual - 1]++;
      } else {
        falsePositives[prediction - 1]++;
        falseNegatives[actual - 1]++;
      }
    }

    // Metrikleri hesapla
    _metrics['accuracy'] = correctPredictions / validationData.length;

    double totalPrecision = 0.0;
    double totalRecall = 0.0;

    for (int i = 0; i < AIConstants.OUTPUT_CLASSES; i++) {
      final precision = truePositives[i] / (truePositives[i] + falsePositives[i]);
      final recall = truePositives[i] / (truePositives[i] + falseNegatives[i]);

      totalPrecision += precision.isNaN ? 0 : precision; // NaN kontrolü
      totalRecall += recall.isNaN ? 0 : recall; // NaN kontrolü
    }

    _metrics['precision'] = totalPrecision / AIConstants.OUTPUT_CLASSES;
    _metrics['recall'] = totalRecall / AIConstants.OUTPUT_CLASSES;

    // F1 Score hesaplama
    if (_metrics['precision']! + _metrics['recall']! > 0) {
      _metrics['f1_score'] =
          2 * (_metrics['precision']! * _metrics['recall']!) /
              (_metrics['precision']! + _metrics['recall']!);
    } else {
      _metrics['f1_score'] = 0; // F1 Score için NaN kontrolü
    }

    return _metrics;
  }

}







