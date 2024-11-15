import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/Parts.dart';
import '../utils/routine_helpers.dart';

class FirebaseParts {
  final String id;
  final String name;
  final int bodyPartId;
  final SetType setType;
  final String additionalNotes;
  final bool isFavorite;
  final bool isCustom;
  final int? userProgress;
  final DateTime? lastUsedDate;
  final bool? userRecommended;
  final List<String> exerciseIds;

  FirebaseParts({
    required this.id,
    required this.name,
    required this.bodyPartId,
    required this.setType,
    this.additionalNotes = '',
    this.isFavorite = false,
    this.isCustom = false,
    this.userProgress,
    this.lastUsedDate,
    this.userRecommended,
    required this.exerciseIds,
  });

  String get setTypeString => setTypeToStringConverter(setType);
  Color get setTypeColor => setTypeToColorConverter(setType);
  int get exerciseCount => setTypeToExerciseCountConverter(setType);

  factory FirebaseParts.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Tüm alanlar için null kontrolü yapıyoruz ve varsayılan değerler atıyoruz
      return FirebaseParts(
        id: doc.id,
        name: data['name'] as String? ?? '',
        bodyPartId: (data['bodyPartId'] as num?)?.toInt() ?? 0,
        setType: SetType.values[(data['setType'] as num?)?.toInt() ?? 0],
        additionalNotes: data['additionalNotes'] as String? ?? '',
        isFavorite: data['isFavorite'] as bool? ?? false,
        isCustom: data['isCustom'] as bool? ?? false,
        userProgress: (data['userProgress'] as num?)?.toInt(),
        lastUsedDate: data['lastUsedDate'] != null
            ? (data['lastUsedDate'] as Timestamp).toDate()
            : null,
        userRecommended: data['userRecommended'] as bool? ?? false,
        exerciseIds: List<String>.from(data['exerciseIds'] ?? []),
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing FirebaseParts from document ${doc.id}: $e\n$stackTrace');
      // Hata durumunda varsayılan bir FirebaseParts objesi dönüyoruz
      return FirebaseParts(
        id: doc.id,
        name: '',
        bodyPartId: 0,
        setType: SetType.values[0],
        exerciseIds: [],
      );
    }
  }



  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'bodyPartId': bodyPartId,
      'setType': setType.index,
      'additionalNotes': additionalNotes,
      'isFavorite': isFavorite,
      'isCustom': isCustom,
      'userProgress': userProgress,
      'lastUsedDate': lastUsedDate != null ? Timestamp.fromDate(lastUsedDate!) : null,
      'userRecommended': userRecommended,
      'exerciseIds': exerciseIds,
    };
  }

  FirebaseParts copyWith({
    String? id,
    String? name,
    int? bodyPartId,
    SetType? setType,
    String? additionalNotes,
    bool? isFavorite,
    bool? isCustom,
    int? userProgress,
    DateTime? lastUsedDate,
    bool? userRecommended,
    List<String>? exerciseIds,
  }) {
    return FirebaseParts(
      id: id ?? this.id,
      name: name ?? this.name,
      bodyPartId: bodyPartId ?? this.bodyPartId,
      setType: setType ?? this.setType,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      isFavorite: isFavorite ?? this.isFavorite,
      isCustom: isCustom ?? this.isCustom,
      userProgress: userProgress ?? this.userProgress,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
      userRecommended: userRecommended ?? this.userRecommended,
      exerciseIds: exerciseIds ?? this.exerciseIds,
    );
  }

  factory FirebaseParts.fromMap(Map<String, dynamic> map) {
    return FirebaseParts(
      id: map['id'] as String,
      name: map['name'] as String,
      bodyPartId: map['bodyPartId'] as int,
      setType: SetType.values[map['setType'] as int],
      additionalNotes: map['additionalNotes'] as String? ?? '',
      isFavorite: map['isFavorite'] as bool? ?? false,
      isCustom: map['isCustom'] as bool? ?? false,
      userProgress: map['userProgress'] as int?,
      lastUsedDate: map['lastUsedDate'] != null ? DateTime.parse(map['lastUsedDate'] as String) : null,
      userRecommended: map['userRecommended'] as bool?,
      exerciseIds: List<String>.from(map['exerciseIds'] ?? []),
    );
  }


  List<int> get safeExerciseIds {
    return exerciseIds.whereType<int>().toList();
  }



  @override
  String toString() {
    return 'FirebasePart(id: $id, name: $name, bodyPartId: $bodyPartId, setType: $setTypeString, additionalNotes: $additionalNotes, isFavorite: $isFavorite, isCustom: $isCustom, userProgress: $userProgress, lastUsedDate: $lastUsedDate, userRecommended: $userRecommended, exerciseIds: $exerciseIds)';
  }
}
