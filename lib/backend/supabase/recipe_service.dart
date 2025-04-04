import 'package:supabase_flutter/supabase_flutter.dart';
import 'accounts_service.dart';
import 'business_profiles_service.dart';
import 'user_profiles_service.dart';

class RecipeService {
  final SupabaseClient _supabase;
  final AccountService _accountService;
  final UserProfilesService _userProfilesService;
  final BusinessProfilesService _businessProfilesService;

  RecipeService(
    this._supabase,
    this._accountService,
    this._userProfilesService,
    this._businessProfilesService,
  );

  // Create a new recipe
  Future<Map<String, dynamic>> insertRecipe({
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
      if (name.isEmpty || readyInMinutes <= 0) {
        throw Exception('Name and time are required');
      }

      // 1. Get account type from accounts service
      final account = await _accountService.fetchAccount(uid);
      if (account == null) {
        throw Exception('Account not found');
      }
      final accountType = account['type'];

      // 2. Get source based on account type
      String source;
      if (accountType == 'business') {
        final businessProfile = await _businessProfilesService.fetchBizProfile(uid);
        source = businessProfile?['name'] ?? 'Unknown Business';
      } else {
        final userProfile = await _userProfilesService.fetchProfile(uid);
        source = userProfile?['name'] ?? 'Unknown User';
      }

      // 3. Insert recipe with the determined type and source
      final response = await _supabase
          .from('recipe')
          .insert({
            'uid': uid,
            'sourceType': accountType, // Use account type from accounts table
            'sourceName': source,    // Use name from profile
            'name': name,
            'image': image,
            'servings': servings,
            'dishType': dishType,
            'calories': calories,
            'fats': fats,
            'protein': protein,
            'carbs': carbs,
            'readyInMinute': readyInMinutes,
            'ingredients': ingredients,
            'instructions': instructions,
            'diets': diets,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create recipe: $e');
    }
  }

  // Get a single recipe by ID
  Future<Map<String, dynamic>> getRecipe(String id) async {
    try {
      if (id.isEmpty) {
        throw Exception('Recipe ID is required');
      }

      final response = await _supabase
          .from('recipe')
          .select()
          .eq('id', id)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch recipe: $e');
    }
  }

  // Get all recipes for a specific user
  Future<List<Map<String, dynamic>>> getUserRecipes(String uid) async {
    try {
      if (uid.isEmpty) {
        throw Exception('User ID is required');
      }

      final response = await _supabase
          .from('recipe')
          .select()
          .eq('uid', uid)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      throw Exception('Failed to fetch user recipes: $e');
    }
  }

  // Update a recipe
  Future<Map<String, dynamic>> updateRecipe({
    required String id,
    required String uid,
    String? name,
    String? image,
    int? calories,
    double? fats,
    double? protein,
    double? carbs,
    int? time,
    Map<String, dynamic>? ingredients,
    Map<String, dynamic>? instructions,
    List<String>? diets,
  }) async {
    try {
      final recipe = await getRecipe(id);
      final user = _supabase.auth.currentUser;
      
      if (recipe['uid'] != uid && user?.id != uid) {
        throw Exception('Unauthorized: You can only update your own recipes');
      }

      final response = await _supabase
          .from('recipe')
          .update({
            if (name != null) 'name': name,
            if (image != null) 'image': image,
            if (calories != null) 'calories': calories,
            if (fats != null) 'fats': fats,
            if (protein != null) 'protein': protein,
            if (carbs != null) 'carbs': carbs,
            if (time != null) 'time': time,
            if (ingredients != null) 'ingredients': ingredients,
            if (instructions != null) 'instructions': instructions,
            if (diets != null) 'diets': diets,
          })
          .eq('id', id)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update recipe: $e');
    }
  }

  // Delete a recipe
  Future<void> deleteRecipe({
    required String id,
    required String uid,
  }) async {
    try {
      final recipe = await getRecipe(id);
      final user = _supabase.auth.currentUser;
      
      if (recipe['uid'] != uid && user?.id != uid) {
        throw Exception('Unauthorized: You can only delete your own recipes');
      }

      await _supabase.from('recipe').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete recipe: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecipesByType(String type, {int offset = 0}) async {
  try {
    if (type.isEmpty) {
      throw Exception('Type is required');
    }

    final response = await _supabase
        .from('recipe')
        .select()
        .eq('type', type)
        .order('created_at', ascending: false)
        .range(offset, offset + 4); // Get 5 recipes at a time

    // Filter out recipes from the current user
    final currentUser = _supabase.auth.currentUser?.id;
    if (currentUser != null) {
      return response.where((recipe) => recipe['uid'] != currentUser).toList();
    }
    
    return response;
  } catch (e) {
    throw Exception('Failed to fetch recipes by type: $e');
  }
}
}