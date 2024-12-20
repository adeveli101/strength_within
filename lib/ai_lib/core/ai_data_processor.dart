// ignore_for_file: unused_field

import 'dart:math' as math;
import 'dart:math';
import 'ai_constants.dart';
import 'ai_exceptions.dart';

class AIDataProcessor {
  // Singleton pattern
  static final AIDataProcessor _instance = AIDataProcessor._internal();
  factory AIDataProcessor() => _instance;
  AIDataProcessor._internal();

  /// Feature extraction için kullanılacak özellikler
  static const List<String> _numericFeatures = [
    'Weight',
    'Height',
    'BMI',
    'Body Fat Percentage',
    'Age',
    'Max_BPM',
    'Avg_BPM',
    'Resting_BPM',
    'Session_Duration (hours)',
    'Calories_Burned',
    'Water_Intake (liters)',
    'Workout_Frequency (days/week)'
  ];

  static const List<String> _categoricalFeatures = [
    'Gender',
    'BMIcase',
    'BFPcase',
    'Workout_Type',
    'Experience_Level'
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

  /// Toplu veri işleme
  Future<List<Map<String, dynamic>>> processTrainingData(List<Map<String, dynamic>> data) async {
    try {
      final processedData = <Map<String, dynamic>>[];

      for (var item in data) {
        final processed = await processRawData(item);
        if (processed != null && processed.isNotEmpty) { // Eğer null veya boş dönerse kontrol et
          processedData.add(processed);
        }
      }

      if (processedData.isEmpty) {
        throw Exception("No valid processed data.");
      }

      return processedData;
    } catch (e) {
      throw AIDataProcessingException(
          'Training data processing failed: $e',
          code: AIConstants.ERROR_INSUFFICIENT_DATA
      );
    }
  }


  /// Sayısal özellikleri normalize eder
  Future<Map<String, double>> _extractNumericFeatures(Map<String, dynamic> data) async {
    final features = <String, double>{};

    // Weight normalization
    features['weight_normalized'] = _normalize(
        data['Weight']?.toDouble() ?? data['Weight (kg)']?.toDouble() ?? 0.0,
        40.0,
        150.0
    );

    // Height normalization
    features['height_normalized'] = _normalize(
        data['Height']?.toDouble() ?? data['Height (m)']?.toDouble() ?? 0.0,
        1.4,
        2.2
    );

    // BMI normalization
    features['bmi_normalized'] = _normalize(
        data['BMI']?.toDouble() ?? 0.0,
        AIConstants.MIN_BMI,
        AIConstants.MAX_BMI
    );

    // BFP normalization
    features['bfp_normalized'] = _normalize(
        data['Body Fat Percentage']?.toDouble() ??
            data['Fat_Percentage']?.toDouble() ?? 0.0,
        AIConstants.MIN_BFP,
        AIConstants.MAX_BFP
    );

    // Age normalization
    features['age_normalized'] = _normalize(
        data['Age']?.toDouble() ?? 0.0,
        AIConstants.MIN_AGE.toDouble(),
        AIConstants.MAX_AGE.toDouble()
    );

    // Exercise metrics normalization
    if (data.containsKey('Max_BPM')) {
      features['max_bpm_normalized'] = _normalize(
          data['Max_BPM'].toDouble(),
          160.0,
          200.0
      );
    }

    if (data.containsKey('Session_Duration (hours)')) {
      features['duration_normalized'] = _normalize(
          data['Session_Duration (hours)'].toDouble(),
          0.5,
          2.0
      );
    }

    if (data.containsKey('Workout_Frequency (days/week)')) {
      features['frequency_normalized'] = _normalize(
          data['Workout_Frequency (days/week)'].toDouble(),
          1.0,
          7.0
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

    // Workout type encoding
    if (data.containsKey('Workout_Type')) {
      final workoutType = data['Workout_Type'].toString().toLowerCase();
      features['workout_cardio'] = workoutType == 'cardio' ? 1.0 : 0.0;
      features['workout_strength'] = workoutType == 'strength' ? 1.0 : 0.0;
      features['workout_hiit'] = workoutType == 'hiit' ? 1.0 : 0.0;
      features['workout_yoga'] = workoutType == 'yoga' ? 1.0 : 0.0;
    }

    // Experience level encoding
    if (data.containsKey('Experience_Level')) {
      final level = data['Experience_Level'] as int;
      features['experience_beginner'] = level == 1 ? 1.0 : 0.0;
      features['experience_intermediate'] = level == 2 ? 1.0 : 0.0;
      features['experience_advanced'] = level == 3 ? 1.0 : 0.0;
    }

    return features;
  }

  /// Min-max normalization uygular
  double _normalize(double value, double min, double max) {
    if (value.isNaN || min.isNaN || max.isNaN) return 0.0;
    if (max == min) return 0.0;
    return (value - min) / (max - min);
  }

  /// Dataset split işlemi
  Future<Map<String, List<Map<String, dynamic>>>> splitDataset(
      List<Map<String, dynamic>> dataset
      ) async {
    dataset.shuffle(Random(42));

    final trainSize = (dataset.length * (1 - AIConstants.VALIDATION_SPLIT * 2)).toInt();
    final validationSize = (dataset.length * AIConstants.VALIDATION_SPLIT).toInt();

    return {
      'train': dataset.sublist(0, trainSize),
      'validation': dataset.sublist(trainSize, trainSize + validationSize),
      'test': dataset.sublist(trainSize + validationSize),
    };
  }

  /// Batch oluşturma
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
