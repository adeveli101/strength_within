// lib/ai_lib/testing/model_tester.dart

import 'package:logging/logging.dart';
import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import '../models/base_model.dart';
import '../core/trainingConfig.dart';

class ModelTestResult {
  final Map<String, double> metrics;
  final Map<String, dynamic> testDetails;
  final bool passed;
  final String modelName;
  final DateTime testTime;

  ModelTestResult({
    required this.metrics,
    required this.testDetails,
    required this.passed,
    required this.modelName,
    required this.testTime,
  });

  Map<String, dynamic> toJson() => {
    'metrics': metrics,
    'test_details': testDetails,
    'passed': passed,
    'model_name': modelName,
    'test_time': testTime.toIso8601String(),
  };
}

class ModelTester {
  final Logger _logger = Logger('ModelTester');

  final Map<String, List<ModelTestResult>> _testHistory = {};
  final TrainingConfig _config;

  ModelTester({
    TrainingConfig? config,
  }) : _config = config ?? TrainingConfig();

  Future<ModelTestResult> testModel({
    required BaseModel model,
    required List<Map<String, dynamic>> testData,
    Map<String, double>? acceptanceCriteria,
    bool verbose = false,
  }) async {
    try {
      _logger.info('Starting model test for ${model.runtimeType}');

      acceptanceCriteria ??= AIConstants.MINIMUM_METRICS;
      final startTime = DateTime.now();

      // Test verilerini validate et
      await _validateTestData(testData);

      // Model hazırlığını kontrol et
      if (!await model.isReady()) {
        throw AIModelException('Model is not ready for testing');
      }

      // Test metriklerini hesapla
      final metrics = await _runTestCases(model, testData, verbose);

      // Sonuçları değerlendir
      final passed = _evaluateResults(metrics, acceptanceCriteria);

      // Test detaylarını oluştur
      final testDetails = await _createTestDetails(
        model,
        testData,
        metrics,
        startTime,
      );

      // Test sonucunu oluştur
      final result = ModelTestResult(
        metrics: metrics,
        testDetails: testDetails,
        passed: passed,
        modelName: model.runtimeType.toString(),
        testTime: DateTime.now(),
      );

      // Test geçmişine ekle
      _addToTestHistory(result);

      if (verbose) {
        _logTestResults(result);
      }

      return result;

    } catch (e) {
      _logger.severe('Model testing failed: $e');
      throw AITestingException('Model testing failed: $e');
    }
  }

  Future<Map<String, double>> _runTestCases(
      BaseModel model,
      List<Map<String, dynamic>> testData,
      bool verbose,
      ) async {
    final metrics = <String, List<double>>{
      'accuracy': [],
      'precision': [],
      'recall': [],
      'f1_score': [],
      'inference_time': [],
      'confidence': [],
    };

    int processedCount = 0;
    final totalCases = testData.length;

    for (var testCase in testData) {
      try {
        final startTime = DateTime.now();
        final prediction = await model.inference(testCase);
        final endTime = DateTime.now();

        final actualValue = testCase['expected_output'];

        // Metrikleri hesapla ve kaydet
        _updateTestMetrics(
          metrics,
          prediction,
          actualValue,
          endTime.difference(startTime).inMilliseconds,
        );

        processedCount++;
        if (verbose && processedCount % 100 == 0) {
          _logger.info('Processed $processedCount/$totalCases test cases');
        }

      } catch (e) {
        _logger.warning('Error in test case: $e');
      }
    }

    // Ortalama metrikleri hesapla
    return _calculateAverageMetrics(metrics);
  }

  void _updateTestMetrics(
      Map<String, List<double>> metrics,
      Map<String, dynamic> prediction,
      dynamic actualValue,
      int inferenceTime,
      ) {
    // Temel metrikleri hesapla
    final accuracy = _calculateAccuracy(prediction['prediction'], actualValue);
    final precision = _calculatePrecision(prediction['prediction'], actualValue);
    final recall = _calculateRecall(prediction['prediction'], actualValue);
    final f1Score = _calculateF1Score(precision, recall);

    // Metrikleri kaydet
    metrics['accuracy']?.add(accuracy);
    metrics['precision']?.add(precision);
    metrics['recall']?.add(recall);
    metrics['f1_score']?.add(f1Score);
    metrics['inference_time']?.add(inferenceTime.toDouble());

    // Confidence değeri varsa kaydet
    if (prediction.containsKey('confidence')) {
      metrics['confidence']?.add(prediction['confidence']);
    }
  }

  Future<void> _validateTestData(List<Map<String, dynamic>> testData) async {
    if (testData.isEmpty) {
      throw AITestingException('Empty test data');
    }

    if (testData.length < AIConstants.MIN_TRAINING_SAMPLES) {
      throw AITestingException(
          'Insufficient test data. Minimum required: ${AIConstants.MIN_TRAINING_SAMPLES}'
      );
    }

    // Test verilerinin yapısını kontrol et
    for (var data in testData) {
      if (!data.containsKey('expected_output')) {
        throw AITestingException('Test data missing expected_output');
      }
    }
  }

  Map<String, double> _calculateAverageMetrics(
      Map<String, List<double>> metrics,
      ) {
    final averages = <String, double>{};

    metrics.forEach((key, values) {
      if (values.isEmpty) {
        averages[key] = 0.0;
      } else {
        averages[key] = values.reduce((a, b) => a + b) / values.length;
      }
    });

    return averages;
  }

  bool _evaluateResults(
      Map<String, double> metrics,
      Map<String, double> acceptanceCriteria,
      ) {
    for (var criterion in acceptanceCriteria.entries) {
      final metricValue = metrics[criterion.key];
      if (metricValue == null || metricValue < criterion.value) {
        return false;
      }
    }
    return true;
  }

  Future<Map<String, dynamic>> _createTestDetails(
      BaseModel model,
      List<Map<String, dynamic>> testData,
      Map<String, double> metrics,
      DateTime startTime,
      ) async {
    return {
      'test_duration_ms': DateTime.now().difference(startTime).inMilliseconds,
      'test_data_size': testData.length,
      'model_metadata': await model.getPredictionMetadata({}),
      'metrics': metrics,
      'config': _config.toJson(),
    };
  }

  void _addToTestHistory(ModelTestResult result) {
    _testHistory.putIfAbsent(result.modelName, () => []);
    _testHistory[result.modelName]!.add(result);

    // Test geçmişini sınırla
    if (_testHistory[result.modelName]!.length > AIConstants.MAX_PROCESSING_HISTORY) {
      _testHistory[result.modelName]!.removeAt(0);
    }
  }

  void _logTestResults(ModelTestResult result) {
    _logger.info('Test Results for ${result.modelName}:');
    _logger.info('Passed: ${result.passed}');
    _logger.info('Metrics: ${result.metrics}');
  }

  // Yardımcı metrik hesaplama metodları
  double _calculateAccuracy(dynamic predicted, dynamic actual) {
    return predicted == actual ? 1.0 : 0.0;
  }

  double _calculatePrecision(dynamic predicted, dynamic actual) {
    // Sınıflandırma için precision hesaplama
    return predicted == actual ? 1.0 : 0.0;
  }

  double _calculateRecall(dynamic predicted, dynamic actual) {
    // Sınıflandırma için recall hesaplama
    return predicted == actual ? 1.0 : 0.0;
  }

  double _calculateF1Score(double precision, double recall) {
    if (precision + recall == 0) return 0.0;
    return 2 * (precision * recall) / (precision + recall);
  }

  // Public metodlar
  List<ModelTestResult>? getTestHistory(String modelName) {
    return _testHistory[modelName];
  }

  Map<String, List<ModelTestResult>> getAllTestHistory() {
    return Map.from(_testHistory);
  }

  void clearTestHistory() {
    _testHistory.clear();
  }
}