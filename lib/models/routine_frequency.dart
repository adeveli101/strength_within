class RoutineFrequency {
  final int? id;
  final int routineId;
  final int recommendedFrequency;
  final int minRestDays;

  RoutineFrequency({
    this.id,
    required this.routineId,
    required this.recommendedFrequency,
    required this.minRestDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineId': routineId,
      'recommendedFrequency': recommendedFrequency,
      'minRestDays': minRestDays,
    };
  }

  factory RoutineFrequency.fromMap(Map<String, dynamic> map) {
    return RoutineFrequency(
      id: map['id'],
      routineId: map['routineId'],
      recommendedFrequency: map['recommendedFrequency'],
      minRestDays: map['minRestDays'],
    );
  }
}