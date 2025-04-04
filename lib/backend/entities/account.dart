class Account {
  final String uid;
  final String email;
  final String type; // 'admin', 'user', 'business'
  final String status;

  Account({
    required this.uid,
    required this.email,
    required this.type,
    required this.status,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      uid: map['uid'] as String,
      email: map['email'] as String,
      type: map['type'] as String,
      status: map['status'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'type': type,
      'status': status,
    };
  }

  Account copyWith({
    String? uid,
    String? email,
    String? type,
    String? status,
  }) {
    return Account(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'Account(uid: $uid, email: $email, type: $type, status: $status)';
  }
}