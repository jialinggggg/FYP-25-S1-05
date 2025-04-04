import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeFavouriteService {
  final SupabaseClient _supabase;
  RecipeFavouriteService(this._supabase);

  Future<void> addFavourite({required int recipeId, required String uid}) async {
    try {
      await _supabase.from('recipes_favourite').insert({
        'recipe_id': recipeId,
        'uid': uid,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error adding to favourites: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFavourites(String uid) async {
    try {
      return await _supabase.from('recipes_favourite').select().eq('uid', uid);
    } catch (e) {
      throw Exception('Error retrieving favourites: $e');
    }
  }

  Future<void> removeFavourite({required int recipeId, required String uid}) async {
    try {
      await _supabase.from('recipes_favourite').delete().eq('recipe_id', recipeId).eq('uid', uid);
    } catch (e) {
      throw Exception('Error removing from favourites: $e');
    }
  }
}