class UserMedicalInfo {
  final String uid;
  final List<String> preExisting;
  final List<String> allergies;

  UserMedicalInfo({
    required this.uid,
    required this.preExisting,
    required this.allergies,
  });

  factory UserMedicalInfo.fromMap(Map<String, dynamic> map) {
  return UserMedicalInfo(
    uid: map['uid'] as String,
    preExisting: (map['pre_existing'] as List<dynamic>).map((e) => e.toString()).toList(),
    allergies: (map['allergies'] as List<dynamic>).map((e) => e.toString()).toList(),
  );
}

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'pre_existing': preExisting,
      'allergies': allergies,
    };
  }

  UserMedicalInfo copyWith({
    String? uid,
    List<String>? preExisting,
    List<String>? allergies,
  }) {
    return UserMedicalInfo(
      uid: uid ?? this.uid,
      preExisting: preExisting ?? this.preExisting,
      allergies: allergies ?? this.allergies,
    );
  }

  @override
  String toString() {
    return 'UserMedicalInfo(uid: $uid, preExisting: $preExisting, allergies: $allergies)';
  }
}