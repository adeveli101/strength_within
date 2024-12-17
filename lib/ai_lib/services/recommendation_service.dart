import '../core/ai_data_processor.dart';
import '../core/ai_exceptions.dart';
import '../models/agde_model.dart';
import '../models/collab_model.dart';
import '../models/knn_model.dart';


class RecommendationService {
  final AGDEModel agdeModel = AGDEModel();
  final KNNModel knnModel = KNNModel();
  final CollaborativeModel collaborativeModel = CollaborativeModel();

  /// Kullanıcı verilerini işleyerek öneri oluşturur
  Future<List<int>> recommendPrograms(Map<String, dynamic> userData) async {
    try {
      // Kullanıcı verilerini işleme
      final processedData = await AIDataProcessor().processRawData(userData);

      // AGDE modelinden öneri al
      int agdeRecommendation = await agdeModel.predict(processedData);

      // KNN modelinden öneri al
      List<int> knnRecommendations = await knnModel.recommend(userData['userId'], 5);

      // Collaborative Filtering modelinden öneri al
      List<int> collaborativeRecommendations = await collaborativeModel.recommendPrograms(userData['userId'], 5);

      // Tüm önerileri birleştir
      List<int> combinedRecommendations = [agdeRecommendation];
      combinedRecommendations.addAll(knnRecommendations);
      combinedRecommendations.addAll(collaborativeRecommendations);

      // Önerileri filtrele ve benzersiz hale getir
      return combinedRecommendations.toSet().toList();
    } catch (e) {
      throw AIPredictionException('Öneri oluşturma hatası: $e');
    }
  }
}
