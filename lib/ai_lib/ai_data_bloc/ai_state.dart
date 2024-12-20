// lib/ai_lib/core/ai_state.dart

import 'dart:async';

import 'package:logging/logging.dart';

enum AIModelState {
  uninitialized,
  initializing,
  initialized,
  training,
  validating,
  inferencing,
  error,
  disposed
}

enum AIDataState {
  empty,
  loading,
  processing,
  ready,
  error
}

enum AIRecommendationState {
  idle,
  generating,
  ready,
  error
}

// lib/ai_lib/core/ai_error.dart

enum AIErrorType {
  model,
  data,
  recommendation,
  validation,
  initialization,
  training,
  prediction,
  resource
}

class AIError {
  final String message;
  final AIErrorType type;
  final String? code;
  final dynamic details;
  final StackTrace? stackTrace;

  AIError(
      this.message, {
        this.type = AIErrorType.model,
        this.code,
        this.details,
        this.stackTrace,
      });

  @override
  String toString() {
    return 'AIError: $message (Type: $type, Code: $code)';
  }
}



class AIStateManager {
  // Singleton pattern
  static final AIStateManager _instance = AIStateManager._internal();
  factory AIStateManager() => _instance;
  AIStateManager._internal();

  final _logger = Logger('AIStateManager');

  // State controllers
  final _modelStateController = StreamController<AIModelState>.broadcast();
  final _dataStateController = StreamController<AIDataState>.broadcast();
  final _recommendationStateController = StreamController<AIRecommendationState>.broadcast();
  final _errorController = StreamController<AIError>.broadcast();
  final _metricsController = StreamController<Map<String, double>>.broadcast();
  final _progressController = StreamController<double>.broadcast();

  // Public streams
  Stream<AIModelState> get modelState => _modelStateController.stream;
  Stream<AIDataState> get dataState => _dataStateController.stream;
  Stream<AIRecommendationState> get recommendationState => _recommendationStateController.stream;
  Stream<AIError> get errors => _errorController.stream;
  Stream<Map<String, double>> get metrics => _metricsController.stream;
  Stream<double> get progress => _progressController.stream;

  // Current states
  AIModelState _currentModelState = AIModelState.uninitialized;
  AIDataState _currentDataState = AIDataState.empty;
  AIRecommendationState _currentRecommendationState = AIRecommendationState.idle;

  // State update methods
  void updateModelState(AIModelState newState) {
    _currentModelState = newState;
    _modelStateController.add(newState);
    _logger.info('Model state updated to: $newState');
  }

  void updateDataState(AIDataState newState) {
    _currentDataState = newState;
    _dataStateController.add(newState);
    _logger.info('Data state updated to: $newState');
  }

  void updateRecommendationState(AIRecommendationState newState) {
    _currentRecommendationState = newState;
    _recommendationStateController.add(newState);
    _logger.info('Recommendation state updated to: $newState');
  }

  void updateMetrics(Map<String, double> metrics) {
    _metricsController.add(metrics);
  }

  void updateProgress(double progress) {
    _progressController.add(progress);
  }

  void handleError(AIError error) {
    _errorController.add(error);
    _logger.severe('AI Error: ${error.message}');

    // Update related states to error
    if (error.type == AIErrorType.model) {
      updateModelState(AIModelState.error);
    } else if (error.type == AIErrorType.data) {
      updateDataState(AIDataState.error);
    } else if (error.type == AIErrorType.recommendation) {
      updateRecommendationState(AIRecommendationState.error);
    }
  }

  // State validation methods
  bool canTrain() {
    return _currentModelState == AIModelState.initialized &&
        _currentDataState == AIDataState.ready;
  }

  bool canPredict() {
    return _currentModelState == AIModelState.initialized &&
        _currentRecommendationState != AIRecommendationState.generating;
  }

  // Resource cleanup
  Future<void> dispose() async {
    await _modelStateController.close();
    await _dataStateController.close();
    await _recommendationStateController.close();
    await _errorController.close();
    await _metricsController.close();
    await _progressController.close();

    _currentModelState = AIModelState.disposed;
    _currentDataState = AIDataState.empty;
    _currentRecommendationState = AIRecommendationState.idle;

    _logger.info('AIStateManager disposed');
  }
}
