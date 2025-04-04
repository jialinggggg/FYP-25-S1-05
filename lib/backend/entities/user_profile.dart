class UserProfile {
  final String uid;
  final String name;
  final String country;
  final String gender;
  final DateTime birthDate;
  final double weight;
  final double height;

  UserProfile({
    required this.uid,
    required this.name,
    required this.country,
    required this.gender,
    required this.birthDate,
    required this.weight,
    required this.height,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      name: map['name'] as String,
      country: map['country'] as String,
      gender: map['gender'] as String,
      birthDate: DateTime.parse(map['birth_date'] as String),
      weight: (map['weight'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'country': country,
      'gender': gender,
      'birth_date': birthDate.toIso8601String(),
      'weight': weight,
      'height': height,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? country,
    String? gender,
    DateTime? birthDate,
    double? weight,
    double? height,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      country: country ?? this.country,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      weight: weight ?? this.weight,
      height: height ?? this.height,
    );
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, name: $name, country: $country, gender: $gender, birthDate: $birthDate, weight: $weight, height: $height)';
  }
}