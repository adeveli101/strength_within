import 'dart:async';
import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import '../models/agde_model.dart';
import '../models/collab_model.dart';
import '../models/knn_model.dart';
import '../ai_data_bloc/dataset_provider.dart';
import '../core/ai_data_processor.dart';

class ABTestRunner {
  // Singleton pattern
  static final ABTestRunner _instance = ABTestRunner._internal();
  factory ABTestRunner() => _instance;
  ABTestRunner._internal();

  // Model instances
  final AGDEModel _agdeModel = AGDEModel();
  final KNNModel _knnModel = KNNModel();
  final CollaborativeModel _collabModel = CollaborativeModel();

  // Data handlers
  final AIDataProcessor _dataProcessor = AIDataProcessor();
  final DatasetDBProvider _datasetProvider = DatasetDBProvider();

  // Test sonuçları
  final Map<String, Map<String, double>> _testResults = {
    'control_group': {
      'accuracy': 0.0,
      'precision': 0.0,
      'recall': 0.0,
      'f1_score': 0.0,
    },
    'test_group': {
      'accuracy': 0.0,
      'precision': 0.0,
      'recall': 0.0,
      'f1_score': 0.0,
    }
  };

  /// A/B testi çalıştırır
  Future<Map<String, Map<String, double>>> runTest() async {
    try {
      // Test verilerini al
      final testData = await _datasetProvider.getCombinedTrainingData();
      final processedData = await _dataProcessor.processTrainingData(testData);

      // Veriyi kontrol ve test grubu olarak böl
      final splits = await _splitTestGroups(processedData);

      // Kontrol grubu testi
      final controlResults = await _runControlGroup(splits['control']!);
      _testResults['control_group'] = controlResults;

      // Test grubu testi
      final testResults = await _runTestGroup(splits['test']!);
      _testResults['test_group'] = testResults;

      return _testResults;
    } catch (e) {
      throw AIException('A/B test failed: $e');
    }
  }

  /// Test gruplarını oluşturur
  Future<Map<String, List<Map<String, dynamic>>>> _splitTestGroups(
      List<Map<String, dynamic>> data
      ) async {
    data.shuffle();
    final splitIndex = (data.length * 0.5).toInt();

    return {
      'control': data.sublist(0, splitIndex),
      'test': data.sublist(splitIndex)
    };
  }

  /// Kontrol grubu testi
  Future<Map<String, double>> _runControlGroup(
      List<Map<String, dynamic>> controlData
      ) async {
    await _agdeModel.train(controlData);
    return await _agdeModel.calculateMetrics(controlData);
  }

  /// Test grubu testi
  Future<Map<String, double>> _runTestGroup(
      List<Map<String, dynamic>> testData
      ) async {
    // Hibrit model testi
    final predictions = await Future.wait(
        testData.map((data) => _getHybridPrediction(data))
    );

    return _calculateMetrics(predictions, testData);
  }

  /// Hibrit tahmin
  Future<int> _getHybridPrediction(Map<String, dynamic> userData) async {
    final agdePred = await _agdeModel.predict(userData);
    final knnPreds = await _knnModel.recommend(userData['userId'], 5);
    final collabPreds = await _collabModel.recommendPrograms(userData['userId'], 5);

    // Ağırlıklı oylama
    final votes = <int, double>{};
    votes[agdePred] = 0.5;

    for (var pred in knnPreds) {
      votes[pred] = (votes[pred] ?? 0) + 0.3 / knnPreds.length;
    }

    for (var pred in collabPreds) {
      votes[pred] = (votes[pred] ?? 0) + 0.2 / collabPreds.length;
    }

    return votes.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Test metriklerini hesaplar
  Map<String, double> _calculateMetrics(
      List<int> predictions,
      List<Map<String, dynamic>> actualData
      ) {
    int correct = 0;
    for (int i = 0; i < predictions.length; i++) {
      if (predictions[i] == actualData[i]['Exercise Recommendation Plan']) {
        correct++;
      }
    }

    final accuracy = correct / predictions.length;
    return {
      'accuracy': accuracy,
      'precision': accuracy, // Basitleştirilmiş metrikler
      'recall': accuracy,
      'f1_score': accuracy,
    };
  }
}
