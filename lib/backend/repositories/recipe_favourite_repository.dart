import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/recipe_favourite.dart';

class RecipeFavouriteRepository {
  final SupabaseClient _supabase;

  RecipeFavouriteRepository(this._supabase);

  Future<void> addFavourite(RecipeFavourite favourite) async {
    try {
      await _supabase.from('recipes_favourite').insert(favourite.toMap());
    } catch (e) {
      throw Exception('Error adding to favourites: $e');
    }
  }

  Future<List<RecipeFavourite>> getFavourites(String uid) async {
    try {
      final response = await _supabase
          .from('recipes_favourite')
          .select()
          .eq('uid', uid);
      return response.map<RecipeFavourite>((map) => RecipeFavourite.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error retrieving favourites: $e');
    }
  }

  Future<void> removeFavourite(RecipeFavourite favourite) async {
    try {
      await _supabase.from('recipes_favourite')
          .delete()
          .eq('recipe_id', favourite.recipeId)
          .eq('uid', favourite.uid);
    } catch (e) {
      throw Exception('Error removing from favourites: $e');
    }
  }
}