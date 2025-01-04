import 'package:tflite_flutter/tflite_flutter.dart';

class FitnessPredictor {
  Interpreter? _interpreter;

  // Eğitim verisinden elde edilen normalizasyon değerleri
  final Map<String, Map<String, double>> _normalization = {
    'weight': {'mean': 80.5, 'std': 15.0},
    'height': {'mean': 1.75, 'std': 0.12},
    'gender': {'mean': 0.5, 'std': 0.5},
    'age': {'mean': 35.0, 'std': 15.0}
  };

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/ai_models/body_composition_model.tflite');
    } catch (e) {
      throw Exception('Model yüklenirken hata: $e');
    }
  }

  List<double> _normalizeInput({
    required double weight,
    required double height,
    required int gender,
    required int age,
  }) {
    return [
      (weight - _normalization['weight']!['mean']!) / _normalization['weight']!['std']!,
      (height - _normalization['height']!['mean']!) / _normalization['height']!['std']!,
      (gender.toDouble() - _normalization['gender']!['mean']!) / _normalization['gender']!['std']!,
      (age.toDouble() - _normalization['age']!['mean']!) / _normalization['age']!['std']!,
    ];
  }

  Future<Map<String, double>> predict({
    required double weight,
    required double height,
    required int gender,
    required int age,
  }) async {
    if (_interpreter == null) {
      throw Exception('Model yüklenmedi');
    }

    try {
      // Girdiyi normalize et
      var normalizedInput = _normalizeInput(
        weight: weight,
        height: height,
        gender: gender,
        age: age,
      );

      // Model girdi ve çıktı tensörlerini hazırla
      var inputArray = [normalizedInput];
      var outputArray = List<double>.filled(1 * 2, 0.0).reshape([1, 2]);

      // Modeli çalıştır
      _interpreter!.run(inputArray, outputArray);

      // Random Forest tahminlerini al
      double bmi = outputArray[0][0];
      double bodyFat = outputArray[0][1];

      // Gerçek BMI hesaplaması ile karşılaştır
      double calculatedBMI = weight / (height * height);

      // Tahminleri döndür
      return {
        'bmi': (bmi + calculatedBMI) / 2, // Model tahmini ve hesaplanan değerin ortalaması
        'body_fat': bodyFat,
      };
    } catch (e) {
      throw Exception('Tahmin hatası: $e');
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
