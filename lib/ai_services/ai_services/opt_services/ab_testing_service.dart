// lib/services/ab_testing_service.dart

import 'dart:math';
import 'package:logging/logging.dart';

class ABTestingService {
  final Logger _logger = Logger('ABTestingService');
  final Random _random = Random();

  bool shouldUseCollaborativeFiltering(String userId) {
    try {
      // Kullanıcıyı rastgele bir gruba ata
      bool useCollaborativeFiltering = _random.nextBool();
      _logger.info('User $userId assigned to ${useCollaborativeFiltering ? "Collaborative Filtering" : "Default"} group');
      return useCollaborativeFiltering;
    } catch (e, stackTrace) {
      _logger.severe('Error in A/B testing: $e', stackTrace);
      return false; // Hata durumunda varsayılan algoritmayı kullan
    }
  }

  void logTestResult(String userId, String algorithm, double performance) {
    try {
      // Test sonuçlarını kaydet
      _logger.info('A/B Test Result - User: $userId, Algorithm: $algorithm, Performance: $performance');
      // Burada sonuçları bir veritabanına veya analiz sistemine kaydedebilirsiniz
    } catch (e, stackTrace) {
      _logger.severe('Error logging A/B test result: $e', stackTrace);
    }
  }
}
