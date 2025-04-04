class BusinessProfile {
  final String uid;
  final String name;
  final String registrationNo;
  final String country;
  final String address;
  final String type;
  final String description;

  BusinessProfile({
    required this.uid,
    required this.name,
    required this.registrationNo,
    required this.country,
    required this.address,
    required this.type,
    required this.description,
  });

  factory BusinessProfile.fromMap(Map<String, dynamic> map) {
    return BusinessProfile(
      uid: map['uid'] as String,
      name: map['name'] as String,
      registrationNo: map['registration_no'] as String,
      country: map['country'] as String,
      address: map['address'] as String,
      type: map['type'] as String,
      description: map['description'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'registration_no': registrationNo,
      'country': country,
      'address': address,
      'type': type,
      'description': description,
    };
  }

  BusinessProfile copyWith({
    String? uid,
    String? name,
    String? registrationNo,
    String? country,
    String? address,
    String? type,
    String? description,
  }) {
    return BusinessProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      registrationNo: registrationNo ?? this.registrationNo,
      country: country ?? this.country,
      address: address ?? this.address,
      type: type ?? this.type,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'BusinessProfile(uid: $uid, name: $name, registrationNo: $registrationNo, country: $country, address: $address, type: $type, description: $description)';
  }
}