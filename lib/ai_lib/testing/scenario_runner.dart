// lib/ai_lib/testing/scenario_runner.dart
import 'package:logging/logging.dart';
import '../ai_data_bloc/ai_repository.dart';
import '../core/ai_constants.dart';
import '../core/ai_exceptions.dart';
import '../core/trainingConfig.dart';

enum ScenarioResultType { success, failure, partial, skipped, error }
enum ScenarioType { userProgression, workoutPlanning, modelAdaptation, stressTest }
enum ScenarioStatus { notStarted, running, completed, failed, skipped }

class ScenarioConfig {
  final String scenarioName;
  final ScenarioType type;
  final Map<String, dynamic> parameters;
  final Duration timeout;
  final bool stopOnFailure;
  final Map<String, dynamic>? expectedResults;
  final List<String>? dependencies;

  ScenarioConfig({
    required this.scenarioName,
    required this.type,
    required this.parameters,
    this.timeout = const Duration(minutes: 5),
    this.stopOnFailure = true,
    this.expectedResults,
    this.dependencies,
  });
}

class ScenarioResult {
  final String scenarioName;
  final List<Map<String, dynamic>> stepResults = [];
  final List<String> errors = [];
  ScenarioStatus status = ScenarioStatus.notStarted;
  final Map<String, double> metrics = {};
  ScenarioResultType resultType = ScenarioResultType.success;

  ScenarioResult(this.scenarioName);

  void addResult(Map<String, dynamic> result) => stepResults.add(result);
  void addError(String error) => errors.add(error);
  void updateMetrics(Map<String, double> newMetrics) => metrics.addAll(newMetrics);

  bool get isSuccess => resultType == ScenarioResultType.success;
  bool get isFailure => resultType == ScenarioResultType.failure;
}

class ScenarioRunner {
  final Logger _logger = Logger('ScenarioRunner');
  final AIRepository _aiRepository;
  final Map<String, ScenarioResult> _results = {};
  bool _isRunning = false;

  ScenarioRunner(this._aiRepository);

  // Repository'nin hazır olduğundan emin olmak için kontrol metodu
  Future<void> _ensureRepositoryReady() async {
    if (_aiRepository.state == AIRepositoryState.uninitialized) {
      await _aiRepository.initialize();
    }

    if (_aiRepository.state != AIRepositoryState.ready) {
      throw AITestingException('Repository is not ready: ${_aiRepository.state}');
    }
  }

  Future<Map<String, ScenarioResult>> runScenario(ScenarioConfig config) async {
    if (_isRunning) {
      throw AITestingException('A scenario is already running');
    }

    _isRunning = true;
    final result = ScenarioResult(config.scenarioName);

    try {
      await _ensureRepositoryReady();
      result.status = ScenarioStatus.running;

      // Timeout kontrolü ekle
      final scenarioFuture = _executeScenario(config);
      final metrics = await Future.any([
        scenarioFuture,
        Future.delayed(config.timeout)
            .then((_) => throw AITestingException('Scenario timeout')),
      ]);

      result.updateMetrics(_convertToDoubleMetrics(metrics));

      if (config.expectedResults != null) {
        _validateResults(metrics, config.expectedResults!);
      }

      result.status = ScenarioStatus.completed;
      result.resultType = ScenarioResultType.success;

    } catch (e) {
      result.status = ScenarioStatus.failed;
      result.resultType = ScenarioResultType.failure;
      result.addError(e.toString());
      _logger.severe('Scenario failed: ${config.scenarioName}', e);

      if (config.stopOnFailure) {
        rethrow;
      }
    } finally {
      _isRunning = false;
      _results[config.scenarioName] = result;
    }

    return Map.from(_results);
  }

  Future<Map<String, dynamic>> _executeScenario(ScenarioConfig config) async {
    switch (config.type) {
      case ScenarioType.userProgression:
        return await _runUserProgressionScenario(config);
      case ScenarioType.workoutPlanning:
        return await _runWorkoutPlanningScenario(config);
      case ScenarioType.modelAdaptation:
        return await _runModelAdaptationScenario(config);
      case ScenarioType.stressTest:
        return await _runStressTestScenario(config) ?? {};
      default:
        throw AITestingException('Unknown scenario type');
    }
  }

  Future<Map<String, dynamic>> _runUserProgressionScenario(ScenarioConfig config) async {
    try {
      final results = <String, dynamic>{};
      final trainingConfig = TrainingConfig(
        epochs: config.parameters['epochs'] ?? AIConstants.EPOCHS,
        batchSize: config.parameters['batch_size'] ?? AIConstants.BATCH_SIZE,
        learningRate: config.parameters['learning_rate'] ?? AIConstants.LEARNING_RATE,
      );

      // Model eğitimini başlat
      await _aiRepository.trainModels(
        config: trainingConfig,
        useBatchProcessing: true,
      );

      // Model metriklerini al
      final metrics = await _aiRepository.metricsStream.first;

      return {
        'type': 'user_progression',
        'results': results,
        'metrics': metrics,
      };
    } catch (e) {
      _logger.severe('User progression scenario failed', e);
      throw AITestingException('User scenario failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> _runWorkoutPlanningScenario(ScenarioConfig config) async {
    try {
      // TrainingConfig oluştur
      final trainingConfig = TrainingConfig(
        epochs: config.parameters['epochs'] ?? AIConstants.EPOCHS,
        batchSize: config.parameters['batch_size'] ?? AIConstants.BATCH_SIZE,
        validationSplit: config.parameters['validation_split'] ?? AIConstants.VALIDATION_SPLIT,
      );

      // Modeli eğit
      await _aiRepository.trainModels(
        config: trainingConfig,
        useBatchProcessing: true,
      );

      // Metrikleri topla
      final metrics = await _aiRepository.metricsStream.first;

      return {
        'type': 'workout_planning',
        'metrics': metrics,
        'training_config': trainingConfig,
      };

    } catch (e) {
      _logger.severe('Workout planning scenario failed', e);
      throw AITestingException('Workout scenario failed: ${e.toString()}');
    }
  }





  Map<String, double> _convertToDoubleMetrics(Map<String, dynamic> metrics) {
    final Map<String, double> doubleMetrics = {};

    metrics.forEach((key, value) {
      if (value is num) {
        doubleMetrics[key] = value.toDouble();
      } else if (value is String) {
        // Try to parse string to double if possible
        try {
          doubleMetrics[key] = double.parse(value);
        } catch (e) {
          _logger.warning('Could not convert metric $key to double: $value');
        }
      }
    });

    return doubleMetrics;
  }

  void _validateResults(Map<String, dynamic> actual, Map<String, dynamic> expected) {
    for (final key in expected.keys) {
      if (!actual.containsKey(key)) {
        throw AITestingException('Missing expected result: $key');
      }

      final actualValue = actual[key];
      final expectedValue = expected[key];

      if (expectedValue is num && actualValue is num) {
        // Allow for small floating-point differences
        if ((actualValue - expectedValue).abs() > AIConstants.EPSILON) {
          throw AITestingException(
            'Result mismatch for $key: expected $expectedValue, got $actualValue',
          );
        }
      } else if (actualValue != expectedValue) {
        throw AITestingException(
          'Result mismatch for $key: expected $expectedValue, got $actualValue',
        );
      }
    }
  }

// scenario_runner.dart içinde:
  Future<Map<String, dynamic>> _runModelAdaptationScenario(ScenarioConfig config) async {
    try {
      final trainingConfig = TrainingConfig(
        epochs: config.parameters['epochs'] ?? AIConstants.EPOCHS,
        batchSize: config.parameters['batch_size'] ?? AIConstants.BATCH_SIZE,
        learningRate: config.parameters['learning_rate'] ?? AIConstants.LEARNING_RATE,
      );

      // adaptModel yerine trainModels kullan
      await _aiRepository.trainModels(
          config: trainingConfig,
          useBatchProcessing: true
      );

      // Metrikleri topla
      final metrics = await _aiRepository.metricsStream.first;

      return {
        'type': 'model_adaptation',
        'metrics': metrics,
        'training_config': trainingConfig,
      };
    } catch (e) {
      _logger.severe('Model adaptation scenario failed', e);
      throw AITestingException('Adaptation scenario failed: ${e.toString()}');
    }
  }

  // scenario_runner.dart içinde:
  Future<Map<String, dynamic>?> _runStressTestScenario(ScenarioConfig config) async {
    try {
      final iterations = config.parameters['iterations'] ?? 100;
      final concurrentUsers = config.parameters['concurrent_users'] ?? 10;
      final results = <Map<String, dynamic>>[];

      // Stress test iterations
      for (var i = 0; i < iterations; i++) {
        final startTime = DateTime.now();

        // Simulate concurrent users using getProgramRecommendation
        final futures = List.generate(concurrentUsers, (index) async {
          try {
            final userProfile = UserProfile(
              id: 'test_user_$index',
              weight: 70.0,
              height: 1.75,
              age: 25,
              gender: 'M',
              experienceLevel: 1,
              bmi: 22.9,
            );

            final recommendation = await _aiRepository.getProgramRecommendation(
                userProfile: userProfile
            );

            return {
              'success': true,
              'recommendation': {
                'plan_id': recommendation.planId,
                'bmi_case': recommendation.bmiCase,
                'bfp_case': recommendation.bfpCase,
                'confidence_score': recommendation.confidenceScore,
              }
            };
          } catch (e) {
            return {
              'success': false,
              'error': e.toString()
            };
          }
        });

        final responses = await Future.wait(futures);
        final endTime = DateTime.now();

        results.add({
          'iteration': i,
          'response_time': endTime.difference(startTime).inMilliseconds,
          'success_rate': responses.where((r) => r['success'] == true).length / concurrentUsers,
        });
      }

      // Calculate performance metrics
      final avgResponseTime = results
          .map((r) => r['response_time'] as int)
          .reduce((a, b) => a + b) / results.length;

      final avgSuccessRate = results
          .map((r) => r['success_rate'] as double)
          .reduce((a, b) => a + b) / results.length;

      return {
        'type': 'stress_test',
        'performance': {
          'avg_response_time': avgResponseTime,
          'success_rate': avgSuccessRate,
        },
        'results': results,
      };

    } catch (e) {
      _logger.severe('Stress test scenario failed', e);
      throw AITestingException('Stress test scenario failed: ${e.toString()}');
    }
  }



}