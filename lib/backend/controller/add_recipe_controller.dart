import 'package:supabase_flutter/supabase_flutter.dart';
import '../../backend/services/add_recipe_service.dart';
import '../../backend/state/recipe_state.dart';
import '../../backend/entities/recipe.dart';

class AddRecipeController {
  final AddRecipeService _business;
  final RecipeState _state;

  AddRecipeController(this._business, this._state);

  // Add these methods:
  void addDietTag() {
    _state.addDietTag();
  }

  void removeDietTag(int index) {
    _state.removeDietTag(index);
  }

  void addIngredient() {
    _state.addIngredient();
  }

  void removeIngredient(int index) {
    _state.removeIngredient(index);
  }

  void addInstruction() {
    _state.addInstruction();
  }

  void removeInstruction(int index) {
    _state.removeInstruction(index);
  }

  Future<void> searchIngredients(IngredientState ingredient) async {
    final query = ingredient.nameController.text.trim();
    if (query.isEmpty) return;

    try {
      final results = await _business.searchIngredients(query);
      if (results.isNotEmpty) {
        final firstResult = results.first;
        ingredient.ingredientId = firstResult['id'];
        
        final detailedInfo = await _business.getIngredientInfo(firstResult['id']);
        
        _state.updateIngredientUnits(
          ingredient, 
          List<String>.from(detailedInfo['possibleUnits'] ?? ['g'])
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> calculateIngredientNutrition(IngredientState ingredient) async {
    if (ingredient.ingredientId == null || ingredient.amount <= 0) return;

    try {
      final info = await _business.getIngredientInfo(
        ingredient.ingredientId!,
        unit: ingredient.selectedUnit,
        amount: ingredient.amount,
      );

      final nutrition = info['nutrition'] as Map<String, dynamic>;
      final nutrients = nutrition['nutrients'] as List<dynamic>;

      double getNutrientValue(String name) {
        final nutrient = nutrients.firstWhere(
          (n) => (n['name'] as String).toLowerCase().contains(name.toLowerCase()),
          orElse: () => {'amount': 0.0},
        );
        return (nutrient['amount'] as num).toDouble();
      }

      ingredient.caloriesController.text = getNutrientValue('calories').toStringAsFixed(0);
      ingredient.proteinController.text = getNutrientValue('protein').toStringAsFixed(1);
      ingredient.carbsController.text = getNutrientValue('carbohydrate').toStringAsFixed(1);
      ingredient.fatsController.text = getNutrientValue('fat').toStringAsFixed(1);

      _state.updateNutritionTotals();
    } catch (e) {
      rethrow;
    }
  }

  Future<Recipe> saveRecipe() async {
    if (!(_state.formKey.currentState?.validate() ?? false)) {
      throw Exception('Form validation failed');
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to save recipes');
    }

    final ingredients = _state.ingredients.map((i) => {
      'name': i.nameController.text,
      'amount': i.measurementController.text,
      'unit': i.selectedUnit,
      'calories': double.tryParse(i.caloriesController.text) ?? 0,
      'protein': double.tryParse(i.proteinController.text) ?? 0,
      'carbs': double.tryParse(i.carbsController.text) ?? 0,
      'fats': double.tryParse(i.fatsController.text) ?? 0,
    }).toList();

    final instructions = _state.instructions.asMap().map((index, instruction) => 
      MapEntry((index + 1).toString(), instruction.text)).cast<String, String>();

    final diets = _state.dietTags.map((tag) => tag.text).toList();

    return await _business.saveRecipe(
      uid: user.id,
      name: _state.titleController.text,
      image: _state.selectedImage,
      servings: int.tryParse(_state.servingsController.text) ?? 0,
      readyInMinutes: int.tryParse(_state.readyInMinutesController.text) ?? 0,
      dishType: _state.selectedDishType ?? '',
      calories: int.tryParse(_state.caloriesController.text) ?? 0,
      fats: double.tryParse(_state.fatsController.text) ?? 0,
      protein: double.tryParse(_state.proteinController.text) ?? 0,
      carbs: double.tryParse(_state.carbsController.text) ?? 0,
      ingredients: {'items': ingredients},
      instructions: instructions,
      diets: diets,
    );
  }
}