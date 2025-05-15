import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeManagementController {
  final SupabaseClient supabase;

  RecipeManagementController({
    required this.supabase,
  });

  Future<List<Map<String, dynamic>>> fetchRecipes() async {
    // Fetch recipes
    final response = await supabase.from('recipes').select();

    // Fetch hidden recipes
    final hiddenResponse = await supabase.from('recipes_hide').select('recipe_id');
    final hiddenRecipeIds = (hiddenResponse as List).map((e) => e['recipe_id']).toSet();

    // Fetch submitter names
    for (var recipe in response) {
      final uid = recipe['uid'];
      recipe['hidden'] = hiddenRecipeIds.contains(recipe['id']);

      final userProfile = await supabase.from('user_profiles').select('name').eq('uid', uid).maybeSingle();
      final businessProfile = await supabase.from('business_profiles').select('name').eq('uid', uid).maybeSingle();
      final nutritionistProfile = await supabase.from('nutritionist_profiles').select('full_name').eq('uid', uid).maybeSingle();

      recipe['submitter_name'] = userProfile?['name'] ??
          businessProfile?['name'] ??
          nutritionistProfile?['full_name'] ??
          'Unknown';
    }

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> fetchRecipeById(int recipeId) async {
    try {
      final response = await supabase.from('recipes').select().eq('id', recipeId).maybeSingle();
      return response;
    } catch (e) {
      print("Error fetching recipe: $e");
      return null;
    }
  }
}