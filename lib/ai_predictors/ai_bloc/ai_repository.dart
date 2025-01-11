import 'package:cloud_firestore/cloud_firestore.dart';
import '../../blocs/data_provider/firebase_provider.dart';
import '../../blocs/data_provider/sql_provider.dart';
import '../../models/firebase_models/user_ai_profile.dart';
import '../exercise_plan_predictor.dart';
import '../fitness_predictor.dart';

class AIRepository {
  // ignore: unused_field
  final SQLProvider _sqlProvider;
  final FirebaseProvider _firebaseProvider;
  final FitnessPredictor _fitnessPredictor = FitnessPredictor();
  final ExercisePlanPredictor _exercisePlanPredictor = ExercisePlanPredictor();

  bool _isInitialized = false;

  AIRepository(this._sqlProvider, this._firebaseProvider);

  Future<void> initialize() async {
    if (_isInitialized) return;
    await Future.wait([
      _fitnessPredictor.initialize(),
      _exercisePlanPredictor.initialize(),
    ]);
    _isInitialized = true;
  }



  Future<Map<String, dynamic>> predictUserMetrics({
    required String userId,
    required double weight,
    required double height,
    required int gender,
    required int age,
    required int goal,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final predictions = await _generatePredictions(
        userId: userId,
        weight: weight,
        height: height,
        gender: gender,
        age: age,
      );

      final userProfile = UserAIProfile(
        userId: userId,
        bmi: predictions['bmi'],
        bfp: predictions['body_fat'],
        fitnessLevel: _calculateFitnessLevel(predictions),
        modelScores: {
          'exercise_plan': predictions['exercise_plan'].toDouble(),
          'confidence': predictions['confidence'],
        },
        lastUpdateTime: DateTime.now(),
        metrics: AIMetrics.initial(),
        weight: weight,
        height: height,
        gender: gender,
        goal: goal,
      );

      await _firebaseProvider.addUserPrediction(userId, userProfile.toFirestore());

      return {
        ...predictions,
        'fitness_level': userProfile.fitnessLevel,
        'timestamp': userProfile.lastUpdateTime.toIso8601String(),
      };
    } catch (e) {
      throw AIRepositoryException('Tahmin işlemi başarısız: $e');
    }
  }

  Future<UserAIProfile> predictAndCreateProfile({
    required String userId,
    required double weight,
    required double height,
    required int gender,
    required int age,
    required int goal,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final predictions = await _generatePredictions(
        userId: userId,
        weight: weight,
        height: height,
        gender: gender,
        age: age,
      );

      final userProfile = UserAIProfile(
        userId: userId,
        bmi: predictions['bmi'],
        bfp: predictions['body_fat'],
        fitnessLevel: _calculateFitnessLevel(predictions),
        modelScores: {
          'exercise_plan': predictions['exercise_plan'].toDouble(),
          'confidence': predictions['confidence'],
        },
        lastUpdateTime: DateTime.now(),
        metrics: AIMetrics.initial(),
        weight: weight,
        height: height,
        gender: gender,
        goal: goal,
      );

      await _firebaseProvider.addUserPrediction(userId, userProfile.toFirestore());

      return userProfile;
    } catch (e) {
      throw AIRepositoryException('Profil oluşturma başarısız: $e');
    }
  }

  Future<Map<String, dynamic>> _generatePredictions({
    required String userId,
    required double weight,
    required double height,
    required int gender,
    required int age,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Fitness tahminlerini al
      final fitnessResults = await _fitnessPredictor.predict(
        weight: weight,
        height: height / 100, // cm'yi metreye çevir
        gender: gender,
        age: age,
      );

      // BMI ve BFP case'lerini belirle
      final bmiCase = getBMICase(fitnessResults['bmi']!);
      final bfpCase = getBFPCase(fitnessResults['body_fat']!, gender);

      // Egzersiz planı tahminini al
      final exercisePlan = await _exercisePlanPredictor.predict(
        weight: weight,
        height: height / 100,
        gender: gender,
        age: age,
        bmi: fitnessResults['bmi']!,
        bodyFat: fitnessResults['body_fat']!,
        bmiCase: bmiCase,
        bfpCase: bfpCase,
      );

      // Tüm sonuçları birleştir
      return {
        'bmi': fitnessResults['bmi']!,
        'body_fat': fitnessResults['body_fat']!,
        'exercise_plan': exercisePlan['exercise_plan']!,
        'confidence': exercisePlan['confidence']!,
        'bmi_case': bmiCase,
        'bfp_case': bfpCase,
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      throw AIRepositoryException('Tahmin hatası: $e');
    }
  }

  int _calculateFitnessLevel(Map<String, dynamic> predictions) {
    final bmiCase = getBMICase(predictions['bmi']);
    final bfpCase = predictions['bfp_case'];
    final confidence = predictions['confidence'];

    // Basit fitness seviyesi hesaplama
    int baseLevel = 3; // Orta seviye
    if (bmiCase == 3 && bfpCase <= 2) baseLevel++; // Normal BMI ve düşük yağ
    if (confidence > 0.8) baseLevel++; // Yüksek güven
    return baseLevel.clamp(1, 5); // 1-5 arası sınırla
  }




  int getBMICase(double bmi) {
    if (bmi < 16.0) return 1;
    if (bmi < 18.5) return 2;
    if (bmi < 25.0) return 3;
    if (bmi < 30.0) return 4;
    if (bmi < 35.0) return 5;
    return 6;
  }

  int getBFPCase(double bodyFat, int gender) {
    if (gender == 0) { // Erkek
      if (bodyFat < 6) return 1;
      if (bodyFat < 14) return 2;
      if (bodyFat < 18) return 3;
      return 4;
    } else { // Kadın
      if (bodyFat < 14) return 1;
      if (bodyFat < 21) return 2;
      if (bodyFat < 25) return 3;
      return 4;
    }
  }



  Future<List<dynamic>> getUserPredictionHistory(String userId) async {
    return await _firebaseProvider.getUserPredictionHistory(userId);
  }

  Future<UserAIProfile?> getLatestUserPrediction(String userId) async {
    return await _firebaseProvider.getLatestUserPrediction(userId);
  }


  void dispose() {
    _fitnessPredictor.dispose();
    _exercisePlanPredictor.dispose();
    _isInitialized = false;
  }
}



class AIRepositoryException implements Exception {
  final String message;
  AIRepositoryException(this.message);

  @override
  String toString() => message;
}
