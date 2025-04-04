class UserMeasurement {
  final String measurementId;
  final String uid;
  final double weight;
  final double height;
  final double bmi;
  final DateTime createdAt;

  UserMeasurement({
    required this.measurementId,
    required this.uid,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.createdAt,
  });

  factory UserMeasurement.fromMap(Map<String, dynamic> map) {
    return UserMeasurement(
      measurementId: map['measurement_id'] as String,
      uid: map['uid'] as String,
      weight: (map['weight'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      bmi: (map['bmi'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'measurement_id': measurementId,
      'uid': uid,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  UserMeasurement copyWith({
    String? measurementId,
    String? uid,
    double? weight,
    double? height,
    double? bmi,
    DateTime? createdAt,
  }) {
    return UserMeasurement(
      measurementId: measurementId ?? this.measurementId,
      uid: uid ?? this.uid,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bmi: bmi ?? this.bmi,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserMeasurement(measurementId: $measurementId, uid: $uid, weight: $weight, height: $height, bmi: $bmi, createdAt: $createdAt)';
  }
}