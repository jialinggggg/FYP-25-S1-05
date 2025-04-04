class RecipeRating {
  final String ratingId;
  final String uid;
  final int recipeId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  RecipeRating({
    required this.ratingId,
    required this.uid,
    required this.recipeId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory RecipeRating.fromMap(Map<String, dynamic> map) {
    return RecipeRating(
      ratingId: map['rating_id'] as String,
      uid: map['uid'] as String,
      recipeId: map['recipe_id'] as int,
      rating: map['rating'] as int,
      comment: map['comment'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rating_id': ratingId,
      'uid': uid,
      'recipe_id': recipeId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  RecipeRating copyWith({
    String? ratingId,
    String? uid,
    int? recipeId,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return RecipeRating(
      ratingId: ratingId ?? this.ratingId,
      uid: uid ?? this.uid,
      recipeId: recipeId ?? this.recipeId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'RecipeRating(ratingId: $ratingId, uid: $uid, recipeId: $recipeId, rating: $rating, comment: $comment, createdAt: $createdAt)';
  }
}