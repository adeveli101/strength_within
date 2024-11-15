// routine_exercises.dart
class RoutineExercises {
  final int id;
  final int routineId;
  final int exerciseId;
  final int orderIndex; // Eklenen alan

  const RoutineExercises({
    required this.id,
    required this.routineId,
    required this.exerciseId,
    required this.orderIndex, // Constructor'a eklendi
  });

  factory RoutineExercises.fromMap(Map<String, dynamic> map) {
    return RoutineExercises(
      id: map['id'] as int,
      routineId: map['routineId'] as int,
      exerciseId: map['exerciseId'] as int,
      orderIndex: map['orderIndex'] as int, // Map'ten okuma eklendi
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineId': routineId,
      'exerciseId': exerciseId,
      'orderIndex': orderIndex, // Map'e yazma eklendi
    };
  }

  RoutineExercises copyWith({
    int? id,
    int? routineId,
    int? exerciseId,
    int? orderIndex, // copyWith parametresi eklendi
  }) {
    return RoutineExercises(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      exerciseId: exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex, // copyWith'e eklendi
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'routineId': routineId,
      'exerciseId': exerciseId,
      'orderIndex': orderIndex, // Firestore'a yazma eklendi
    };
  }

  @override
  String toString() {
    return 'RoutineExercises(id: $id, routineId: $routineId, exerciseId: $exerciseId, orderIndex: $orderIndex)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoutineExercises &&
        other.id == id &&
        other.routineId == routineId &&
        other.exerciseId == exerciseId &&
        other.orderIndex == orderIndex; // Eşitlik kontrolüne eklendi
  }

  @override
  int get hashCode {
    return Object.hash(id, routineId, exerciseId, orderIndex); // Hash'e eklendi
  }
}