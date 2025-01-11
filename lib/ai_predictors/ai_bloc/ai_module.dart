import 'package:logging/logging.dart';
import 'package:strength_within/blocs/data_provider/sql_provider.dart';
import '../../blocs/data_provider/firebase_provider.dart';
import '../../models/firebase_models/user_ai_profile.dart';
import '../../models/sql_models/routines.dart';
import '../exercise_plan_predictor.dart';
import '../fitness_predictor.dart';
import 'exercisetype_classifier.dart';

class AIModule {
  final SQLProvider _sqlProvider;
  final FirebaseProvider _firebaseProvider;
  final FitnessPredictor _fitnessPredictor;
  final ExercisePlanPredictor _exercisePlanPredictor;
  final ExerciseTypeClassifier _exerciseTypeClassifier;
  bool _isInitialized = false;

  AIModule({
    required SQLProvider sqlProvider,
    required FirebaseProvider firebaseProvider,
    required FitnessPredictor fitnessPredictor,
    required ExercisePlanPredictor exercisePlanPredictor,
    required ExerciseTypeClassifier exerciseTypeClassifier,
  }) :  _sqlProvider = sqlProvider,
        _firebaseProvider = firebaseProvider,
        _fitnessPredictor = fitnessPredictor,
        _exercisePlanPredictor = exercisePlanPredictor,
        _exerciseTypeClassifier = exerciseTypeClassifier;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Future.wait([
        _fitnessPredictor.initialize(),
        _exercisePlanPredictor.initialize(),
      ]);
      _isInitialized = true;
    } catch (e) {
      throw Exception('AI Modül başlatılamadı: $e');
    }
  }

  ValidationResult validateUserInputs({
    required double weight,
    required double height,
    required int gender,
    required int age,
  }) {
    if (weight < 30 || weight > 250) {
      return ValidationResult(
        isValid: false,
        message: 'Kilo 30-250 kg arasında olmalıdır',
      );
    }
    if (height < 120 || height > 220) {
      return ValidationResult(
        isValid: false,
        message: 'Boy 120-220 cm arasında olmalıdır',
      );
    }
    if (age < 15 || age > 90) {
      return ValidationResult(
        isValid: false,
        message: 'Yaş 15-90 arasında olmalıdır',
      );
    }
    return ValidationResult(isValid: true);
  }

  Future<Map<String, dynamic>> generatePredictions({
    required double weight,
    required double height,
    required int gender,
    required int age,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final fitnessResults = await _fitnessPredictor.predict(
        weight: weight,
        height: height / 100,
        gender: gender,
        age: age,
      );

      // BMI ve BFP kategorilerini hesapla
      final bmiCase = _calculateBMICase(fitnessResults['bmi']!);
      final bfpCase = _calculateBFPCase(fitnessResults['body_fat']!, gender);

      final planResults = await _exercisePlanPredictor.predict(
        weight: weight,
        height: height / 100,
        gender: gender,
        age: age,
        bmi: fitnessResults['bmi']!,
        bodyFat: fitnessResults['body_fat']!,
        bmiCase: bmiCase,
        bfpCase: bfpCase,
      );

      return {
        'bmi': fitnessResults['bmi'],
        'body_fat': fitnessResults['body_fat'],
        'bmi_case': bmiCase,
        'bfp_case': bfpCase,
        'exercise_plan': planResults['exercise_plan'],
        'confidence': planResults['confidence'],
      };
    } catch (e) {
      throw Exception('AI tahmin hatası: $e');
    }
  }

  Future<List<int>> getRecommendedRoutines({
    required double weight,
    required double height,
    required int gender,
    required int age,
    int limit = 10
  }) async {
    final predictions = await generatePredictions(
      weight: weight,
      height: height,
      gender: gender,
      age: age,
    );

    return await _exerciseTypeClassifier.getOptimalRoutineIds(
      exerciseType: predictions['exercise_plan'],
      confidence: predictions['confidence'],
      limit: limit,
      bmiCategory: predictions['bmi_case'], // BMI kategorisini buraya ekleyin
      bfpCategory: predictions['bfp_case'], // BFP kategorisini buraya ekleyin
    );
  }




  Future<UserAIProfile> createUserProfile({
    required String userId,
    required double weight,
    required double height,
    required int gender,
    required int age,
  }) async {
    final logger = Logger('AIModule.createUserProfile');
    logger.info('Creating user profile for userId: $userId');
    logger.fine('Input parameters - weight: $weight, height: $height, gender: $gender, age: $age');

    try {
      logger.info('Generating AI predictions');
      final predictions = await generatePredictions(
        weight: weight,
        height: height,
        gender: gender,
        age: age,
      );
      logger.fine('Predictions generated successfully: $predictions');

      logger.info('Determining main workout goal');
      final mainGoal = determineMainWorkoutGoal(
          predictions['exercise_plan'] as int
      );
      logger.fine('Main goal determined: $mainGoal');

      logger.info('Calculating fitness level');
      final fitnessLevel = calculateFitnessLevel(predictions);
      logger.fine('Fitness level calculated: $fitnessLevel');

      logger.info('Creating UserAIProfile object');
      final userProfile = UserAIProfile(
        userId: userId,
        bmi: predictions['bmi'],
        bfp: predictions['body_fat'],
        fitnessLevel: calculateFitnessLevel(predictions),
        modelScores: {
          'exercise_plan': predictions['exercise_plan'].toDouble(),
          'confidence': predictions['confidence'],
        },
        lastUpdateTime: DateTime.now(),
        metrics: AIMetrics.initial(),
        weight: weight,
        height: height,
        gender: gender,
        goal: mainGoal,
      );

      logger.fine('UserAIProfile created: ${userProfile.toString()}');

      logger.info('Saving profile to Firebase');
      await _firebaseProvider.addUserPrediction(userId, userProfile.toFirestore());
      logger.info('Profile saved successfully');

      return userProfile;
    } catch (e, stackTrace) {
      logger.severe(
          'Profile creation failed\n'
              'Error: $e\n'
              'Stack trace: $stackTrace\n'
              'Parameters - weight: $weight, height: $height, gender: $gender, age: $age'
      );
      throw Exception('Profil oluşturma hatası: $e');
    }
  }

  Future<List<Routines>> getRoutinesByIds(List<int> routineIds) async {
    final logger = Logger('AIModule.getRoutinesByIds');

    try {

      final List<Routines> routines = [];
      for (final id in routineIds) {
        final routine = await _sqlProvider.getRoutineById(id);
        if (routine != null) {
          routines.add(routine);
        }
      }
      return routines;
    } catch (e, stackTrace) {
      logger.severe('Failed to fetch routines', e, stackTrace);
      throw Exception('Rutin detayları alınamadı: $e');
    }
  }



  int calculateFitnessLevel(Map<String, dynamic> predictions) {
    final bmiCase = predictions['bmi_case'];
    final bfpCase = predictions['bfp_case'];
    final confidence = predictions['confidence'];

    int baseLevel = 3;
    if (bmiCase == 3 && bfpCase <= 2) baseLevel++;
    if (confidence > 0.8) baseLevel++;
    return baseLevel.clamp(1, 5);
  }

  int _calculateBMICase(double bmi) {
    if (bmi < 16.0) return 1;
    if (bmi < 18.5) return 2;
    if (bmi < 25.0) return 3;
    if (bmi < 30.0) return 4;
    if (bmi < 35.0) return 5;
    return 6;
  }

  int determineMainWorkoutGoal(int exerciseType) {
    final goalWeights = _exerciseTypeClassifier.exerciseTypeGoalWeights[exerciseType];

    if (goalWeights == null) {
      throw Exception('Geçersiz exercise type: $exerciseType');
    }

    int mainGoal = -1;
    double maxWeight = 0;

    goalWeights.forEach((goalId, weight) {
      if (weight > maxWeight) {
        maxWeight = weight;
        mainGoal = goalId;
      }
    });

    if (mainGoal == -1) {
      throw Exception('Hedef belirlenemedi');
    }

    return mainGoal;
  }



  int _calculateBFPCase(double bfp, int gender) {
    if (gender == 1) { // Erkek
      if (bfp < 10) return 1;
      if (bfp < 15) return 2;
      if (bfp < 20) return 3;
      if (bfp < 25) return 4;
      return 5;
    } else { // Kadın
      if (bfp < 18) return 1;
      if (bfp < 23) return 2;
      if (bfp < 28) return 3;
      if (bfp < 33) return 4;
      return 5;
    }
  }

  void dispose() {
    _fitnessPredictor.dispose();
    _exercisePlanPredictor.dispose();
    _isInitialized = false;
  }
}

class ValidationResult {
  final bool isValid;
  final String message;

  const ValidationResult({
    required this.isValid,
    this.message = '',
  });
}
