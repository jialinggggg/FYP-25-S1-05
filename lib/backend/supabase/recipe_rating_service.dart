import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeRatingService {
  final SupabaseClient _supabase;
  RecipeRatingService(this._supabase);

  Future<void> addRating({
    required String uid,
    required int recipeId,
    required int rating,
    required String comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5.');
    }
    try {
      await _supabase.from('recipes_rating').insert({
        'uid': uid,
        'recipe_id': recipeId,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error adding rating: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRatings(int recipeId) async {
    try {
      return await _supabase.from('recipes_rating').select().eq('recipe_id', recipeId);
    } catch (e) {
      throw Exception('Error retrieving ratings: $e');
    }
  }
}