// lib/ai_lib/ai_repository.dart
import 'dart:async';
import 'dart:math';
import 'package:logging/logging.dart';
import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import '../models/agde_model.dart';
import '../models/collab_model.dart';
import '../models/knn_model.dart';
import 'dataset_provider.dart';
import 'datasets_models.dart';

enum AIRepositoryState {
  uninitialized,
  initializing,
  ready,
  training,
  error
}

class AIRepository {
  // Singleton pattern
  static final AIRepository _instance = AIRepository._internal();
  factory AIRepository() => _instance;
  AIRepository._internal();

  final _logger = Logger('AIRepository');
  final _datasetProvider = DatasetDBProvider();

  // Models
  late final AGDEModel _agdeModel;
  late final KNNModel _knnModel;
  late final CollaborativeFilteringModel _collabModel;

  // Repository state
  AIRepositoryState _state = AIRepositoryState.uninitialized;
  AIRepositoryState get state => _state;

  // Stream controllers
  final _metricsController = StreamController<Map<String, Map<String, double>>>.broadcast();
  final _stateController = StreamController<AIRepositoryState>.broadcast();

  // Public streams
  Stream<Map<String, Map<String, double>>> get metricsStream => _metricsController.stream;
  Stream<AIRepositoryState> get stateStream => _stateController.stream;

  // Model weights
  final Map<String, double> _modelWeights = {
    'agde': 0.4,
    'knn': 0.3,
    'collaborative': 0.3,
  };

  Future<void> initialize() async {
    if (_state != AIRepositoryState.uninitialized) return;

    try {
      _updateState(AIRepositoryState.initializing);

      // Initialize models
      _agdeModel = AGDEModel();
      _knnModel = KNNModel();
      _collabModel = CollaborativeFilteringModel();

      // Get training data
      final List<GymMembersTracking> trackingData = await _datasetProvider.getExerciseTrackingData()
          .then((data) => data.map((d) => GymMembersTracking.fromMap(d)).toList());

      final List<FinalDatasetBFP> bfpData = await _datasetProvider.getBFPDataset()
          .then((data) => data.map((d) => FinalDatasetBFP.fromMap(d)).toList());

      final List<FinalDataset> baseData = await _datasetProvider.getBMIDataset()
          .then((data) => data.map((d) => FinalDataset.fromMap(d)).toList());

      // Setup models
      await Future.wait([
        _agdeModel.setup(trackingData),
        _knnModel.setup(bfpData),
        _collabModel.setup(baseData)
      ]);

      _updateState(AIRepositoryState.ready);
      _logger.info('AI Repository initialized successfully');
    } catch (e) {
      _updateState(AIRepositoryState.error);
      _logger.severe('Repository initialization failed: $e');
      throw AIInitializationException('Repository initialization failed: $e');
    }
  }

  Future<void> trainModels() async {
    if (_state != AIRepositoryState.ready) {
      throw AITrainingException('Repository not ready for training');
    }

    try {
      _updateState(AIRepositoryState.training);

      final trackingData = await _datasetProvider.getExerciseTrackingData()
          .then((data) => data.map((d) => GymMembersTracking.fromMap(d)).toList());

      await Future.wait([
        _trainAGDEModel(trackingData),
        _trainKNNModel(trackingData),
        _trainCollabModel(trackingData)
      ]);

      _updateState(AIRepositoryState.ready);
    } catch (e) {
      _updateState(AIRepositoryState.error);
      throw AITrainingException('Training failed: $e');
    }
  }



  Future<FinalDataset> getProgramRecommendation(GymMembersTracking profile) async {
    if (_state != AIRepositoryState.ready) {
      throw AIException('Repository not ready');
    }

    try {
      final predictions = await Future.wait([
        _agdeModel.predict(profile),
        _knnModel.predict(profile),
        _collabModel.predict(profile)
      ]);

      return _combineModelPredictions(predictions);
    } catch (e) {
      _logger.severe('Program recommendation failed: $e');
      throw AIException('Failed to get program recommendation: $e');
    }
  }

  FinalDataset _combineModelPredictions(List<FinalDataset> predictions) {
    0; // ID'yi burada belirtin
    double weightSum = 0;
    double heightSum = 0;
    double bmiSum = 0;
    Map<String, int> genderVotes = {};
    int ageSum = 0;
    Map<String, int> bmiCaseVotes = {};
    int exercisePlanSum = 0;

    for (var i = 0; i < predictions.length; i++) {
      final weight = _modelWeights.values.elementAt(i); // Her modelin ağırlığını al
      final pred = predictions[i];

      // Ağırlıklı toplamları hesapla
      weightSum += pred.weight * weight;
      heightSum += pred.height * weight;
      bmiSum += pred.bmi * weight;

      // Cinsiyet oylaması
      genderVotes[pred.gender] = (genderVotes[pred.gender] ?? 0) + 1;

      // Yaş toplamı
      ageSum += pred.age;

      // BMI durumu oylaması
      bmiCaseVotes[pred.bmiCase] = (bmiCaseVotes[pred.bmiCase] ?? 0) + 1;

      // Egzersiz planı toplamı
      exercisePlanSum += pred.exercisePlan;
    }

    return FinalDataset(
        id: 0,
        weight: weightSum / predictions.length,
        height: heightSum / predictions.length,
        bmi: bmiSum / predictions.length,
        gender: genderVotes.entries.reduce((a, b) => a.value > b.value ? a : b).key,
        age: (ageSum / predictions.length).round(),
        bmiCase: bmiCaseVotes.entries.reduce((a, b) => a.value > b.value ? a : b).key,
        exercisePlan: (exercisePlanSum / predictions.length).round()
    );
  }

  void _updateState(AIRepositoryState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void _updateMetrics(Map<String, Map<String, double>> metrics) {
    _metricsController.add(metrics);
  }

  Future<void> dispose() async {
    await _metricsController.close();
    await _stateController.close();
    await _agdeModel.dispose();
    await _knnModel.dispose();
    await _collabModel.dispose();
    _state = AIRepositoryState.uninitialized;
  }
}
