// lib/ai_services/AGDE_service.dart

import 'dart:math';
import 'package:logging/logging.dart';
import '../Feature.dart';

class AGDEService {
  final _logger = Logger('AGDEService');
  static const int POPULATION_SIZE = 100;
  static const int MAX_GENERATIONS = 10;
  static const double LOWER_BOUND = 0.0;
  static const double UPPER_BOUND = 1.0;
  final Random _random = Random();

  Future<List<double>> calculateWeights(List<Feature> features) async {
    try {
      if (features.isEmpty) {
        _logger.warning('Empty features list provided');
        return [];
      }

      final dimension = features.first.values.length;
      List<List<double>> population = _initializePopulation(dimension);
      List<double> bestSolution = List.filled(dimension, 1.0);
      double bestFitness = double.infinity;

      List<double> crPeriodsCounts = [0, 0];
      List<double> normalizedWeights = [0.5, 0.5];

      for (int generation = 0; generation < MAX_GENERATIONS; generation++) {
        List<int> crPeriodsIndex = List.filled(POPULATION_SIZE, 0);
        List<double> successRates = [0, 0];

        for (int j = 0; j < POPULATION_SIZE; j++) {
          double cr = _selectCR(normalizedWeights, generation);
          crPeriodsIndex[j] = cr < 0.5 ? 0 : 1;
          crPeriodsCounts[crPeriodsIndex[j]]++;

          List<double> trial = _createTrialVector(
            population[j],
            population,
            dimension,
            cr,
          );

          trial = _checkBounds(trial);

          double trialFitness = _calculateFitness(features, trial);
          double currentFitness = _calculateFitness(features, population[j]);

          if (trialFitness <= currentFitness) {
            successRates[crPeriodsIndex[j]]++;
            population[j] = trial;

            if (trialFitness < bestFitness) {
              bestSolution = List.from(trial);
              bestFitness = trialFitness;
              _logger.info('Generation $generation: New best fitness: $bestFitness');
            }
          }
        }

        normalizedWeights = _updateWeights(successRates, crPeriodsCounts);
      }

      return _normalizeSolution(bestSolution);
    } catch (e, stackTrace) {
      _logger.severe('Error calculating weights', e, stackTrace);
      return List.filled(features.first.values.length, 1.0);
    }
  }

  List<List<double>> _initializePopulation(int dimension) {
    return List.generate(
      POPULATION_SIZE,
          (_) => List.generate(
        dimension,
            (_) => LOWER_BOUND + (UPPER_BOUND - LOWER_BOUND) * _random.nextDouble(),
      ),
    );
  }

  double _selectCR(List<double> weights, int generation) {
    return _random.nextDouble() <= weights[0] ?
    0.05 + 0.1 * _random.nextDouble() :
    0.9 + 0.1 * _random.nextDouble();
  }

  List<double> _createTrialVector(
      List<double> current,
      List<List<double>> population,
      int dimension,
      double cr,
      ) {
    List<int> indices = _selectRandomIndices();
    double f = 0.1 + 0.9 * _random.nextDouble();
    int rnd = _random.nextInt(dimension);

    List<double> trial = List.from(current);
    for (int i = 0; i < dimension; i++) {
      if (_random.nextDouble() < cr || i == rnd) {
        trial[i] = population[indices[2]][i] +
            f * (population[indices[0]][i] - population[indices[1]][i]);
      }
    }
    return trial;
  }

  List<int> _selectRandomIndices() {
    Set<int> indices = {};
    while (indices.length < 3) {
      indices.add(_random.nextInt(POPULATION_SIZE));
    }
    return indices.toList();
  }

  List<double> _checkBounds(List<double> vector) {
    return vector.map((x) =>
    x < LOWER_BOUND || x > UPPER_BOUND ?
    LOWER_BOUND + (UPPER_BOUND - LOWER_BOUND) * _random.nextDouble() :
    x
    ).toList();
  }

  double _calculateFitness(List<Feature> features, List<double> weights) {
    double error = 0.0;
    for (var feature in features) {
      double weightedSum = 0.0;
      for (var j = 0; j < feature.values.length; j++) {
        weightedSum += feature.values[j] * weights[j];
      }
      double target = _calculateTargetValue(feature);
      error += pow(target - weightedSum, 2);
    }
    return error / features.length;
  }

  double _calculateTargetValue(Feature feature) {
    // Özellik değerlerine göre hedef değeri hesapla
    double target = 0.0;
    if (feature.values.length >= 5) {
      target += feature.values[0] * 0.4; // ilerleme
      target += feature.values[1] * 0.2; // zorluk/egzersiz sayısı
      target += feature.values[2] * 0.2; // favori mi
      target += feature.values[3] * 0.1; // son kullanım tarihi
      target += feature.values[4] * 0.1; // kullanıcı önerisi
    }
    return target;
  }


  List<double> _updateWeights(List<double> successRates, List<double> counts) {
    for (int i = 0; i < counts.length; i++) {
      if (counts[i] == 0) counts[i] = 0.0001;
    }
    List<double> rates = List.generate(
      successRates.length,
          (i) => successRates[i] / counts[i],
    );
    double sum = rates.reduce((a, b) => a + b);
    return sum == 0 ? [0.5, 0.5] : rates.map((r) => r / sum).toList();
  }

  List<double> _normalizeSolution(List<double> solution) {
    double sum = solution.reduce((a, b) => a + b);
    return solution.map((w) => w / sum).toList();
  }
}