// lib/backend/controllers/edit_recipe_controller.dart

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_type/mime_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/recipes.dart';
import '../entities/extended_ingredient.dart';
import '../entities/analyzed_instruction.dart';
import '../entities/nutrition.dart';
import '../api/spoonacular_service.dart';

class EditRecipeController with ChangeNotifier {
  final SupabaseClient _supabase;
  final SpoonacularService _spoonacularService;
  final int recipeId;

  EditRecipeController(
    this._supabase,
    this._spoonacularService,
    this.recipeId,
  );

  // --- State ---
  String _title = '';
  String? _image;
  String? _imageType;
  int _servings = 1;
  int _readyInMinutes = 0;
  final List<String> _dishTypes = [];
  final List<String> _diets = [];
  List<ExtendedIngredient> _extendedIngredients = [];
  List<AnalyzedInstruction> _analyzedInstructions = [];
  bool _isLoading = false;
  String? _error;

  // Ingredient-search helpers
  final Map<int, List<Map<String, dynamic>>> _ingredientSuggestions = {};
  final Map<int, bool> _loadingIngredientInfo = {};
  final Map<int, int> _ingredientSearchOffset = {};
  final Map<int, List<Map<String, dynamic>>> _allSuggestions = {};

  // --- Getters ---
  String get title => _title;
  String? get image => _image;
  String? get imageType => _imageType;
  int get servings => _servings;
  int get readyInMinutes => _readyInMinutes;
  List<String> get dishTypes => List.unmodifiable(_dishTypes);
  List<String> get diets => List.unmodifiable(_diets);
  List<ExtendedIngredient> get extendedIngredients => _extendedIngredients;
  List<AnalyzedInstruction> get analyzedInstructions => _analyzedInstructions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<int, List<Map<String, dynamic>>> get ingredientSuggestions => _ingredientSuggestions;
  Map<int, bool> get loadingIngredientInfo => _loadingIngredientInfo;

  // --- Simple setters ---
  void setTitle(String v) { _title = v; notifyListeners(); }
  void setServings(int v) { _servings = v; notifyListeners(); }
  void setReadyInMinutes(int v) { _readyInMinutes = v; notifyListeners(); }
  void addDishType(String t) { _dishTypes.add(t); notifyListeners(); }
  void removeDishType(String t) { _dishTypes.remove(t); notifyListeners(); }
  void addDiet(String d) { _diets.add(d); notifyListeners(); }
  void removeDiet(String d) { _diets.remove(d); notifyListeners(); }
  void setExtendedIngredients(List<ExtendedIngredient> l) { _extendedIngredients = l; notifyListeners(); }
  void setAnalyzedInstructions(List<AnalyzedInstruction> l) { _analyzedInstructions = l; notifyListeners(); }

  // --- Status mutation ---
  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? v) { _error = v; notifyListeners(); }

  /// Clears any existing error message.
  void clearError() => _setError(null);

    /// Adds a new ingredient to the end of the list
  void addExtendedIngredient(ExtendedIngredient e) {
    _extendedIngredients = [..._extendedIngredients, e];
    notifyListeners();
  }

  /// Removes the ingredient at index [i]
  void removeExtendedIngredient(int i) {
    final list = List<ExtendedIngredient>.from(_extendedIngredients);
    list.removeAt(i);
    _extendedIngredients = list;
    notifyListeners();
  }

  /// Replaces the ingredient at index [i] with [e]
  void replaceIngredient(int i, ExtendedIngredient e) {
    final list = List<ExtendedIngredient>.from(_extendedIngredients);
    list[i] = e;
    _extendedIngredients = list;
    notifyListeners();
  }

  /// Loads the existing recipe from Supabase.
  Future<void> loadRecipe() async {
    _setLoading(true);
    try {
      final resp = await _supabase
        .from('recipes')
        .select()
        .eq('id', recipeId)
        .single();
      final r = Recipes.fromMap(resp);

      _title = r.title;
      _image = r.image;
      _imageType = r.imageType;
      _servings = r.servings ?? 1;
      _readyInMinutes = r.readyInMinutes ?? 0;
      _dishTypes
        ..clear()
        ..addAll(r.dishTypes ?? []);
      _diets
        ..clear()
        ..addAll(r.diets ?? []);
      _extendedIngredients = r.extendedIngredients ?? [];
      _analyzedInstructions = r.analyzedInstructions ?? [];
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recipe: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Pushes edits back to Supabase and returns the updated recipe.
  Future<Recipes> updateRecipe() async {
    _setLoading(true);
    try {
      final nutrition = calculateTotalNutrition();
      final payload = {
        'title': _title,
        'image': _image,
        'image_type': _imageType,
        'servings': _servings,
        'ready_in_minutes': _readyInMinutes,
        'dish_types': _dishTypes,
        'diets': _diets,
        'extended_ingredients': _extendedIngredients.map((e) => e.toMap()).toList(),
        'analyzed_instructions': _analyzedInstructions.map((i) => i.toMap()).toList(),
        'nutrition': nutrition.toMap(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      final resp = await _supabase
        .from('recipes')
        .update(payload)
        .eq('id', recipeId)
        .select()
        .single();
      return Recipes.fromMap(resp);
    } catch (e) {
      _setError('Failed to update recipe: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --- Ingredient search pipeline ---
  Future<void> searchIngredients(String query, int index) async {
    if (query.isEmpty) return;
    _ingredientSearchOffset[index] = 0;
    _allSuggestions[index] = [];
    try {
      final suggestions = await _spoonacularService.searchIngredients(
        query: query,
        number: 3,
      );
      _allSuggestions[index] = suggestions;
      _ingredientSuggestions[index] = suggestions;
      notifyListeners();
      _ingredientSearchOffset[index] = suggestions.length;
    } catch (e) {
      _setError('Failed to search ingredients: $e');
    }
  }

  Future<void> loadMoreIngredients(int index) async {
    try {
      final name = _extendedIngredients[index].name;
      final more = await _spoonacularService.searchIngredients(
        query: name,
        number: 3,
        offset: _ingredientSearchOffset[index] ?? 0,
      );
      final newOnes = more.where((m) =>
        !_allSuggestions[index]!.any((e) => e['id'] == m['id'])
      ).toList();
      _allSuggestions[index]!.addAll(newOnes);
      _ingredientSuggestions[index] = _allSuggestions[index]!;
      _ingredientSearchOffset[index] = (_ingredientSearchOffset[index] ?? 0) + newOnes.length;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load more ingredients: $e');
    }
  }

  Future<void> selectIngredient(Map<String, dynamic> ingredient, int index) async {
    _loadingIngredientInfo[index] = true;
    notifyListeners();
    try {
      final fetched = await _spoonacularService.getIngredientInformation(
        ingredient['id'],
      );
      final copy = fetched.copyWith(
        amount: fetched.amount,
        unit: fetched.unit,
      );
      final list = List<ExtendedIngredient>.from(_extendedIngredients);
      list[index] = copy;
      _extendedIngredients = list;
      _ingredientSuggestions[index] = [];
      notifyListeners();
    } catch (e) {
      _setError('Failed to fetch ingredient info: $e');
    } finally {
      _loadingIngredientInfo[index] = false;
      notifyListeners();
    }
  }

  Future<void> updateIngredientAmountAndUnit(int index, double amount, String unit) async {
    final ingr = _extendedIngredients[index];
    final updated = ingr.copyWith(amount: amount, unit: unit);
    final list = List<ExtendedIngredient>.from(_extendedIngredients);
    list[index] = updated;
    _extendedIngredients = list;
    notifyListeners();
    if (ingr.nutrition != null) {
      await _updateIngredientNutrition(index, amount, unit);
    }
  }

  Future<void> _updateIngredientNutrition(int index, double amount, String unit) async {
    try {
      final info = await _spoonacularService.getIngredientInformation(
        _extendedIngredients[index].id,
        amount: amount,
        unit: unit,
      );
      final list = List<ExtendedIngredient>.from(_extendedIngredients);
      list[index] = info;
      _extendedIngredients = list;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update ingredient nutrition: $e');
    }
  }

  // --- Nutrition calculator ---
  Nutrition calculateTotalNutrition() {
    final Map<String, double> totals = {};
    for (final ingr in _extendedIngredients) {
      if (ingr.nutrition != null) {
        for (final n in ingr.nutrition!.nutrients) {
          final key = n.title.toLowerCase();
          totals[key] = (totals[key] ?? 0) + n.amount;
        }
      }
    }
    final factor = servings > 0 ? servings : 1;
    final standard = [
      ['calories', 'kcal'],
      ['fat', 'g'],
      ['saturated fat', 'g'],
      ['carbohydrates', 'g'],
      ['sugar', 'g'],
      ['protein', 'g'],
      ['cholesterol', 'mg'],
      ['sodium', 'mg'],
      ['fiber', 'g'],
      ['vitamin d', 'mcg'],
      ['calcium', 'mg'],
      ['iron', 'mg'],
      ['potassium', 'mg'],
      ['vitamin a', 'mcg'],
      ['vitamin c', 'mg'],
    ];
    final result = standard.map<Nutrient>((item) {
      final amt = (totals[item[0]] ?? 0) / factor;
      return Nutrient(
        title: item[0][0].toUpperCase() + item[0].substring(1),
        amount: amt,
        unit: item[1],
      );
    }).toList();
    return Nutrition(nutrients: result);
  }

  // --- Image upload & DB update ---
  Future<void> updateRecipeImage(int recipeId, XFile imageFile) async {
    _setLoading(true);
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final mimeType = mime(imageFile.path) ?? 'image/jpeg';
      final resp = await _supabase.storage
        .from('recipe-images')
        .uploadBinary(fileName, bytes, fileOptions: FileOptions(contentType: mimeType));
      if (resp.isEmpty) throw Exception('Upload failed');
      final url = _supabase.storage.from('recipe-images').getPublicUrl(fileName);

      await _supabase.from('recipes').update({
        'image': url,
        'image_type': mimeType,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', recipeId);

      _image = url;
      _imageType = mimeType;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update recipe image: $e');
    } finally {
      _setLoading(false);
    }
  }
}