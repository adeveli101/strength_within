class GymMembersTracking {
  final int id;
  final int age;
  final String gender;
  final double weightKg;
  final double heightM;
  final int maxBpm;
  final int avgBpm;
  final int restingBpm;
  final double sessionDuration;
  final double caloriesBurned;
  final String workoutType;
  final double fatPercentage;
  final double waterIntake;
  final int workoutFrequency;
  final int experienceLevel;
  final double bmi;

  GymMembersTracking({
    required this.id,
    required this.age,
    required this.gender,
    required this.weightKg,
    required this.heightM,
    required this.maxBpm,
    required this.avgBpm,
    required this.restingBpm,
    required this.sessionDuration,
    required this.caloriesBurned,
    required this.workoutType,
    required this.fatPercentage,
    required this.waterIntake,
    required this.workoutFrequency,
    required this.experienceLevel,
    required this.bmi,
  });

  factory GymMembersTracking.fromMap(Map<String, dynamic> map) {
    return GymMembersTracking(
      id: map['id'] as int,
      age: map['age'] as int,
      gender: map['gender'] as String,
      weightKg: (map['weight_kg'] as num).toDouble(),
      heightM: (map['height_m'] as num).toDouble(),
      maxBpm: map['max_bpm'] as int,
      avgBpm: map['avg_bpm'] as int,
      restingBpm: map['resting_bpm'] as int,
      sessionDuration: (map['session_duration'] as num).toDouble(),
      caloriesBurned: (map['calories_burned'] as num).toDouble(),
      workoutType: map['workout_type'] as String,
      fatPercentage: (map['fat_percentage'] as num).toDouble(),
      waterIntake: (map['water_intake'] as num).toDouble(),
      workoutFrequency: map['workout_frequency'] as int,
      experienceLevel: map['experience_level'] as int,
      bmi: (map['bmi'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'age': age,
    'gender': gender,
    'weight_kg': weightKg,
    'height_m': heightM,
    'max_bpm': maxBpm,
    'avg_bpm': avgBpm,
    'resting_bpm': restingBpm,
    'session_duration': sessionDuration,
    'calories_burned': caloriesBurned,
    'workout_type': workoutType,
    'fat_percentage': fatPercentage,
    'water_intake': waterIntake,
    'workout_frequency': workoutFrequency,
    'experience_level': experienceLevel,
    'bmi': bmi,
  };
}

class FinalDatasetBFP {
  final int id; // ID eklendi
  final double weight;
  final double height;
  final double bmi;
  final double bodyFatPercentage;
  final String bfpCase;
  final String gender;
  final int age;
  final String bmiCase;
  final int exercisePlan;

  FinalDatasetBFP({
    required this.id, // ID zorunlu hale getirildi
    required this.weight,
    required this.height,
    required this.bmi,
    required this.bodyFatPercentage,
    required this.bfpCase,
    required this.gender,
    required this.age,
    required this.bmiCase,
    required this.exercisePlan,
  });

  Map<String, dynamic> toMap() => {
    'id': id, // ID haritaya eklendi
    'weight': weight,
    'height': height,
    'bmi': bmi,
    'bodyFatPercentage': bodyFatPercentage,
    'bfpCase': bfpCase,
    'gender': gender,
    'age': age,
    'bmiCase': bmiCase,
    'exercisePlan': exercisePlan,
  };

  factory FinalDatasetBFP.fromMap(Map<String, dynamic> map) => FinalDatasetBFP(
    id: map['id'], // ID haritadan alındı
    weight: map['weight'],
    height: map['height'],
    bmi: map['bmi'],
    bodyFatPercentage: map['bodyFatPercentage'],
    bfpCase: map['bfpCase'],
    gender: map['gender'],
    age: map['age'],
    bmiCase: map['bmiCase'],
    exercisePlan: map['exercisePlan'],
  );
}

class FinalDataset {
  final int id; // ID eklendi
  final double weight;
  final double height;
  final double bmi;
  final String gender;
  final int age;
  final String bmiCase;
  final int exercisePlan;

  FinalDataset({
    required this.id, // ID zorunlu hale getirildi
    required this.weight,
    required this.height,
    required this.bmi,
    required this.gender,
    required this.age,
    required this.bmiCase,
    required this.exercisePlan,
  });

  Map<String, dynamic> toMap() => {
    'id': id, // ID haritaya eklendi
    'weight': weight,
    'height': height,
    'bmi': bmi,
    'gender': gender,
    'age': age,
    'bmiCase': bmiCase,
    'exercisePlan': exercisePlan
  };

  factory FinalDataset.fromMap(Map<String, dynamic> map) => FinalDataset(
      id: map['id'], // ID haritadan alındı
      weight: map['weight'],
      height: map['height'],
      bmi: map['bmi'],
      gender: map['gender'],
      age: map['age'],
      bmiCase: map['bmiCase'],
      exercisePlan: map['exercisePlan']
  );
}
