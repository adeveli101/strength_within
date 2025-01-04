import 'package:tflite_flutter/tflite_flutter.dart';

class ExercisePlanPredictor {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Normalizasyon değerleri
  final Map<String, Map<String, double>> _normalization = {
    'weight': {'mean': 80.5, 'std': 15.0},
    'height': {'mean': 1.75, 'std': 0.12},
    'bmi': {'mean': 25.0, 'std': 5.0},
    'body_fat': {'mean': 20.0, 'std': 8.0},
    'gender': {'mean': 0.5, 'std': 0.5},
    'age': {'mean': 35.0, 'std': 15.0}
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset('assets/ai_models/exercise_plan.tflite');
      _isInitialized = true;
    } catch (e) {
      throw Exception('Model yüklenirken hata: $e');
    }
  }

  Future<Map<String, dynamic>> predict({
    required double weight,
    required double height,
    required int gender,
    required int age,
    required double bmi,
    required double bodyFat,
    required int bmiCase,
    required int bfpCase,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Girdi verilerini normalize et
      var normalizedInputs = [
        (weight - _normalization['weight']!['mean']!) / _normalization['weight']!['std']!,
        (height - _normalization['height']!['mean']!) / _normalization['height']!['std']!,
        (gender.toDouble() - _normalization['gender']!['mean']!) / _normalization['gender']!['std']!,
        (age.toDouble() - _normalization['age']!['mean']!) / _normalization['age']!['std']!,
        (bmi - _normalization['bmi']!['mean']!) / _normalization['bmi']!['std']!,
        (bodyFat - _normalization['body_fat']!['mean']!) / _normalization['body_fat']!['std']!,
      ];

      var inputArray = [normalizedInputs];
      var outputArray = List.filled(1 * 7, 0.0).reshape([1, 7]);

      _interpreter!.run(inputArray, outputArray);

      // En yüksek olasılıklı planı bul
      int predictedPlan = 0;
      double maxProb = outputArray[0][0];

      for (int i = 1; i < 7; i++) {
        if (outputArray[0][i] > maxProb) {
          maxProb = outputArray[0][i];
          predictedPlan = i;
        }
      }

      return {
        'exercise_plan': predictedPlan + 1,
        'confidence': maxProb,
        'bmi_case': bmiCase,
        'bfp_case': bfpCase
      };

    } catch (e) {
      throw Exception('Tahmin hatası: $e');
    }
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
