import 'package:collection/collection.dart';

import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import '../models/agde_model.dart';
import '../models/collab_model.dart';
import '../models/knn_model.dart';
import '../ai_data_bloc/dataset_provider.dart';
import '../core/ai_data_processor.dart';

class ModelTester {
  // Singleton pattern
  static final ModelTester _instance = ModelTester._internal();
  factory ModelTester() => _instance;
  ModelTester._internal();

  // Model instances
  final AGDEModel _agdeModel = AGDEModel();
  final KNNModel _knnModel = KNNModel();
  final CollaborativeModel _collabModel = CollaborativeModel();

  // Data handlers
  final AIDataProcessor _dataProcessor = AIDataProcessor();
  final DatasetDBProvider _datasetProvider = DatasetDBProvider();

  /// Model performans testi yapar
  Future<Map<String, Map<String, double>>> testModels() async {
    try {
      // Test verilerini al
      final testData = await _datasetProvider.getCombinedTrainingData();
      final processedData = await _dataProcessor.processTrainingData(testData);

      // Dataset split
      final splits = await _dataProcessor.splitDataset(processedData);
      final testSet = splits['test']!;

      // Her model için test sonuçları
      return {
        'agde': await _testAGDEModel(testSet),
        'knn': await _testKNNModel(testSet),
        'collaborative': await _testCollaborativeModel(testSet),
        'hybrid': await _testHybridModel(testSet)
      };
    } catch (e) {
      throw AIException('Model testing failed: $e');
    }
  }

  /// AGDE model testi
  Future<Map<String, double>> _testAGDEModel(
      List<Map<String, dynamic>> testData
      ) async {
    return await _agdeModel.calculateMetrics(testData);
  }

  /// KNN model testi
  Future<Map<String, double>> _testKNNModel(
      List<Map<String, dynamic>> testData
      ) async {
    final predictions = await Future.wait(
        testData.map((data) => _knnModel.recommend(data['userId'], 5))
    );

    return _calculateMetrics(
        predictions.map((p) => p.first).toList(),
        testData.map((d) => d['Exercise Recommendation Plan'] as int).toList()
    );
  }

  /// Collaborative model testi
  Future<Map<String, double>> _testCollaborativeModel(
      List<Map<String, dynamic>> testData
      ) async {
    final predictions = await Future.wait(
        testData.map((data) =>
            _collabModel.recommendPrograms(data['userId'], 1)
        )
    );

    return _calculateMetrics(
        predictions.map((p) => p.first).toList(),
        testData.map((d) => d['Exercise Recommendation Plan'] as int).toList()
    );
  }

  /// Hibrit model testi
  Future<Map<String, double>> _testHybridModel(
      List<Map<String, dynamic>> testData
      ) async {
    final predictions = await Future.wait(
        testData.map((data) async {
          final agdePred = await _agdeModel.predict(data);
          final knnPreds = await _knnModel.recommend(data['userId'], 5);
          final collabPreds = await _collabModel.recommendPrograms(data['userId'], 5);

          return _combineRecommendations(agdePred, knnPreds, collabPreds).first;
        })
    );

    return _calculateMetrics(
        predictions,
        testData.map((d) => d['Exercise Recommendation Plan'] as int).toList()
    );
  }

  /// Metrikleri hesaplar
  Map<String, double> _calculateMetrics(List<int> predictions, List<int> actuals) {
    int correct = 0;
    for (int i = 0; i < predictions.length; i++) {
      if (predictions[i] == actuals[i]) correct++;
    }

    final accuracy = correct / predictions.length;
    return {
      'accuracy': accuracy,
      'precision': accuracy,
      'recall': accuracy,
      'f1_score': accuracy,
    };
  }

  /// Önerileri birleştirir
  List<int> _combineRecommendations(
      int agdeRec,
      List<int> knnRecs,
      List<int> collabRecs
      ) {
    final votes = <int, double>{};
    votes[agdeRec] = 0.5;

    for (var rec in knnRecs) {
      votes[rec] = (votes[rec] ?? 0) + 0.3 / knnRecs.length;
    }

    for (var rec in collabRecs) {
      votes[rec] = (votes[rec] ?? 0) + 0.2 / collabRecs.length;
    }

    return votes.entries
        .toList()
        .sorted((a, b) => b.value.compareTo(a.value))
        .map((e) => e.key)
        .toList();
  }
}
