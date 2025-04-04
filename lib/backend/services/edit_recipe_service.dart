import '../entities/recipe.dart';
import '../repositories/recipe_repository.dart';
import '../../backend/api/spoonacular_api_service.dart';

class EditRecipeService {
  final RecipeRepository _recipeRepository;
  final SpoonacularApiService _spoonacularService;

  EditRecipeService(this._recipeRepository, this._spoonacularService);

  Future<Recipe> getRecipe(String recipeId) async {
    try {
      final recipe = await _recipeRepository.getRecipe(int.parse(recipeId));
      return recipe;
    } catch (e) {
      throw Exception('Failed to fetch recipe: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchIngredients({required String query}) async {
    try {
      return await _spoonacularService.searchIngredients(query: query);
    } catch (e) {
      throw Exception('Failed to search ingredients: $e');
    }
  }

  Future<Map<String, dynamic>> getIngredientInfo(
    int id, {
    String? unit,
    double? amount,
  }) async {
    try {
      return await _spoonacularService.getIngredientInfo(
        id,
        unit: unit,
        amount: amount,
      );
    } catch (e) {
      throw Exception('Failed to get ingredient info: $e');
    }
  }

  Future<Recipe> updateRecipe({
    required String id,
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
      // Get current recipe to preserve some fields
      final currentRecipe = await _recipeRepository.getRecipe(int.parse(id));
      
      return await _recipeRepository.updateRecipe(
        Recipe(
          id: int.parse(id),
          uid: currentRecipe.uid,
          name: name,
          image: image ?? currentRecipe.image,
          calories: calories,
          carbs: carbs,
          protein: protein,
          fats: fats,
          servings: servings,
          readyInMinutes: readyInMinutes,
          ingredients: ingredients,
          instructions: instructions,
          dishType: dishType,
          diets: diets,
          sourceName: currentRecipe.sourceName,
          sourceType: currentRecipe.sourceType,
          createdAt: currentRecipe.createdAt,
        ),
      );
    } catch (e) {
      throw Exception('Failed to update recipe: $e');
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _recipeRepository.deleteRecipe(int.parse(recipeId));
    } catch (e) {
      throw Exception('Failed to delete recipe: $e');
    }
  }
}