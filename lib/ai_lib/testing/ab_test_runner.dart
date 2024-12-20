// lib/ai_lib/testing/ab_test.dart

import 'package:logging/logging.dart';
import '../core/ai_constants.dart';
import '../models/base_model.dart';

class ABTest {
  final Logger _logger = Logger('ABTest');
  final BaseModel modelA;
  final BaseModel modelB;

  Map<String, dynamic> _testResults = {};
  final Map<String, List<double>> _performanceMetrics = {};

  ABTest({
    required this.modelA,
    required this.modelB,
  });

  Future<void> runTest({
    required List<Map<String, dynamic>> testData,
    required Map<String, double> successThresholds,
    bool collectDetailedMetrics = true,
  }) async {
    try {
      _logger.info('Starting AB test between models');

      final modelAResults = await _evaluateModel(
        modelA,
        testData,
        'Model A',
        collectDetailedMetrics,
      );

      final modelBResults = await _evaluateModel(
        modelB,
        testData,
        'Model B',
        collectDetailedMetrics,
      );

      _testResults = await _compareResults(
        modelAResults,
        modelBResults,
        successThresholds,
      );

      _logger.info('AB test completed successfully');
    } catch (e) {
      _logger.severe('AB test failed: $e');
      throw Exception('AB test failed: $e');
    }
  }

  Future<Map<String, dynamic>> _evaluateModel(
      BaseModel model,
      List<Map<String, dynamic>> testData,
      String modelName,
      bool collectDetailedMetrics,
      ) async {
    final results = <String, dynamic>{};
    final metrics = <String, List<double>>{
      'accuracy': [],
      'precision': [],
      'recall': [],
      'f1_score': [],
      'inference_time': [],
    };

    for (var data in testData) {
      try {
        final startTime = DateTime.now();
        final prediction = await model.inference(data);
        final endTime = DateTime.now();

        final actualValue = data['expected_output'];

        _updateMetrics(metrics, prediction, actualValue);

        if (collectDetailedMetrics) {
          _collectDetailedMetrics(
            metrics,
            prediction,
            actualValue,
            endTime.difference(startTime).inMilliseconds,
          );
        }
      } catch (e) {
        _logger.warning('Error in model evaluation: $e');
      }
    }

    return {
      'metrics': metrics,
      'model_name': modelName,
    };
  }

  Future<Map<String, dynamic>> _compareResults(
      Map<String, dynamic> modelAResults,
      Map<String, dynamic> modelBResults,
      Map<String, double> successThresholds,
      ) async {
    final comparison = <String, dynamic>{};

    for (var metric in ['accuracy', 'precision', 'recall', 'f1_score']) {
      final modelAMetric = _calculateAverageMetric(modelAResults['metrics'][metric]);
      final modelBMetric = _calculateAverageMetric(modelBResults['metrics'][metric]);

      comparison[metric] = {
        'model_a': modelAMetric,
        'model_b': modelBMetric,
        'difference': modelBMetric - modelAMetric,
        'significant_improvement':
        (modelBMetric - modelAMetric) > successThresholds[metric]!,
      };
    }

    comparison['winner'] = _determineWinner(comparison);
    return comparison;
  }

  void _updateMetrics(
      Map<String, List<double>> metrics,
      Map<String, dynamic> prediction,
      dynamic actualValue,
      ) {
    final accuracy = _calculateAccuracy(prediction['prediction'], actualValue);
    final precision = _calculatePrecision(prediction['prediction'], actualValue);
    final recall = _calculateRecall(prediction['prediction'], actualValue);
    final f1Score = _calculateF1Score(precision, recall);

    metrics['accuracy']?.add(accuracy);
    metrics['precision']?.add(precision);
    metrics['recall']?.add(recall);
    metrics['f1_score']?.add(f1Score);
  }

  void _collectDetailedMetrics(
      Map<String, List<double>> metrics,
      Map<String, dynamic> prediction,
      dynamic actualValue,
      int inferenceTimeMs,
      ) {
    metrics['inference_time']?.add(inferenceTimeMs.toDouble());

    // Ek metrikler eklenebilir
    if (prediction.containsKey('confidence')) {
      metrics['confidence'] ??= [];
      metrics['confidence']?.add(prediction['confidence']);
    }
  }

  double _calculateAverageMetric(List<double> metrics) {
    if (metrics.isEmpty) return 0.0;
    return metrics.reduce((a, b) => a + b) / metrics.length;
  }

  String _determineWinner(Map<String, dynamic> comparison) {
    int modelAWins = 0;
    int modelBWins = 0;

    for (var metric in ['accuracy', 'precision', 'recall', 'f1_score']) {
      if (comparison[metric]['significant_improvement']) {
        modelBWins++;
      } else if (comparison[metric]['difference'] < 0) {
        modelAWins++;
      }
    }

    if (modelBWins > modelAWins) return 'Model B';
    if (modelAWins > modelBWins) return 'Model A';
    return 'Tie';
  }

  double _calculateAccuracy(dynamic predicted, dynamic actual) {
    return predicted == actual ? 1.0 : 0.0;
  }

  double _calculatePrecision(dynamic predicted, dynamic actual) {
    // İkili sınıflandırma için basit precision hesaplama
    return predicted == actual ? 1.0 : 0.0;
  }

  double _calculateRecall(dynamic predicted, dynamic actual) {
    // İkili sınıflandırma için basit recall hesaplama
    return predicted == actual ? 1.0 : 0.0;
  }

  double _calculateF1Score(double precision, double recall) {
    if (precision + recall == 0) return 0.0;
    return 2 * (precision * recall) / (precision + recall);
  }

  Map<String, dynamic> getTestResults() => _testResults;
  Map<String, List<double>> getPerformanceMetrics() => _performanceMetrics;
}