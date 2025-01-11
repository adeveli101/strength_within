import 'package:cloud_firestore/cloud_firestore.dart';

class UserAIProfile {
  final String userId;
  final double? bmi;
  final double? bfp;
  final int fitnessLevel;
  final Map<String, double>? modelScores;
  final List<String>? recommendedRoutineIds;
  final DateTime lastUpdateTime;
  final AIMetrics metrics;
  final double weight;
  final double height;
  final int gender;
  final int goal;

  const UserAIProfile._({
    required this.userId,
    this.bmi,
    this.bfp,
    this.fitnessLevel = 1,
    this.modelScores,
    this.recommendedRoutineIds,
    required this.lastUpdateTime,
    required this.metrics,
    required this.weight,
    required this.height,
    required this.gender,
    required this.goal,
  });

  factory UserAIProfile({
    required String userId,
    double? bmi,
    double? bfp,
    int fitnessLevel = 1,
    Map<String, double>? modelScores,
    List<String>? recommendedRoutineIds,
    DateTime? lastUpdateTime,
    AIMetrics? metrics,
    required double weight,
    required double height,
    required int gender,
    required int goal,
  }) {
    return UserAIProfile._(
      userId: userId,
      bmi: bmi,
      bfp: bfp,
      fitnessLevel: fitnessLevel.clamp(1, 5),
      modelScores: modelScores,
      recommendedRoutineIds: recommendedRoutineIds,
      lastUpdateTime: lastUpdateTime ?? DateTime.now(),
      metrics: metrics ?? AIMetrics.initial(),
      weight: weight,
      height: height,
      gender: gender,
      goal: goal,
    );
  }

  factory UserAIProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('User data not found');

    return UserAIProfile(
      userId: doc.id,
      bmi: data['bmi']?.toDouble(),
      bfp: data['bfp']?.toDouble(),
      fitnessLevel: (data['fitnessLevel'] ?? 1).clamp(1, 5),
      modelScores: data['modelScores'] != null
          ? Map<String, double>.from(data['modelScores'])
          : null,
      recommendedRoutineIds: data['recommendedRoutineIds'] != null
          ? List<String>.from(data['recommendedRoutineIds'])
          : null,
      lastUpdateTime: data['lastUpdateTime'] != null
          ? (data['lastUpdateTime'] as Timestamp).toDate()
          : DateTime.now(),
      metrics: data['metrics'] != null
          ? AIMetrics.fromMap(data['metrics'])
          : AIMetrics.initial(),
      weight: data['weight']?.toDouble() ?? 0.0,
      height: data['height']?.toDouble() ?? 0.0,
      gender: data['gender'] ?? 0,
      goal: data['goal'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (bmi != null) 'bmi': bmi,
      if (bfp != null) 'bfp': bfp,
      'fitnessLevel': fitnessLevel,
      if (modelScores != null) 'modelScores': modelScores,
      if (recommendedRoutineIds != null)
        'recommendedRoutineIds': recommendedRoutineIds,
      'lastUpdateTime': Timestamp.fromDate(lastUpdateTime),
      'metrics': metrics.toMap(),
      'weight': weight,
      'height': height,
      'gender': gender,
      'goal': goal,
    };
  }

  UserAIProfile copyWith({
    String? userId,
    double? bmi,
    double? bfp,
    int? fitnessLevel,
    Map<String, double>? modelScores,
    List<String>? recommendedRoutineIds,
    DateTime? lastUpdateTime,
    AIMetrics? metrics,
    double? weight,
    double? height,
    int? gender,
    int? goal,
  }) {
    return UserAIProfile(
      userId: userId ?? this.userId,
      bmi: bmi ?? this.bmi,
      bfp: bfp ?? this.bfp,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      modelScores: modelScores ?? this.modelScores,
      recommendedRoutineIds: recommendedRoutineIds ?? this.recommendedRoutineIds,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      metrics: metrics ?? this.metrics,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
    );
  }
}

class AIMetrics {
  final int completedProgramCount;
  final double programDropoutRate;
  final int averageTrainingMinutes;

  const AIMetrics({
    this.completedProgramCount = 0,
    this.programDropoutRate = 0.0,
    this.averageTrainingMinutes = 0,
  });

  factory AIMetrics.initial() => const AIMetrics();

  factory AIMetrics.fromMap(Map<String, dynamic> map) {
    return AIMetrics(
      completedProgramCount: map['completedProgramCount'] ?? 0,
      programDropoutRate: (map['programDropoutRate'] ?? 0.0).clamp(0.0, 1.0),
      averageTrainingMinutes: map['averageTrainingMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completedProgramCount': completedProgramCount,
      'programDropoutRate': programDropoutRate.clamp(0.0, 1.0),
      'averageTrainingMinutes': averageTrainingMinutes,
    };





  }

  AIMetrics copyWith({
    int? completedProgramCount,
    double? programDropoutRate,
    int? averageTrainingMinutes,
  }) {
    return AIMetrics(
      completedProgramCount: completedProgramCount ?? this.completedProgramCount,
      programDropoutRate: programDropoutRate ?? this.programDropoutRate,
      averageTrainingMinutes: averageTrainingMinutes ?? this.averageTrainingMinutes,
    );
  }
}
