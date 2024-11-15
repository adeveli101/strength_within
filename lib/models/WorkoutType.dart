class WorkoutTypes {
  final int id;
  final String name;

  const WorkoutTypes({
    required this.id,
    required this.name,
  });

  factory WorkoutTypes.fromMap(Map<String, dynamic> map) {
    return WorkoutTypes(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      // Diğer alanlar...
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Name': name,
    };
  }

  WorkoutTypes copyWith({
    int? id,
    String? name,
  }) {
    return WorkoutTypes(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  String toString() => 'WorkoutType(id: $id, name: $name)';


}
