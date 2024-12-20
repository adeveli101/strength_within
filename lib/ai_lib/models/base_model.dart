import 'package:logging/logging.dart';
import '../ai_data_bloc/ai_repository.dart';
import '../core/ai_exceptions.dart';

abstract class BaseModel {
  final _logger = Logger('BaseModel');
  Map<String, double> _metrics = {};

  // Ana metodlar
  Future<void> setup(List<Map<String, dynamic>> trainingData);
  Future<void> fit(List<Map<String, dynamic>> trainingData);
  Future<Map<String, dynamic>> inference(Map<String, dynamic> input);
  Future<void> validateData(List<Map<String, dynamic>> data);

  // Metriklerle ilgili metodlar
  Future<Map<String, dynamic>> analyzeFit(int programId, UserProfile profile);
  Future<Map<String, dynamic>> analyzeProgress(List<Map<String, dynamic>> userData);
  Future<Map<String, double>> calculateMetrics(List<Map<String, dynamic>> testData);
  Future<double> calculateConfidence(Map<String, dynamic> input, dynamic prediction);

  // Metadata ve durum metodları
  Future<Map<String, dynamic>> getPredictionMetadata(Map<String, dynamic> input);

  // Yardımcı metodlar
  void updateMetrics(Map<String, double> newMetrics) {
    _metrics = Map<String, double>.from(newMetrics);
    _logger.info('Metrics updated: $_metrics');
  }

  Map<String, double> getMetrics() {
    return Map<String, double>.from(_metrics);
  }

  // Kaynak temizleme
  Future<void> dispose() async {
    try {
      _metrics.clear();
      _logger.info('Base model resources released');
    } catch (e) {
      _logger.severe('Error during base model disposal: $e');
      throw AIModelException('Base model disposal failed: $e');
    }
  }

  // Model validation
  Future<void> validate() async {
    if (_metrics.isEmpty) {
      _logger.warning('Model has no metrics calculated');
    }
  }

  // Batch işleme kapasitesi
  Future<List<Map<String, dynamic>>> batchProcess(
      List<Map<String, dynamic>> inputs) async {
    final results = <Map<String, dynamic>>[];

    for (var input in inputs) {
      try {
        final result = await inference(input);
        results.add(result);
      } catch (e) {
        _logger.severe('Batch processing error for input: $input');
        results.add({
          'error': e.toString(),
          'input': input,
        });
      }
    }

    return results;
  }

  // Model durumu kontrolü
  Future<bool> isReady() async {
    try {
      await validate();
      return true;
    } catch (e) {
      _logger.warning('Model validation failed: $e');
      return false;
    }
  }

  // Model performans metrikleri
  Future<Map<String, double>> evaluatePerformance(
      List<Map<String, dynamic>> testData) async {
    try {
      final metrics = await calculateMetrics(testData);
      updateMetrics(metrics);
      return metrics;
    } catch (e) {
      _logger.severe('Performance evaluation failed: $e');
      throw AIModelException('Performance evaluation failed: $e');
    }
  }

  // Early stopping için yardımcı metod
  bool shouldStopTraining(Map<String, double> currentMetrics,
      Map<String, double> previousMetrics,
      {double threshold = 0.001}) {

    if (previousMetrics.isEmpty) return false;

    for (var metric in currentMetrics.keys) {
      final current = currentMetrics[metric] ?? 0.0;
      final previous = previousMetrics[metric] ?? 0.0;

      if ((current - previous).abs() > threshold) {
        return false;
      }
    }

    return true;
  }

  // Model serialization için yardımcı metodlar
  Map<String, dynamic> toJson() {
    return {
      'metrics': _metrics,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<void> fromJson(Map<String, dynamic> json) async {
    try {
      if (json.containsKey('metrics')) {
        _metrics = Map<String, double>.from(json['metrics']);
      }
      _logger.info('Model loaded from JSON');
    } catch (e) {
      _logger.severe('Error loading model from JSON: $e');
      throw AIModelException('Model loading failed: $e');
    }
  }

  // Model checkpoint yönetimi
  Future<Map<String, dynamic>> saveCheckpoint() async {
    return {
      'model_state': toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<void> loadCheckpoint(Map<String, dynamic> checkpoint) async {
    try {
      if (checkpoint.containsKey('model_state')) {
        await fromJson(checkpoint['model_state']);
      }
      _logger.info('Checkpoint loaded successfully');
    } catch (e) {
      _logger.severe('Error loading checkpoint: $e');
      throw AIModelException('Checkpoint loading failed: $e');
    }
  }
}