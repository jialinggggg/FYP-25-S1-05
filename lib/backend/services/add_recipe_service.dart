import '../../backend/entities/recipe.dart';
import '../repositories/recipe_repository.dart';
import '../api/spoonacular_api_service.dart';

class AddRecipeService {
  final RecipeRepository _recipeRepository;
  final SpoonacularApiService _spoonacularService;

  AddRecipeService(this._recipeRepository, this._spoonacularService);

  Future<List<Map<String, dynamic>>> searchIngredients(String query) async {
    return await _spoonacularService.searchIngredients(query: query);
  }

  Future<Map<String, dynamic>> getIngredientInfo(
    int id, {
    String? unit,
    double? amount,
  }) async {
    return await _spoonacularService.getIngredientInfo(
      id,
      unit: unit,
      amount: amount,
    );
  }

  Future<Recipe> saveRecipe({
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
    return await _recipeRepository.insertRecipe(
      uid: uid,
      name: name,
      image: image,
      servings: servings,
      readyInMinutes: readyInMinutes,
      dishType: dishType,
      calories: calories,
      fats: fats,
      protein: protein,
      carbs: carbs,
      ingredients: ingredients,
      instructions: instructions,
      diets: diets,
    );
  }
}