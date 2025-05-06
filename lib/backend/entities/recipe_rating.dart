class RecipeRating {
  final String ratingId;
  final String uid;
  final int recipeId;
  final int rating;
  final String comment;
  final String sourceType;
  final DateTime createdAt;

  RecipeRating({
    required this.ratingId,
    required this.uid,
    required this.recipeId,
    required this.rating,
    required this.comment,
    required this.sourceType,
    required this.createdAt,
  });

  factory RecipeRating.fromMap(Map<String, dynamic> map) {
    return RecipeRating(
      ratingId: map['rating_id'] as String,
      uid: map['uid'] as String,
      recipeId: map['recipe_id'] as int,
      rating: map['rating'] as int,
      comment: map['comment'] as String,
      sourceType: map['source_type'] as String,
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
      'source_type': sourceType,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}