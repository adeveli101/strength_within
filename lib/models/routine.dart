enum MainTargetedBodyPart { abs, arm, back, chest, leg, shoulder, fullBody, lowerBody, upperBody, core }

class Routine {
  final int id;
  final String name;
  final MainTargetedBodyPart mainTargetedBodyPart;
  final List<int> partIds;
  final bool isRecommended;
  final int difficulty; // 1-3 arası bir değer
  final int estimatedTime; // dakika cinsinden

  // Firebase'den gelen kullanıcıya özel veriler
  int? userProgress;
  DateTime? lastUsedDate;
  bool? userRecommended;

  Routine({
    required this.id,
    required this.name,
    required this.mainTargetedBodyPart,
    required this.partIds,
    required this.isRecommended,
    required this.difficulty,
    required this.estimatedTime,
    this.userProgress,
    this.lastUsedDate,
    this.userRecommended,

  });

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['Id'] as int,
      name: map['Name'] as String,
      mainTargetedBodyPart: MainTargetedBodyPart.values.firstWhere(
            (e) => e.toString() == 'MainTargetedBodyPart.${map['MainTargetedBodyPart']}',
        orElse: () => MainTargetedBodyPart.fullBody,
      ),
      partIds: (map['PartIds'] as String?)?.split(',').map((e) => int.parse(e)).toList() ?? [],
      isRecommended: (map['IsRecommended'] as int?) == 1,
      difficulty: map['Difficulty'] as int? ?? 1,
      estimatedTime: map['EstimatedTime'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Name': name,
      'MainTargetedBodyPart': mainTargetedBodyPart.toString().split('.').last,
      'PartIds': partIds.join(','),
      'IsRecommended': isRecommended ? 1 : 0,
      'Difficulty': difficulty,
      'EstimatedTime': estimatedTime,
    };
  }

  Routine copyWith({
    int? id,
    String? name,
    MainTargetedBodyPart? mainTargetedBodyPart,
    List<int>? partIds,
    bool? isRecommended,
    int? difficulty,
    int? estimatedTime,
    int? userProgress,
    DateTime? lastUsedDate,
    bool? userRecommended,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      mainTargetedBodyPart: mainTargetedBodyPart ?? this.mainTargetedBodyPart,
      partIds: partIds ?? List.from(this.partIds),
      isRecommended: isRecommended ?? this.isRecommended,
      difficulty: difficulty ?? this.difficulty,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      userProgress: userProgress ?? this.userProgress,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
      userRecommended: userRecommended ?? this.userRecommended,
    );
  }

  // Firebase verilerini güncellemek için yeni bir metod
  Routine updateWithFirebaseData(Map<String, dynamic> firebaseData) {
    return copyWith(
      userProgress: firebaseData['progress'] as int?,
      lastUsedDate: firebaseData['lastUsedDate'] != null
          ? DateTime.parse(firebaseData['lastUsedDate'])
          : null,
      userRecommended: firebaseData['isRecommended'] as bool?,
    );
  }

  @override
  String toString() => 'Routine(id: $id, name: $name, difficulty: $difficulty, isRecommended: $isRecommended, userProgress: $userProgress, userRecommended: $userRecommended)';
}
