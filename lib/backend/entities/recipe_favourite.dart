class RecipeFavourite {
  final int recipeId;
  final String uid;
  final String sourceType;
  final DateTime createdAt;

  RecipeFavourite({
    required this.recipeId,
    required this.uid,
    required this.sourceType,
    required this.createdAt,
  });

  factory RecipeFavourite.fromMap(Map<String, dynamic> map) {
    return RecipeFavourite(
      recipeId: map['recipe_id'] as int,
      uid: map['uid'] as String,
      sourceType: map['source_type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipe_id': recipeId,
      'uid': uid,
      'source_type': sourceType,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  RecipeFavourite copyWith({
    int? recipeId,
    String? uid,
    String? sourceType,
    DateTime? createdAt,
  }) {
    return RecipeFavourite(
      recipeId: recipeId ?? this.recipeId,
      uid: uid ?? this.uid,
      sourceType: sourceType ?? this.sourceType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'RecipeFavourite(recipeId: $recipeId, uid: $uid, createdAt: $createdAt)';
  }
}