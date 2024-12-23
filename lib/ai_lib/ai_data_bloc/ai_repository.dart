// lib/ai_lib/ai_repository.dart
import 'dart:async';
import 'dart:math';
import 'package:logging/logging.dart';
import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import '../models/EnsembleNeuralModel.dart';
import '../models/agde_model.dart';
import '../models/base_model.dart';
import '../models/collab_model.dart';
import '../models/knn_model.dart';
import 'ai_state.dart';
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
  final _datasetProvider = DatasetProvider();



  // Models
  late final EnsembleNeuralModel _EnsembleNeuralModel;
  late final KNNModel _knnModel;
  late final AGDEModel _agdeModel;

  // Repository state
  AIRepositoryState _state = AIRepositoryState.uninitialized;
  AIRepositoryState get state => _state;

  // Stream controllers
  final _metricsController = StreamController<Map<String, Map<String, double>>>.broadcast();
  final _stateController = StreamController<AIRepositoryState>.broadcast();

  // Public streams
  Stream<Map<String, Map<String, double>>> get metricsStream => _metricsController.stream;
  Stream<AIRepositoryState> get stateStream => _stateController.stream;





  Future<void> initialize() async {
    try {
      _updateState(AIRepositoryState.initializing);
      await _datasetProvider.initialize();


      _updateState(AIRepositoryState.ready);
    } catch (e) {
      _logger.severe('Repository initialization failed: $e');
      _updateState(AIRepositoryState.error);
      throw AIInitializationException('Repository initialization failed: $e');
    }
  }

  Future<void> trainModels(String modelType) async {
    _logger.info('Starting model training for type: $modelType');
    try {
      _logger.info('Initializing DatasetProvider for model training...');
      await _datasetProvider.initialize();
      _logger.info('DatasetProvider initialized successfully for all models');

      switch (modelType) {
        case 'AGDE Model':
          _logger.info('Starting AGDE Model training...');
          await runAGDEModel();
          break;
        case 'KNN Model':
          _logger.info('Starting KNN Model training...');
          await runKNNModel();
          break;
        case 'ENN Model':
          _logger.info('Starting ENN Model training...');
          await runENModel();
          break;
        default:
          _logger.severe('Invalid model type requested: $modelType');
          throw AIModelException('Invalid model type: $modelType');
      }
      _logger.info('Model training completed successfully for: $modelType');
    } catch (e, stackTrace) {
      _logger.severe('Model training failed: $e\nStackTrace: $stackTrace');
      throw AIModelException('Model training failed: $e');
    }
  }

  Future<void> runAGDEModel() async {
    _logger.info('=== AGDE Model Training Started ===');
    try {
      _logger.info('Initializing DatasetProvider for AGDE model...');
      await _datasetProvider.initialize();
      _logger.info('DatasetProvider initialized successfully');

      // Model instance'ını sınıf field'ına ata
      _agdeModel = AGDEModel();
      AIStateManager().updateModelState(AIModelState.initializing);
      _logger.info('AGDE model instance created');

      _logger.info('Loading training data...');
      final trainingData = await _datasetProvider.getGymMembersTracking();
      _logger.info('Training data loaded successfully: ${trainingData.length} samples');

      _logger.info('Setting up AGDE model...');
      await _agdeModel.setup(trainingData);
      _logger.info('AGDE model setup completed successfully');
      AIStateManager().updateModelState(AIModelState.initialized);

      _logger.info('Starting AGDE model training...');
      AIStateManager().updateModelState(AIModelState.training);

      var generationCount = 0;
      _agdeModel.trainingProgress.listen((progress) {
        generationCount++;
        _logger.info('''
      === Training Progress ===
      Generation: ${progress.generation}
      Best Fitness: ${progress.bestFitness.toStringAsFixed(6)}
      Average Fitness: ${progress.avgFitness.toStringAsFixed(6)}
      Current State: ${progress.state}
      Progress: ${(progress.generation / AIConstants.MAX_GENERATIONS * 100).toStringAsFixed(2)}%
      ''');
        AIStateManager().updateProgress(progress.generation / AIConstants.MAX_GENERATIONS);
      });

      await _agdeModel.fit(trainingData);
      _logger.info('AGDE model training completed successfully');

      _logger.info('Starting model validation...');
      AIStateManager().updateModelState(AIModelState.validating);
      final metrics = await _agdeModel.calculateMetrics(trainingData);
      _logger.info('''
    === Model Metrics ===
    ${metrics.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(4)}').join('\n    ')}
    ''');

      _logger.info('Saving AGDE model...');
      await saveModel(_agdeModel);
      _logger.info('AGDE model saved successfully');

    } catch (e, stackTrace) {
      _logger.severe('''
    AGDE model execution failed:
    Error: $e
    StackTrace: $stackTrace
    ''');
      AIStateManager().updateModelState(AIModelState.error);
      throw AIModelException('AGDE model execution failed: $e');
    } finally {
      _logger.info('Cleaning up AGDE model resources...');
      AIStateManager().updateModelState(AIModelState.disposed);
      if (_agdeModel != null) {
        await _agdeModel.dispose();
      }
      _logger.info('=== AGDE Model Training Completed ===');
    }
  }

  Future<void> runKNNModel() async {
    _logger.info('=== KNN Model Training Started ===');
    try {
      // DatasetProvider zaten sınıf seviyesinde tanımlı, yeni instance oluşturmaya gerek yok
      await _datasetProvider.initialize();
      _logger.info('DatasetProvider initialized for KNN model');

      final knnModel = KNNModel();
      AIStateManager().updateModelState(AIModelState.initializing);

      _logger.info('Loading training data...');
      final trainingData = await _datasetProvider.getGymMembersTracking();
      _logger.info('''
    Training data loaded successfully:
    - Sample count: ${trainingData.length}
    - Data type: ${trainingData.runtimeType}
    ''');

      _logger.info('Setting up KNN model...');
      await knnModel.setup(trainingData);
      _logger.info('KNN model setup completed successfully');
      AIStateManager().updateModelState(AIModelState.initialized);

      _logger.info('Starting KNN model training...');
      AIStateManager().updateModelState(AIModelState.training);
      await knnModel.fit(trainingData);
      _logger.info('KNN model training completed successfully');

      _logger.info('Starting model validation...');
      AIStateManager().updateModelState(AIModelState.validating);
      final metrics = await knnModel.calculateMetrics(trainingData);
      _logger.info('''
    === Model Metrics ===
    ${metrics.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(4)}').join('\n    ')}
    ''');

      _logger.info('Saving KNN model...');
      await saveModel(knnModel);
      _logger.info('KNN model saved successfully');

    } catch (e, stackTrace) {
      _logger.severe('''
    KNN model execution failed:
    Error: $e
    StackTrace: $stackTrace
    ''');
      AIStateManager().updateModelState(AIModelState.error);
      throw AIModelException('KNN model execution failed: $e');
    } finally {
      _logger.info('Cleaning up KNN model resources...');
      AIStateManager().updateModelState(AIModelState.disposed);
      await _knnModel.dispose();
      _logger.info('=== KNN Model Training Completed ===');
    }
  }

  Future<void> runENModel() async {
    _logger.info('=== ENN Model Training Started ===');
    try {
      await _datasetProvider.initialize();
      _logger.info('DatasetProvider initialized for ENN model');

      final ennModel = EnsembleNeuralModel();
      AIStateManager().updateModelState(AIModelState.initializing);

      _logger.info('Loading training data...');
      final trainingData = await _datasetProvider.getGymMembersTracking();
      _logger.info('''
    Training data loaded successfully:
    - Sample count: ${trainingData.length}
    - Data type: ${trainingData.runtimeType}
    ''');

      _logger.info('Setting up ENN model...');
      await ennModel.setup(trainingData);
      _logger.info('ENN model setup completed successfully');
      AIStateManager().updateModelState(AIModelState.initialized);

      _logger.info('Starting ENN model training...');
      AIStateManager().updateModelState(AIModelState.training);
      await ennModel.fit(trainingData);
      _logger.info('ENN model training completed successfully');

      _logger.info('Starting model validation...');
      AIStateManager().updateModelState(AIModelState.validating);
      final metrics = await ennModel.calculateMetrics(trainingData);
      _logger.info('''
    === Model Metrics ===
    ${metrics.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(4)}').join('\n    ')}
    ''');

      _logger.info('Saving ENN model...');
      await saveModel(ennModel);
      _logger.info('ENN model saved successfully');

    } catch (e, stackTrace) {
      _logger.severe('''
    ENN model execution failed:
    Error: $e
    StackTrace: $stackTrace
    ''');
      AIStateManager().updateModelState(AIModelState.error);
      throw AIModelException('ENN model execution failed: $e');
    } finally {
      _logger.info('Cleaning up ENN model resources...');
      AIStateManager().updateModelState(AIModelState.disposed);
      await _EnsembleNeuralModel.dispose();
      _logger.info('=== ENN Model Training Completed ===');
    }
  }


  Future<void> saveModel(BaseModel model) async {
    try {
      final modelJson = model.toJson();
      final modelType = model.runtimeType.toString();
      await _datasetProvider.saveModelData(
          modelType: modelType,
          modelData: modelJson,
          timestamp: DateTime.now()
      );
      _logger.info('$modelType model saved successfully');
    } catch (e) {
      _logger.severe('Model saving failed: $e');
      throw AIModelException('Model saving failed: $e');
    }
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
    await _EnsembleNeuralModel.dispose();
    await _knnModel.dispose();
    await _agdeModel.dispose();
    await _datasetProvider.dispose();
    _state = AIRepositoryState.uninitialized;
  }




}
