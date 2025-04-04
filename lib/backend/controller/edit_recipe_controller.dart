import 'package:flutter/material.dart';
import '../services/edit_recipe_service.dart';
import '../state/recipe_state.dart';
import '../entities/recipe.dart';

class EditRecipeController {
  final EditRecipeService _service;
  final RecipeState _state;

  EditRecipeController(this._service, this._state);

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


  Future<void> loadRecipe(String recipeId) async {
    try {
      final recipe = await _service.getRecipe(recipeId);
      
      _state.titleController.text = recipe.name;
      _state.servingsController.text = recipe.servings.toString();
      _state.readyInMinutesController.text = recipe.readyInMinutes.toString();
      _state.selectedImage = recipe.image;
      _state.selectedDishType = recipe.dishType;
      
      // Load ingredients
      final ingredients = recipe.ingredients['items'] as List? ?? [];
      for (final ingredient in ingredients) {
        final controller = IngredientState()
          ..nameController.text = ingredient['name'] ?? ''
          ..measurementController.text = ingredient['amount']?.toString() ?? '0'
          ..selectedUnit = ingredient['unit'] ?? 'g'
          ..caloriesController.text = ingredient['calories']?.toString() ?? '0'
          ..proteinController.text = ingredient['protein']?.toString() ?? '0'
          ..carbsController.text = ingredient['carbs']?.toString() ?? '0'
          ..fatsController.text = ingredient['fats']?.toString() ?? '0';
        _state.ingredients.add(controller);
      }

      // Load instructions
      final instructions = recipe.instructions;
      final sortedSteps = instructions.entries.toList()
        ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
      for (final step in sortedSteps) {
        final controller = TextEditingController(text: step.value);
        _state.instructions.add(controller);
      }

      // Load diet tags
      final diets = recipe.diets ?? [];
      for (final diet in diets) {
        final controller = TextEditingController(text: diet);
        _state.dietTags.add(controller);
      }

      _state.updateNutritionTotals();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> searchIngredients(IngredientState ingredient) async {
    final query = ingredient.nameController.text.trim();
    if (query.isEmpty) return;

    try {
      final results = await _service.searchIngredients(query:query);
      if (results.isNotEmpty) {
        final firstResult = results.first;
        ingredient.ingredientId = firstResult['id'];
        
        final detailedInfo = await _service.getIngredientInfo(firstResult['id']);
        
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
      final info = await _service.getIngredientInfo(
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

  Future<Recipe> updateRecipe(String recipeId) async {
    if (!_state.formKey.currentState!.validate()) {
      throw Exception('Form validation failed');
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

    return await _service.updateRecipe(
      id: recipeId,
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

  Future<void> deleteRecipe(String recipeId) async {
    await _service.deleteRecipe(recipeId);
  }
}