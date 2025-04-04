class RecipeFavourite {
  final int recipeId;
  final String uid;
  final DateTime createdAt;

  RecipeFavourite({
    required this.recipeId,
    required this.uid,
    required this.createdAt,
  });

  factory RecipeFavourite.fromMap(Map<String, dynamic> map) {
    return RecipeFavourite(
      recipeId: map['recipe_id'] as int,
      uid: map['uid'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipe_id': recipeId,
      'uid': uid,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  RecipeFavourite copyWith({
    int? recipeId,
    String? uid,
    DateTime? createdAt,
  }) {
    return RecipeFavourite(
      recipeId: recipeId ?? this.recipeId,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'RecipeFavourite(recipeId: $recipeId, uid: $uid, createdAt: $createdAt)';
  }
}