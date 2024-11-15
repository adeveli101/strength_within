// lib/ai_services/KNN_service.dart

import 'dart:math';
import 'package:logging/logging.dart';
import '../Feature.dart';

class KNNService {
  final _logger = Logger('KNNService');
  final int k; // k değeri

  KNNService({this.k = 3}); // Varsayılan k=3

  double calculateError(List<Feature> trainFeatures, List<Feature> testFeatures) {
    try {
      final testCount = testFeatures.length;
      final trainCount = trainFeatures.length;

      if (testCount == 0 || trainCount == 0) {
        _logger.warning('Empty feature sets provided');
        return 100.0; // %100 hata
      }

      // Mesafe matrisini hesapla
      List<List<_DistanceItem>> distances = [];
      int trueCount = 0;
      int falseCount = 0;

      for (int i = 0; i < testCount; i++) {
        List<_DistanceItem> distanceRow = [];

        for (int j = 0; j < trainCount; j++) {
          double distance = _calculateDistance(
            testFeatures[i].values,
            trainFeatures[j].values,
          );

          distanceRow.add(_DistanceItem(
            distance: distance,
            index: j,
            id: trainFeatures[j].id,
          ));
        }

        // Mesafeleri sırala
        distanceRow.sort((a, b) => a.distance.compareTo(b.distance));
        distances.add(distanceRow);

        // En yakın k komşuya göre sınıflandırma yap
        int predictedClass = _findClass(
          distanceRow.take(k).map((d) => d.id).toList(),
        );

        // Doğruluk kontrolü
        if (predictedClass == testFeatures[i].id) {
          trueCount++;
        } else {
          falseCount++;
        }
      }

      // Hata oranını hesapla
      return (100 * falseCount) / testCount;
    } catch (e, stackTrace) {
      _logger.severe('Error calculating KNN error', e, stackTrace);
      return 100.0;
    }
  }

  double _calculateDistance(List<double> test, List<double> train) {
    if (test.length != train.length) {
      throw Exception('Feature vectors must have same length');
    }

    double sumSquared = 0.0;
    for (int i = 0; i < test.length; i++) {
      sumSquared += pow(train[i] - test[i], 2);
    }
    return sqrt(sumSquared);
  }

  int _findClass(List<int> nearestIds) {
    // En çok tekrar eden ID'yi bul
    Map<int, int> frequency = {};
    int maxFreq = 0;
    int predictedClass = nearestIds.first;

    for (int id in nearestIds) {
      frequency[id] = (frequency[id] ?? 0) + 1;
      if (frequency[id]! > maxFreq) {
        maxFreq = frequency[id]!;
        predictedClass = id;
      }
    }

    return predictedClass;
  }

  List<Feature> classifyFeatures(List<Feature> trainFeatures, List<Feature> testFeatures) {
    try {
      if (testFeatures.isEmpty || trainFeatures.isEmpty) {
        return testFeatures;
      }

      List<Feature> classifiedFeatures = [];

      for (var testFeature in testFeatures) {
        // En yakın k komşuyu bul
        var neighbors = _findNearestNeighbors(testFeature, trainFeatures);

        // Sınıflandırma yap
        int predictedClass = _findClass(
          neighbors.take(k).map((n) => n.id).toList(),
        );

        // Yeni özellik vektörü oluştur
        classifiedFeatures.add(Feature(
          id: predictedClass,
          values: testFeature.values,
        ));
      }

      return classifiedFeatures;
    } catch (e, stackTrace) {
      _logger.severe('Error classifying features', e, stackTrace);
      return testFeatures;
    }
  }

  List<_DistanceItem> _findNearestNeighbors(Feature test, List<Feature> trainFeatures) {
    List<_DistanceItem> distances = trainFeatures.map((train) {
      return _DistanceItem(
        distance: _calculateDistance(test.values, train.values),
        index: trainFeatures.indexOf(train),
        id: train.id,
      );
    }).toList();

    distances.sort((a, b) => a.distance.compareTo(b.distance));
    return distances;
  }
}

class _DistanceItem {
  final double distance;
  final int index;
  final int id;

  _DistanceItem({
    required this.distance,
    required this.index,
    required this.id,
  });
}