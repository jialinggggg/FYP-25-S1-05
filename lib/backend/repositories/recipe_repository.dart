import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/recipe.dart';
import 'account_repository.dart';
import 'business_profiles_repository.dart';
import 'user_profiles_repository.dart';

class RecipeRepository {
  final SupabaseClient _supabase;
  final AccountRepository _accountService;
  final UserProfilesRepository _userProfilesService;
  final BusinessProfilesRepository _businessProfilesService;

  RecipeRepository(
    this._supabase,
    this._accountService,
    this._userProfilesService,
    this._businessProfilesService,
  );

  Future<Recipe> insertRecipe({
  required String uid,
  required String name,
  String? image,
  required int servings,
  required int readyInMinutes,
  required String dishType,
  required int calories,
  required double fats,
  required double protein,
  required double carbs,
  required Map<String, dynamic> ingredients,
  required Map<String, dynamic> instructions,
  List<String>? diets,
}) async {
  try {
    final account = await _accountService.fetchAccount(uid);
    if (account == null) throw Exception('Account not found');

    String sourceName;
    String sourceType;
    
    if (account.type == 'business') {
      final businessProfile = await _businessProfilesService.fetchProfile(uid);
      sourceName = businessProfile?.name ?? 'Unknown Business';
      sourceType = 'business';
    } else {
      final userProfile = await _userProfilesService.fetchProfile(uid);
      sourceName = userProfile?.name ?? 'Unknown User';
      sourceType = 'user';
    }

    final response = await _supabase
        .from('recipe')
        .insert({
          'uid': uid,
          'name': name,
          'image': image,
          'servings': servings,
          'ready_in_minutes': readyInMinutes,
          'dish_type': dishType,
          'calories': calories,
          'fats': fats,
          'protein': protein,
          'carbs': carbs,
          'ingredients': ingredients,
          'instructions': instructions,
          'diets': diets,
          'source_name': sourceName,
          'source_type': sourceType,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    return Recipe.fromMap(response);
  } catch (e) {
    throw Exception('Failed to create recipe: $e');
  }
}

  Future<Recipe> getRecipe(int id) async {
    try {
      final response = await _supabase
          .from('recipe')
          .select()
          .eq('id', id)
          .single();
      return Recipe.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch recipe: $e');
    }
  }

  Future<List<Recipe>> getUserRecipes(String uid) async {
    try {
      final response = await _supabase
          .from('recipe')
          .select()
          .eq('uid', uid)
          .order('created_at', ascending: false);
      return response.map<Recipe>((map) => Recipe.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user recipes: $e');
    }
  }

  Future<Recipe> updateRecipe(Recipe recipe) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (recipe.uid != currentUser?.id) {
        throw Exception('Unauthorized: You can only update your own recipes');
      }

      final response = await _supabase
          .from('recipe')
          .update(recipe.toMap())
          .eq('id', recipe.id)
          .select()
          .single();

      return Recipe.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update recipe: $e');
    }
  }

  Future<void> deleteRecipe(int id) async {
    try {
      final recipe = await getRecipe(id);
      final currentUser = _supabase.auth.currentUser;
      
      if (recipe.uid != currentUser?.id) {
        throw Exception('Unauthorized: You can only delete your own recipes');
      }

      await _supabase.from('recipe').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete recipe: $e');
    }
  }

  Future<List<Recipe>> getRecipesByType(String type, {int limit = 10, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('recipe')
          .select()
          .eq('dish_type', type)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final currentUser = _supabase.auth.currentUser?.id;
      if (currentUser != null) {
        return response
            .where((recipe) => recipe['uid'] != currentUser)
            .map<Recipe>((map) => Recipe.fromMap(map))
            .toList();
      }
      
      return response.map<Recipe>((map) => Recipe.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recipes by type: $e');
    }
  }
}