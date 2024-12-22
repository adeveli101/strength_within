class GymMembersTracking {
  final int id; // ID eklendi
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
    required this.id, // ID zorunlu hale getirildi
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

  Map<String, dynamic> toMap() => {
    'id': id, // ID haritaya eklendi
    'age': age,
    'gender': gender,
    'weightKg': weightKg,
    'heightM': heightM,
    'maxBpm': maxBpm,
    'avgBpm': avgBpm,
    'restingBpm': restingBpm,
    'sessionDuration': sessionDuration,
    'caloriesBurned': caloriesBurned,
    'workoutType': workoutType,
    'fatPercentage': fatPercentage,
    'waterIntake': waterIntake,
    'workoutFrequency': workoutFrequency,
    'experienceLevel': experienceLevel,
    'bmi': bmi,
  };

  factory GymMembersTracking.fromMap(Map<String, dynamic> map) => GymMembersTracking(
    id: map['id'], // ID haritadan alındı
    age: map['age'],
    gender: map['gender'],
    weightKg: map['weightKg'],
    heightM: map['heightM'],
    maxBpm: map['maxBpm'],
    avgBpm: map['avgBpm'],
    restingBpm: map['restingBpm'],
    sessionDuration: map['sessionDuration'],
    caloriesBurned: map['caloriesBurned'],
    workoutType: map['workoutType'],
    fatPercentage: map['fatPercentage'],
    waterIntake: map['waterIntake'],
    workoutFrequency: map['workoutFrequency'],
    experienceLevel: map['experienceLevel'],
    bmi: map['bmi'],
  );
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
