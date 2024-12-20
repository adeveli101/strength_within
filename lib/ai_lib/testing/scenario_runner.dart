import 'dart:math';

import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import '../models/agde_model.dart';
import '../models/collab_model.dart';
import '../models/knn_model.dart';
import '../ai_data_bloc/dataset_provider.dart';
import '../core/ai_data_processor.dart';

class ScenarioRunner {
  // Singleton pattern
  static final ScenarioRunner _instance = ScenarioRunner._internal();
  factory ScenarioRunner() => _instance;
  ScenarioRunner._internal();

  // Model instances
  final AGDEModel _agdeModel = AGDEModel();
  final KNNModel _knnModel = KNNModel();
  final CollaborativeModel _collabModel = CollaborativeModel();

  // Data handlers
  final AIDataProcessor _dataProcessor = AIDataProcessor();
  // ignore: unused_field
  final DatasetDBProvider _datasetProvider = DatasetDBProvider();

  /// Farklı senaryoları test eder
  Future<Map<String, Map<String, double>>> runScenarios() async {
    try {
      return {
        'beginner_scenario': await _runBeginnerScenario(),
        'weight_loss_scenario': await _runWeightLossScenario(),
        'muscle_gain_scenario': await _runMuscleGainScenario(),
        'endurance_scenario': await _runEnduranceScenario(),
        'rehabilitation_scenario': await _runRehabilitationScenario(),
      };
    } catch (e) {
      throw AIException('Scenario running failed: $e');
    }
  }

  /// Yeni başlayan kullanıcı senaryosu
  Future<Map<String, double>> _runBeginnerScenario() async {
    final testData = {
      'weight': 75.0,
      'height': 1.75,
      'bmi': 24.5,
      'gender': 'male',
      'age': 25,
      'experience_level': 1,
      'workout_frequency': 2,
      'fat_percentage': 22.0,
    };

    return await _runScenario(testData);
  }

  /// Kilo verme senaryosu
  Future<Map<String, double>> _runWeightLossScenario() async {
    final testData = {
      'weight': 95.0,
      'height': 1.80,
      'bmi': 29.3,
      'gender': 'female',
      'age': 35,
      'experience_level': 2,
      'workout_frequency': 4,
      'fat_percentage': 32.0,
    };

    return await _runScenario(testData);
  }

  /// Kas kazanma senaryosu
  Future<Map<String, double>> _runMuscleGainScenario() async {
    final testData = {
      'weight': 65.0,
      'height': 1.70,
      'bmi': 22.5,
      'gender': 'male',
      'age': 28,
      'experience_level': 3,
      'workout_frequency': 5,
      'fat_percentage': 15.0,
    };

    return await _runScenario(testData);
  }

  /// Dayanıklılık geliştirme senaryosu
  Future<Map<String, double>> _runEnduranceScenario() async {
    final testData = {
      'weight': 70.0,
      'height': 1.75,
      'bmi': 22.9,
      'gender': 'female',
      'age': 42,
      'experience_level': 2,
      'workout_frequency': 3,
      'fat_percentage': 24.0,
    };

    return await _runScenario(testData);
  }

  /// Rehabilitasyon senaryosu
  Future<Map<String, double>> _runRehabilitationScenario() async {
    final testData = {
      'weight': 82.0,
      'height': 1.78,
      'bmi': 25.9,
      'gender': 'male',
      'age': 45,
      'experience_level': 1,
      'workout_frequency': 3,
      'fat_percentage': 28.0,
    };

    return await _runScenario(testData);
  }

  /// Senaryo çalıştırma yardımcı metodu
  Future<Map<String, double>> _runScenario(Map<String, dynamic> testData) async {
    final processedData = await _dataProcessor.processRawData(testData);

    final agdePred = await _agdeModel.predict(processedData);
    final knnPreds = await _knnModel.recommend(testData['userId'] ?? 0, 5);
    final collabPreds = await _collabModel.recommendPrograms(testData['userId'] ?? 0, 5);

    return {
      'agde_confidence': _calculateConfidence(agdePred),
      'knn_confidence': _calculateListConfidence(knnPreds),
      'collab_confidence': _calculateListConfidence(collabPreds),
    };
  }

  /// Güven skoru hesaplama
  double _calculateConfidence(int prediction) {
    return 0.8 + (Random().nextDouble() * 0.2); // Simüle edilmiş güven skoru
  }

  double _calculateListConfidence(List<int> predictions) {
    return 0.7 + (Random().nextDouble() * 0.3); // Simüle edilmiş güven skoru
  }
}
