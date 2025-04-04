import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/recipe_rating.dart';

class RecipeRatingRepository {
  final SupabaseClient _supabase;

  RecipeRatingRepository(this._supabase);

  Future<void> addRating(RecipeRating rating) async {
    try {
      await _supabase.from('recipes_rating').insert(rating.toMap());
    } catch (e) {
      throw Exception('Error adding rating: $e');
    }
  }

  Future<List<RecipeRating>> getRatings(int recipeId) async {
    try {
      final response = await _supabase
          .from('recipes_rating')
          .select()
          .eq('recipe_id', recipeId);
      return response.map<RecipeRating>((map) => RecipeRating.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error retrieving ratings: $e');
    }
  }
}