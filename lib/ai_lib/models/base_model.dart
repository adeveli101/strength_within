import 'package:logging/logging.dart';
import '../ai_data_bloc/datasets_models.dart';
import '../core/ai_exceptions.dart';

abstract class BaseModel {
  final _logger = Logger('BaseModel');
  Map<String, double> _metrics = {};




  Future<void> setup(List<Map<String, dynamic>> trainingData);
  Future<void> fit(List<Map<String, dynamic>> trainingData);
  Future<FinalDataset> predict(GymMembersTracking input);
  Future<bool> validateData(List<Map<String, dynamic>> data);
  Future<Map<String, double>> analyzeFit(int programId, GymMembersTracking profile);
  Future<Map<String, double>> analyzeProgress(List<GymMembersTracking> userData);
  Future<Map<String, double>> calculateMetrics(List<Map<String, dynamic>> testData);
  Future<double> calculateConfidence(GymMembersTracking input, FinalDataset prediction);

  Future<Map<String, dynamic>> getPredictionMetadata(GymMembersTracking input);

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
  Future<bool> validate() async {
    if (_metrics.isEmpty) {
      _logger.warning('Model has no metrics calculated');
      return false;
    }
    return true;
  }

  // Batch işleme kapasitesi
  Future<List<FinalDataset>> batchProcess(List<GymMembersTracking> inputs) async {
    final results = <FinalDataset>[];
    for (var input in inputs) {
      try {
        final result = await predict(input);
        results.add(result);
      } catch (e) {
        _logger.severe('Batch processing error for input: $input');
        throw AIModelException('Batch processing failed: $e');
      }
    }
    return results;
  }

// _trainingData tanımsız olduğu için düzeltme
  Future<bool> isReady() async {
    try {
      return await validate();
    } catch (e) {
      _logger.warning('Model validation failed: $e');
      return false;
    }
  }


  Future<Map<String, double>> evaluatePerformance(List<Map<String, dynamic>> testData) async {
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
  bool shouldStopTraining(
      Map<String, double> currentMetrics,
      Map<String, double> previousMetrics, {
        double threshold = 0.001
      }) {
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

  // Model serialization
  Map<String, dynamic> toJson() {
    return {
      'metrics': _metrics,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<void> fromJson(Map<String, dynamic> json) async {
    try {
      if (json.containsKey('metrics')) {
        final metricsMap = json['metrics'] as Map<String, dynamic>;
        _metrics = metricsMap.map((key, value) =>
            MapEntry(key, (value as num).toDouble()));
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
