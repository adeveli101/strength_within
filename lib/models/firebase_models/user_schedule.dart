import 'package:cloud_firestore/cloud_firestore.dart';

import 'users.dart';


mixin UserScheduleValidation {
  static const int MIN_SELECTED_DAYS = 1;
  static const int MAX_SELECTED_DAYS = 7;
  static const int MIN_FREQUENCY = 1;
  static const int MAX_FREQUENCY = 7;
  static const int MIN_REST_DAYS = 0;
  static const int MAX_REST_DAYS = 6;

  static ValidationResult validateUserSchedule({
    required String userId,
    required int itemId,
    required String type,
    required List<int> selectedDays,
    required DateTime startDate,
    int? recommendedFrequency,
    int? minRestDays,
  }) {
    if (userId.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'Kullanıcı ID boş olamaz',
      );
    }

    if (itemId <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz item ID',
      );
    }

    if (type != 'part' && type != 'routine') {
      return ValidationResult(
        isValid: false,
        message: "Tip 'part' veya 'routine' olmalıdır",
      );
    }

    if (selectedDays.isEmpty || selectedDays.length > MAX_SELECTED_DAYS) {
      return ValidationResult(
        isValid: false,
        message: 'Seçili gün sayısı $MIN_SELECTED_DAYS-$MAX_SELECTED_DAYS arasında olmalıdır',
      );
    }

    if (startDate.isBefore(DateTime(2020))) {
      return ValidationResult(
        isValid: false,
        message: 'Geçersiz başlangıç tarihi',
      );
    }

    if (recommendedFrequency != null &&
        (recommendedFrequency < MIN_FREQUENCY || recommendedFrequency > MAX_FREQUENCY)) {
      return ValidationResult(
        isValid: false,
        message: 'Önerilen frekans $MIN_FREQUENCY-$MAX_FREQUENCY arasında olmalıdır',
      );
    }

    if (minRestDays != null &&
        (minRestDays < MIN_REST_DAYS || minRestDays > MAX_REST_DAYS)) {
      return ValidationResult(
        isValid: false,
        message: 'Minimum dinlenme günü $MIN_REST_DAYS-$MAX_REST_DAYS arasında olmalıdır',
      );
    }

    return ValidationResult(isValid: true);
  }
}


class UserSchedule with UserScheduleValidation {
  final String id;
  final String userId;
  final int itemId;
  final String type; // 'part' veya 'routine'
  final List<int> selectedDays;
  final DateTime startDate;
  final bool isActive;
  final int? recommendedFrequency;
  final int? minRestDays;
  final DateTime lastUpdated;
  final Map<String, dynamic>? performanceData;
  final bool isCustom;
  final Map<String, List<Map<String, dynamic>>>? dailyExercises; // Yeni


  // Firebase'e veri gönderme
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'itemId': itemId,
      'type': type,
      'selectedDays': selectedDays,
      'startDate': Timestamp.fromDate(startDate),
      'isActive': isActive,
      'recommendedFrequency': recommendedFrequency,
      'minRestDays': minRestDays,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      if (performanceData != null) 'performanceData': performanceData,
      'isCustom': isCustom,
      if (dailyExercises != null) 'dailyExercises': dailyExercises,
    };
  }

  // Local SQLite için veri dönüşümü
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'itemId': itemId,
      'type': type,
      'selectedDays': selectedDays.join(','),
      'startDate': startDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'recommendedFrequency': recommendedFrequency,
      'minRestDays': minRestDays,
      'lastUpdated': lastUpdated.toIso8601String(),
      'performanceData': performanceData != null ?
      Map<String, dynamic>.from(performanceData!).toString() : null,
      'isCustom': isCustom ? 1 : 0,
      'dailyExercises': dailyExercises != null ?
      Map<String, dynamic>.from(dailyExercises!).toString() : null,
    };
  }

  // Firebase'den veri alma
  factory UserSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSchedule(
      id: doc.id,
      userId: data['userId'],
      itemId: data['itemId'],
      type: data['type'],
      selectedDays: List<int>.from(data['selectedDays']),
      startDate: (data['startDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      recommendedFrequency: data['recommendedFrequency'],
      minRestDays: data['minRestDays'],
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      performanceData: data['performanceData'] as Map<String, dynamic>?,
      isCustom: data['isCustom'] ?? false,
      dailyExercises: data['dailyExercises'] != null ?
      Map<String, List<Map<String, dynamic>>>.from(data['dailyExercises']) : null,
    );
  }

  // SQLite'dan veri alma
  factory UserSchedule.fromMap(Map<String, dynamic> map) {
    return UserSchedule(
      id: map['id'],
      userId: map['userId'],
      itemId: map['itemId'],
      type: map['type'],
      selectedDays: map['selectedDays'].toString().split(',')
          .map((e) => int.parse(e.trim())).toList(),
      startDate: DateTime.parse(map['startDate']),
      isActive: map['isActive'] == 1,
      recommendedFrequency: map['recommendedFrequency'],
      minRestDays: map['minRestDays'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
      performanceData: map['performanceData'] != null ?
      Map<String, dynamic>.from(
          map['performanceData'] as Map<String, dynamic>
      ) : null,
      isCustom: map['isCustom'] == 1,
      dailyExercises: map['dailyExercises'] != null ?
      Map<String, List<Map<String, dynamic>>>.from(
          map['dailyExercises'] as Map<String, dynamic>
      ) : null,
    );
  }

  // Kopya oluşturma
  UserSchedule copyWith({
    String? id,
    String? userId,
    int? itemId,
    String? type,
    List<int>? selectedDays,
    DateTime? startDate,
    bool? isActive,
    int? recommendedFrequency,
    int? minRestDays,
    DateTime? lastUpdated,
    Map<String, dynamic>? performanceData,
    bool? isCustom,
    Map<String, List<Map<String, dynamic>>>? dailyExercises,
  }) {
    return UserSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      selectedDays: selectedDays ?? this.selectedDays,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
      recommendedFrequency: recommendedFrequency ?? this.recommendedFrequency,
      minRestDays: minRestDays ?? this.minRestDays,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      performanceData: performanceData ?? this.performanceData,
      isCustom: isCustom ?? this.isCustom,
      dailyExercises: dailyExercises ?? this.dailyExercises,
    );
  }

  // Eşitlik kontrolü
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSchedule &&
        other.id == id &&
        other.userId == userId &&
        other.itemId == itemId &&
        other.type == type &&
        listEquals(other.selectedDays, selectedDays) &&
        other.isActive == isActive &&
        other.isCustom == isCustom;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    userId.hashCode ^
    itemId.hashCode ^
    type.hashCode ^
    selectedDays.hashCode ^
    isActive.hashCode ^
    isCustom.hashCode;
  }

  // Debug için toString
  @override
  String toString() {
    return 'UserSchedule(id: $id, userId: $userId, itemId: $itemId, type: $type, '
        'selectedDays: $selectedDays, isActive: $isActive, '
        'recommendedFrequency: $recommendedFrequency, '
        'minRestDays: $minRestDays, dailyExercises: $dailyExercises)';
  }

  // Yardımcı metod
  bool listEquals(List? a, List? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }


  UserSchedule._({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.type,
    required this.selectedDays,
    required this.startDate,
    required this.isActive,
    this.recommendedFrequency,
    this.minRestDays,
    DateTime? lastUpdated,
    this.performanceData,
    required this.isCustom,
    this.dailyExercises,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory UserSchedule({
    required String id,
    required String userId,
    required int itemId,
    required String type,
    required List<int> selectedDays,
    required DateTime startDate,
    bool isActive = true,
    int? recommendedFrequency,
    int? minRestDays,
    DateTime? lastUpdated,
    Map<String, dynamic>? performanceData,
    bool isCustom = false,
    Map<String, List<Map<String, dynamic>>>? dailyExercises,
  }) {
    final validation = UserScheduleValidation.validateUserSchedule(
      userId: userId,
      itemId: itemId,
      type: type,
      selectedDays: selectedDays,
      startDate: startDate,
      recommendedFrequency: recommendedFrequency,
      minRestDays: minRestDays,
    );

    if (!validation.isValid) {
      throw UserScheduleException(validation.message);
    }

    return UserSchedule._(
      id: id,
      userId: userId,
      itemId: itemId,
      type: type,
      selectedDays: selectedDays,
      startDate: startDate,
      isActive: isActive,
      recommendedFrequency: recommendedFrequency,
      minRestDays: minRestDays,
      lastUpdated: lastUpdated,
      performanceData: performanceData,
      isCustom: isCustom,
      dailyExercises: dailyExercises,
    );
  }
}

class UserScheduleException implements Exception {
  final String message;
  UserScheduleException(this.message);

  @override
  String toString() => message;
}
