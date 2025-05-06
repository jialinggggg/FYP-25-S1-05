import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart'; 
import '../api/spoonacular_service.dart';
import '../entities/recipes.dart';

class FetchRecipeForMealLogController extends ChangeNotifier {  // Extend ChangeNotifier
  final SupabaseClient supabaseClient;
  final SpoonacularService _spoonacularService;
  
  bool isLoading = false; // Add an isLoading property
  List<Recipes> recipes = []; // Store recipes here
  
  FetchRecipeForMealLogController(this.supabaseClient, this._spoonacularService,);

  // Fetch food/recipes, favorite, and custom recipes
  Future<void> fetchRecipes(String uid, String tab) async {
    try {
      isLoading = true;  // Set isLoading to true while fetching data
      notifyListeners();  // Notify listeners

      List<Recipes> newRecipes = [];

      // Check the tab to fetch data from the respective sources
      if (tab == "Recent") {
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(Duration(days: 7));

        // Query the meal_log table to get records created in the last 7 days
        final mealLogResponse = await supabaseClient
            .from('meal_log')
            .select()
            .eq('uid', uid)
            .gte('created_at', sevenDaysAgo.toIso8601String()); // Filter by date

        Set<int> recipeIds = {}; // To track unique recipes by recipe_id
        Set<Recipes> uniqueRecipes = {}; // To store unique recipe objects

        if (mealLogResponse.isNotEmpty) {
          for (var log in mealLogResponse) {
            final recipeId = log['recipe_id'];
            final sourceType = log['source_type'];

            if (!recipeIds.contains(recipeId)) { // Ensure uniqueness by checking recipeId
              recipeIds.add(recipeId);

              if (sourceType == 'user' || sourceType == 'business' || sourceType == 'nutritionist') {
                final recipeResponse = await supabaseClient
                    .from('recipes')
                    .select()
                    .eq('id', recipeId);

                if (recipeResponse.isNotEmpty) {
                  uniqueRecipes.add(Recipes.fromMap(recipeResponse[0]));
                }
              } else if (sourceType == 'spoonacular') {
                final spoonacularRecipe = await _spoonacularService.fetchRecipeById(recipeId);
                uniqueRecipes.add(spoonacularRecipe);
              }
            }
          }
        }

        newRecipes = uniqueRecipes.toList();
      } else if (tab == "Favourite") {
        final favResponse = await supabaseClient
            .from('recipes_favourite')
            .select()
            .eq('uid', uid);

        if (favResponse.isNotEmpty) {
          for (var fav in favResponse) {
            final recipeId = fav['recipe_id'];
            final sourceType = fav['source_type'];

            if (sourceType == 'user' || sourceType == 'business' || sourceType == 'nutritionist') {
              final recipeResponse = await supabaseClient
                  .from('recipes')
                  .select()
                  .eq('id', fav['recipe_id']);

              if (recipeResponse.isNotEmpty) {
                newRecipes.add(Recipes.fromMap(recipeResponse[0]));
              }
            } else if (sourceType == 'spoonacular') {
              final spoonacularRecipe = await _spoonacularService.fetchRecipeById(recipeId);
              newRecipes.add(spoonacularRecipe);
            }
          }
        }
      } else if (tab == "Created") {
        final customResponse = await supabaseClient
            .from('recipes')
            .select()
            .eq('uid', uid);

        if (customResponse.isNotEmpty) {
          for (var custom in customResponse) {
            newRecipes.add(Recipes.fromMap(custom));
          }
        }
      }

      recipes = newRecipes;
        // Assign the fetched recipes
      isLoading = false;  // Set isLoading to false after the data is fetched
      notifyListeners();  // Notify listeners after the data is updated
    } catch (e) {
      isLoading = false;  // Set isLoading to false if an error occurs
      notifyListeners();  // Notify listeners even if an error occurs
      throw Exception("Error fetching recipes: $e");
    }
  }
}
