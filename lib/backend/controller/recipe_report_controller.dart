import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/spoonacular_api_service.dart';

class RecipeReportController {
  final SupabaseClient supabase;
  final SpoonacularApiService apiService;

  RecipeReportController({
    required this.supabase,
    required this.apiService,
  });

  Future<void> acceptRecipeReport(int recipeId, String sourceType, String reportId) async {
    await supabase.from('recipes_hide').insert({'recipe_id': recipeId, 'source_type': sourceType,});
    await supabase.from('recipes_report').update({'status': 'approved'}).eq('report_id', reportId);
  }

  Future<void> rejectRecipeReport(String reportId, int recipeId) async {
    await supabase.from('recipes_report').update({'status': 'rejected'}).eq('report_id', reportId);
    await supabase.from('recipes_hide').delete().eq('recipe_id', recipeId);
  }

  Future<void> acceptProductReport(String reportId) async {
    await supabase.from('product_report').update({'status': 'approved'}).eq('id', reportId);
  }

  Future<void> rejectProductReport(String reportId) async {
    await supabase.from('product_report').update({'status': 'rejected'}).eq('id', reportId);
  }

  Future<void> hideRecipe(int recipeId, String sourceType, String createdAt) async {
    try {
      await supabase.from('recipes_hide').insert({
        'recipe_id': recipeId,
        'source_type': sourceType,
        'created_at': createdAt,
      });
      print("Recipe $recipeId hidden successfully.");
    } catch (e) {
      print("Error hiding recipe $recipeId: $e");
      throw e;
    }
  }

  Future<void> unhideRecipe(int recipeId) async {
    try {
      await supabase.from('recipes_hide').delete().eq('recipe_id', recipeId);
      print("Recipe $recipeId unhidden successfully.");
    } catch (e) {
      print("Error unhiding recipe $recipeId: $e");
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecipeReports() async {
    final reports = await supabase.from('recipes_report').select().order('created_at', ascending: false);

    final apiService = SpoonacularApiService();
    List<Map<String, dynamic>> result = [];

    for (final report in reports) {
      final recipeId = report['recipe_id'];
      final sourceType = report['source_type'];

      Map<String, dynamic>? recipe;

      try {
        if (sourceType == 'user' || sourceType == 'business' || sourceType == 'nutritionist') {
          recipe = await supabase.from('recipes').select().eq('id', recipeId).maybeSingle();
          if (recipe == null) {
            print('Local recipe not found: $recipeId');
            continue;
          }
        } else if (sourceType == 'spoonacular') {
          recipe = await apiService.fetchRecipeById(recipeId);
          if (recipe == null) {
            print('Spoonacular recipe not found: $recipeId');
            continue;
          }
        }

        if (recipe == null) continue;

        // UID-to-name logic for all source types
        final uid = report['uid'];
        String submitterName = 'Unknown';

        if (uid != null) {
          final userProfile = await supabase.from('user_profiles').select('name').eq('uid', uid).maybeSingle();
          final businessProfile = await supabase.from('business_profiles').select('name').eq('uid', uid).maybeSingle();
          final nutritionistProfile = await supabase.from('nutritionist_profiles').select('full_name').eq('uid', uid).maybeSingle();

          submitterName = userProfile?['name'] ??
              businessProfile?['name'] ??
              nutritionistProfile?['full_name'] ??
              'Unknown';
        }

        recipe['submitter_name'] = submitterName;

        final combined = {
          ...report,
          ...recipe,
        };
        result.add(combined);
        print ('Combined report and recipe: $combined');
      } catch (e) {
        print('Error processing report for recipe ID $recipeId: $e');
        continue;
      }
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> fetchProductReports() async {
    final reports = await supabase.from('product_report').select().order('created_at', ascending: false);

    List<Map<String, dynamic>> result = [];

    for (final report in reports) {
      final productId = report['product_id'];
      Map<String, dynamic>? product;

      try {
        product = await supabase.from('products').select().eq('id', productId).maybeSingle();

        if (product == null) continue;

        // UID-to-name logic
        final uid = report['user_id'];
        String submitterName = 'Unknown';

        if (uid != null) {
          final userProfile = await supabase.from('user_profiles').select('name').eq('uid', uid).maybeSingle();
          final businessProfile = await supabase.from('business_profiles').select('name').eq('uid', uid).maybeSingle();
          final nutritionistProfile = await supabase.from('nutritionist_profiles').select('full_name').eq('uid', uid).maybeSingle();

          submitterName = userProfile?['name'] ??
              businessProfile?['name'] ??
              nutritionistProfile?['full_name'] ??
              'Unknown';
        }

        product['submitter_name'] = submitterName;

        final combined = {
          ...product,
          ...report,
        };

        result.add(combined);
        print('Combined report and recipe: $combined');
      } catch (e) {
        print('Error processing report for product ID $productId: $e');
        continue;
      }
    }
    return result;
  }

}