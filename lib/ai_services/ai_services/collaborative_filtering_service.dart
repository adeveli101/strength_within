// lib/services/collaborative_filtering_service.dart

import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

import '../../firebase_class/firebase_parts.dart';
import '../../firebase_class/firebase_routines.dart';
import '../../firebase_class/users.dart';
import '../../models/Parts.dart';
import '../../models/routines.dart';



class CollaborativeFilteringService {
  final Logger _logger = Logger('CollaborativeFilteringService');
  final int _neighborhoodSize;
  final double _similarityThreshold;

  CollaborativeFilteringService({
    int neighborhoodSize = 20,
    double similarityThreshold = 0.1,
  })  : _neighborhoodSize = neighborhoodSize,
        _similarityThreshold = similarityThreshold;

  Future<List> getRecommendations<T>(String userId, List<T> items) async {
    try {
      _logger.info('$userId kullanıcısı için öneriler alınıyor');
      Map<String, Map<int, double>> userItemMatrix = _createUserItemMatrix(items);
      Map<int, double> targetUserVector = userItemMatrix[userId] ?? {};
      Map<String, double> similarityMatrix = _calculateSimilarityMatrix(userId, userItemMatrix);
      List<String> neighbors = _findNeighbors(similarityMatrix);
      List recommendations = _calculateRecommendations(userId, targetUserVector, neighbors, userItemMatrix, items);
      _logger.info('$userId kullanıcısı için ${recommendations.length} öneri oluşturuldu');
      return recommendations;
    } catch (e, stackTrace) {
      _logger.severe('İşbirlikçi filtrelemede hata: $e', stackTrace);
      rethrow;
    }
  }

  Map<String, Map<int, double>> _createUserItemMatrix<T>(List<T> items) {
    Map<String, Map<int, double>> matrix = {};
    for (var item in items) {
      int itemId = item is Parts ? item.id : (item as Routines).id;
      double rating = _getRating(item);
      String userId = _getUserId(item);
      matrix.putIfAbsent(userId, () => {});
      matrix[userId]![itemId] = rating;
    }
    return matrix;
  }

  double _getRating(dynamic item) {
    if (item is Parts) {
      return item.userProgress?.toDouble() ?? 0.0;
    } else if (item is Routines) {
      return item.userProgress?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  String _getUserId(dynamic item) {
    if (item is FirebaseRoutines || item is FirebaseParts) {
      // FirebaseRoutines ve FirebaseParts sınıfları zaten belirli bir kullanıcıya ait olduğundan,
      // bu nesnelerin ait olduğu kullanıcının ID'sini döndürebiliriz.
      // Ancak bu sınıflarda kullanıcı ID'si tutulmuyorsa, mevcut oturum açmış kullanıcının ID'sini alabiliriz.
      return FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';
    } else if (item is Users) {
      // Eğer item bir Users nesnesi ise, doğrudan onun ID'sini döndürebiliriz.
      return item.id;
    } else {
      // Eğer item'ın türü bilinmiyorsa veya kullanıcı ID'si içermiyorsa, varsayılan bir değer döndürürüz.
      _logger.warning('Unknown item type or no user ID available. Returning default user ID.');
      return 'defaultUserId';
    }
  }


  Map<String, double> _calculateSimilarityMatrix(String userId, Map<String, Map<int, double>> userItemMatrix) {
    Map<String, double> similarityMatrix = {};
    Map<int, double> targetUserVector = userItemMatrix[userId] ?? {};

    for (var otherUserId in userItemMatrix.keys) {
      if (otherUserId != userId) {
        double similarity = _calculateCosineSimilarity(targetUserVector, userItemMatrix[otherUserId]!);
        if (similarity > _similarityThreshold) {
          similarityMatrix[otherUserId] = similarity;
        }
      }
    }

    return similarityMatrix;
  }

  double _calculateCosineSimilarity(Map<int, double> vector1, Map<int, double> vector2) {
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    Set<int> allItems = {...vector1.keys, ...vector2.keys};

    for (var item in allItems) {
      double v1 = vector1[item] ?? 0.0;
      double v2 = vector2[item] ?? 0.0;
      dotProduct += v1 * v2;
      norm1 += v1 * v1;
      norm2 += v2 * v2;
    }

    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  List<String> _findNeighbors(Map<String, double> similarityMatrix) {
    var sortedUsers = similarityMatrix.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedUsers.take(_neighborhoodSize).map((e) => e.key).toList();
  }

  List<dynamic> _calculateRecommendations(
      String userId,
      Map<int, double> targetUserVector,
      List<String> neighbors,
      Map<String, Map<int, double>> userItemMatrix,
      List<dynamic> allItems
      ) {
    Map<int, double> predictedRatings = {};

    for (var item in allItems) {
      int itemId = item is Parts ? item.id : (item as Routines).id;
      if (!targetUserVector.containsKey(itemId)) {
        double weightedSum = 0.0;
        double similaritySum = 0.0;

        for (var neighborId in neighbors) {
          double? neighborRating = userItemMatrix[neighborId]?[itemId];
          double similarity = userItemMatrix[neighborId]?[itemId] ?? 0.0;

          if (neighborRating != null) {
            weightedSum += similarity * neighborRating;
            similaritySum += similarity.abs();
          }
        }

        if (similaritySum > 0) {
          predictedRatings[itemId] = weightedSum / similaritySum;
        }
      }
    }

    var sortedPredictions = predictedRatings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedPredictions
        .take(10)
        .map((e) => allItems.firstWhere((item) =>
    (item is Parts ? item.id : (item as Routines).id) == e.key))
        .toList();
  }
}
