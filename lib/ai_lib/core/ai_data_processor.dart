import 'dart:math' as math;
import 'dart:math';
import 'ai_constants.dart';
import 'ai_exceptions.dart';

/// Veri işleme ve hazırlama işlemlerini yöneten sınıf
class AIDataProcessor {
  // Singleton pattern
  static final AIDataProcessor _instance = AIDataProcessor._internal();
  factory AIDataProcessor() => _instance;
  AIDataProcessor._internal();

  /// Feature extraction için kullanılacak özellikler
  // ignore: unused_field
  static const List<String> _numericFeatures = [
    'Weight',
    'Height',
    'BMI',
    'Body Fat Percentage',
    'Age'
  ];

  // ignore: unused_field
  static const List<String> _categoricalFeatures = [
    'Gender',
    'BMIcase',
    'BFPcase'
  ];

  /// Ham veriyi modelin anlayacağı formata dönüştürür
  Future<Map<String, dynamic>> processRawData(Map<String, dynamic> rawData) async {
    try {
      final numericFeatures = await _extractNumericFeatures(rawData);
      final categoricalFeatures = await _extractCategoricalFeatures(rawData);

      return {
        'features': {...numericFeatures, ...categoricalFeatures},
        'label': rawData['Exercise Recommendation Plan']
      };
    } catch (e) {
      throw AIDataProcessingException('Veri işleme hatası: $e');
    }
  }

  /// Sayısal özellikleri çıkarır ve normalize eder
  Future<Map<String, double>> _extractNumericFeatures(Map<String, dynamic> data) async {
    final features = <String, double>{};

    // Weight normalization
    if (data.containsKey('Weight')) {
      features['weight_normalized'] = _normalize(
          data['Weight'].toDouble(),
          0.0,  // Min weight from dataset
          200.0 // Max weight from dataset
      );
    }

    // Height normalization
    if (data.containsKey('Height')) {
      features['height_normalized'] = _normalize(
          data['Height'].toDouble(),
          0.0,  // Min height from dataset
          2.5   // Max height from dataset
      );
    }

    // BMI normalization
    if (data.containsKey('BMI')) {
      features['bmi_normalized'] = _normalize(
          data['BMI'].toDouble(),
          AIConstants.MIN_BMI,
          AIConstants.MAX_BMI
      );
    }

    // BFP normalization (if exists)
    if (data.containsKey('Body Fat Percentage')) {
      features['bfp_normalized'] = _normalize(
          data['Body Fat Percentage'].toDouble(),
          AIConstants.MIN_BFP,
          AIConstants.MAX_BFP
      );
    }

    // Age normalization
    if (data.containsKey('Age')) {
      features['age_normalized'] = _normalize(
          data['Age'].toDouble(),
          AIConstants.MIN_AGE.toDouble(),
          AIConstants.MAX_AGE.toDouble()
      );
    }

    return features;
  }

  /// Kategorik özellikleri one-hot encoding ile dönüştürür
  Future<Map<String, double>> _extractCategoricalFeatures(Map<String, dynamic> data) async {
    final features = <String, double>{};

    // Gender encoding
    if (data.containsKey('Gender')) {
      features['gender_male'] = data['Gender'].toString().toLowerCase() == 'male' ? 1.0 : 0.0;
      features['gender_female'] = data['Gender'].toString().toLowerCase() == 'female' ? 1.0 : 0.0;
    }

    // BMIcase encoding
    if (data.containsKey('BMIcase')) {
      final bmiCase = data['BMIcase'].toString().toLowerCase();
      features['bmi_severely_underweight'] = bmiCase.contains('severe') && bmiCase.contains('under') ? 1.0 : 0.0;
      features['bmi_underweight'] = bmiCase == 'underweight' ? 1.0 : 0.0;
      features['bmi_normal'] = bmiCase == 'normal' ? 1.0 : 0.0;
      features['bmi_overweight'] = bmiCase == 'overweight' ? 1.0 : 0.0;
      features['bmi_obese'] = bmiCase == 'obese' ? 1.0 : 0.0;
      features['bmi_severely_obese'] = bmiCase.contains('severe') && bmiCase.contains('obese') ? 1.0 : 0.0;
    }

    // BFPcase encoding (if exists)
    if (data.containsKey('BFPcase')) {
      final bfpCase = data['BFPcase'].toString().toLowerCase();
      features['bfp_athletes'] = bfpCase == 'athletes' ? 1.0 : 0.0;
      features['bfp_fitness'] = bfpCase == 'fitness' ? 1.0 : 0.0;
      features['bfp_acceptable'] = bfpCase == 'acceptable' ? 1.0 : 0.0;
      features['bfp_obese'] = bfpCase == 'obese' ? 1.0 : 0.0;
    }

    return features;
  }

  /// Min-max normalization uygular
  double _normalize(double value, double min, double max) {
    return (value - min) / (max - min);
  }

  /// Z-score normalization uygular
  double _standardize(double value, double mean, double stdDev) {
    return (value - mean) / stdDev;
  }

  /// Veri setini train/validation/test olarak böler
  Future<Map<String, List<Map<String, dynamic>>>> splitDataset(
      List<Map<String, dynamic>> dataset
      ) async {
    dataset.shuffle(Random(42)); // Sabit seed ile karıştırma

    final trainSize = (dataset.length * (1 - AIConstants.VALIDATION_SPLIT * 2)).toInt();
    final validationSize = (dataset.length * AIConstants.VALIDATION_SPLIT).toInt();

    return {
      'train': dataset.sublist(0, trainSize),
      'validation': dataset.sublist(trainSize, trainSize + validationSize),
      'test': dataset.sublist(trainSize + validationSize),
    };
  }

  /// Batch oluşturur
  Future<List<Map<String, dynamic>>> createBatch(
      List<Map<String, dynamic>> dataset,
      int batchSize
      ) async {
    if (dataset.length < batchSize) {
      throw AIDataProcessingException(
          'Dataset size smaller than batch size',
          code: AIConstants.ERROR_INSUFFICIENT_DATA
      );
    }

    final random = Random();
    final indices = List.generate(batchSize, (_) => random.nextInt(dataset.length));
    return indices.map((i) => dataset[i]).toList();
  }
}
