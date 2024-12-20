import 'dart:async';
import 'package:collection/collection.dart';

import '../core/ai_constants.dart';
import '../core/ai_data_processor.dart';
import '../core/ai_exceptions.dart';
import '../models/agde_model.dart';
import '../models/collab_model.dart';
import '../models/knn_model.dart';
import 'dataset_provider.dart';


class AIRepository {
  // Singleton pattern
  static final AIRepository _instance = AIRepository._internal();
  factory AIRepository() => _instance;
  AIRepository._internal();

  // Model instances
  final AGDEModel _agdeModel = AGDEModel();
  final KNNModel _knnModel = KNNModel();
  final CollaborativeModel _collabModel = CollaborativeModel();

  // Data handlers
  final AIDataProcessor _dataProcessor = AIDataProcessor();
  final DatasetDBProvider _datasetProvider = DatasetDBProvider();

  // Stream controllers
  final StreamController<Map<String, double>> _metricsController =
  StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get metricsStream => _metricsController.stream;

  // Model states
  final Map<String, bool> _modelStates = {
    'agde_initialized': false,
    'agde_trained': false,
    'knn_initialized': false,
    'collab_initialized': false,
  };

  // Training metrics
  final Map<String, Map<String, double>> _modelMetrics = {
    'agde': {
      'accuracy': 0.0,
      'precision': 0.0,
      'recall': 0.0,
      'f1_score': 0.0,
    },
    'knn': {
      'accuracy': 0.0,
      'precision': 0.0,
      'recall': 0.0,
      'f1_score': 0.0,
    },
    'collaborative': {
      'accuracy': 0.0,
      'precision': 0.0,
      'recall': 0.0,
      'f1_score': 0.0,
    },
  };

  // Cache management
  final Map<int, List<int>> _recommendationCache = {};
  static const Duration _cacheDuration = Duration(hours: 1);
  DateTime _lastCacheCleanup = DateTime.now();

  // Recommendation weights
  final Map<String, double> _recommendationWeights = {
    'agde': 0.5,
    'knn': 0.3,
    'collaborative': 0.2,
  };

  /// Repository'yi initialize eder
  Future<void> initialize() async {

      await _datasetProvider.initDatabase();

      // Veri kontrolü
      await _datasetProvider.testDatabaseContent(); // Her tablodan en az bir veri alıp almadığınızı kontrol edin



    try {
      // Dataset yükleme
      final trainingData = await _datasetProvider.getCombinedTrainingData();
      final processedData = await _dataProcessor.processTrainingData(trainingData);

      // Model initialization
      await _agdeModel.initialize();
      await _knnModel.initialize(processedData);
      await _collabModel.initialize(
          await _getUserCount(),
          await _getProgramCount()
      );

      // Model durumlarını güncelle
      _modelStates['agde_initialized'] = true;
      _modelStates['knn_initialized'] = true;
      _modelStates['collab_initialized'] = true;

      // AGDE model metriklerini dinle
      _agdeModel.metricsStream.listen((metrics) {
        _updateMetrics('agde', metrics);
        _metricsController.add(metrics);
      });

    } catch (e) {
      print("Model başlatma hatası: $e");
      throw AIException('Repository initialization failed: $e');
    }
  }

  /// Modelleri eğitir
  Future<void> trainModels() async {
    try {
      final trainingData = await _datasetProvider.getCombinedTrainingData();
      final processedData = await _dataProcessor.processTrainingData(trainingData);

      // Dataset split
      final splits = await _dataProcessor.splitDataset(processedData);

      // AGDE model eğitimi
      await _agdeModel.train(splits['train']!);
      _modelStates['agde_trained'] = true;

      // Diğer modeller için güncelleme
      await _knnModel.calculateSimilarities();
      await _collabModel.calculateSimilarityMatrix();

      // Validation
      await _updateAllMetrics(splits['validation']!);

    } catch (e) {
      throw AIException('Model training failed: $e');
    }
  }

  /// Program önerisi yapar
  Future<Map<String, dynamic>> recommendProgram(Map<String, dynamic> userData) async {
    _checkInitialization();
    _cleanupCache();

    try {
      final userId = userData['userId'] as int;

      // Cache kontrol
      if (_recommendationCache.containsKey(userId)) {
        return {'recommendations': _recommendationCache[userId]};
      }

      final processedData = await _dataProcessor.processRawData(userData);

      // Model önerileri
      final agdeRecommendation = await _agdeModel.predict(processedData);
      final knnRecommendations = await _knnModel.recommend(
          userId,
          AIConstants.KNN_NEIGHBORS_COUNT
      );
      final collabRecommendations = await _collabModel.recommendPrograms(
          userId,
          AIConstants.COLLAB_RECOMMENDATIONS_COUNT
      );

      // Önerileri birleştir
      final combinedRecommendations = await _combineRecommendations(
          agdeRecommendation,
          knnRecommendations,
          collabRecommendations
      );

      // Cache'e kaydet
      _recommendationCache[userId] = combinedRecommendations;

      return {
        'recommendations': combinedRecommendations,
        'metrics': _modelMetrics
      };

    } catch (e) {
      throw AIException('Recommendation failed: $e');
    }
  }

  /// Private helper methods
  Future<int> _getUserCount() async {
    final data = await _datasetProvider.getBMIDataset();
    return data.length;
  }

  Future<int> _getProgramCount() async {
    final data = await _datasetProvider.getExerciseTrackingData();
    return data.where((e) => e['Workout_Type'] != null).toSet().length;
  }

  void _checkInitialization() {
    if (!_modelStates.values.every((state) => state)) {
      throw AIException('Not all models are initialized');
    }
  }

  Future<List<int>> _combineRecommendations(
      int agdeRec,
      List<int> knnRecs,
      List<int> collabRecs
      ) async {
    final weightedRecommendations = <int, double>{};

    weightedRecommendations[agdeRec] = _recommendationWeights['agde']!;

    for (var rec in knnRecs) {
      weightedRecommendations[rec] =
          (weightedRecommendations[rec] ?? 0) +
              _recommendationWeights['knn']! / knnRecs.length;
    }

    for (var rec in collabRecs) {
      weightedRecommendations[rec] =
          (weightedRecommendations[rec] ?? 0) +
              _recommendationWeights['collaborative']! / collabRecs.length;
    }

    return weightedRecommendations.entries
        .toList()
        .sorted((a, b) => b.value.compareTo(a.value))
        .map((e) => e.key)
        .toList();
  }

  void _cleanupCache() {
    final now = DateTime.now();
    if (now.difference(_lastCacheCleanup) > _cacheDuration) {
      _recommendationCache.clear();
      _lastCacheCleanup = now;
    }
  }

  Future<void> _updateAllMetrics(List<Map<String, dynamic>> validationData) async {
    final agdeMetrics = await _agdeModel.calculateMetrics(validationData);
    _updateMetrics('agde', agdeMetrics);
  }

  void _updateMetrics(String modelName, Map<String, double> metrics) {
    _modelMetrics[modelName]?.addAll(metrics);
    _metricsController.add(_modelMetrics[modelName]!);
  }

  /// Dispose
  void dispose() {
    _metricsController.close();
  }
}
