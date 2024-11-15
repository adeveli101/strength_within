class PartFrequency {
  final int? id;
  final int partId;
  final int recommendedFrequency;
  final int minRestDays;

  PartFrequency({
    this.id,
    required this.partId,
    required this.recommendedFrequency,
    required this.minRestDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partId': partId,
      'recommendedFrequency': recommendedFrequency,
      'minRestDays': minRestDays,
    };
  }

  factory PartFrequency.fromMap(Map<String, dynamic> map) {
    return PartFrequency(
      id: map['id'],
      partId: map['partId'],
      recommendedFrequency: map['recommendedFrequency'],
      minRestDays: map['minRestDays'],
    );
  }
}