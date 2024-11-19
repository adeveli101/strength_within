class PartExercise {
  final int id;
  final int partId;
  final dynamic exerciseId;
  final int orderIndex; //

  const PartExercise({
    required this.id,
    required this.partId,
    required this.exerciseId,
    required this.orderIndex, //
  });

  factory PartExercise.fromMap(Map<String, dynamic> map) {
    return PartExercise(
      id: map['id'] as int,
      partId: map['partId'] as int,
      exerciseId: map['exerciseId'] as dynamic,
      orderIndex: map['orderIndex'] as int? ?? 0, //
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partId': partId,
      'exerciseId': exerciseId,
      'orderIndex': orderIndex, //
    };
  }

  PartExercise copyWith({
    int? id,
    int? partId,
    dynamic exerciseId,
    int? orderIndex, //
  }) {
    return PartExercise(
      id: id ?? this.id,
      partId: partId ?? this.partId,
      exerciseId: exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  String toString() => 'PartExercise(id: $id, partId: $partId, exerciseId: $exerciseId, orderIndex: $orderIndex)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PartExercise &&
        other.id == id &&
        other.partId == partId &&
        other.exerciseId == exerciseId &&
        other.orderIndex == orderIndex;
  }

  @override
  int get hashCode => id.hashCode ^ partId.hashCode ^ exerciseId.hashCode ^ orderIndex.hashCode;
}