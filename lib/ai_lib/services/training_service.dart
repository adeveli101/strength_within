
import '../models/agde_model.dart';
import '../models/collab_model.dart';
import '../models/knn_model.dart';

class TrainingService {
  final AGDEModel agdeModel = AGDEModel();
  final KNNModel knnModel = KNNModel();
  final CollaborativeModel collaborativeModel = CollaborativeModel();

  /// Modelleri eğitir
  Future<void> trainModels(List<Map<String, dynamic>> trainingData) async {
    // AGDE modelini eğit
    await agdeModel.train(trainingData);

    // KNN modelini initialize et
    await knnModel.initialize(trainingData);

    // Collaborative modelini initialize et
    await collaborativeModel.initialize(trainingData.length, trainingData[0]['features'].length);

    // Kullanıcı-program matrisini güncelle
    for (var data in trainingData) {
      await collaborativeModel.updateUserItemMatrix(data['userId'], data['programId'], data['rating']);
    }

    // Benzerlik matrisini hesapla
    await collaborativeModel.calculateSimilarityMatrix();
  }
}
