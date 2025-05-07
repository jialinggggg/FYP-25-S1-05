import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_type/mime_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/recipes.dart';
import '../entities/extended_ingredient.dart';
import '../entities/analyzed_instruction.dart';
import '../entities/nutrition.dart';
import '../api/spoonacular_service.dart';

class AddRecipeController with ChangeNotifier {
  final SupabaseClient _supabase;
  final SpoonacularService _spoonacularService;

  AddRecipeController(this._supabase, this._spoonacularService);

  // State variables
  String _title = '';
  String? _image;
  int _servings = 0;
  int _readyInMinutes = 0;
  String? _imageType;
  final List<String> _dishTypes = [];
  final List<String> _diets = [];
  List<ExtendedIngredient> _extendedIngredients = [];
  List<AnalyzedInstruction> _analyzedInstructions = [];
  bool _isLoading = false;
  String? _error;
  Recipes? _recipe;
  final Map<int, List<Map<String, dynamic>>> _ingredientSuggestions = {};
  final Map<int, bool> _loadingIngredientInfo = {};
  final Map<int, int> _ingredientSearchOffset = {};
  final Map<int, List<Map<String, dynamic>>> _allSuggestions = {};

  // Getters
  String get title => _title;
  String? get image => _image;
  int get servings => _servings;
  int get readyInMinutes => _readyInMinutes;
  String? get imageType => _imageType;
  List<String> get dishTypes => List.unmodifiable(_dishTypes);
  List<String> get diets => List.unmodifiable(_diets);
  List<ExtendedIngredient> get extendedIngredients => _extendedIngredients;
  List<AnalyzedInstruction> get analyzedInstructions => List.unmodifiable(_analyzedInstructions);
  bool get isLoading => _isLoading;
  String? get error => _error;
  Recipes? get recipe => _recipe;
  List<Map<String, dynamic>> getIngredientSuggestions(int index) => _ingredientSuggestions[index] ?? [];
  bool isLoadingIngredientInfo(int index) => _loadingIngredientInfo[index] ?? false;

  // Setters
  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setImage(String? value) {
    _image = value;
    notifyListeners();
  }

  void setImageType(String? value) {
    _imageType = value;
    notifyListeners();
  }

  void setServings(int value) {
    _servings = value;
    notifyListeners();
  }

  void setReadyInMinutes(int value) {
    _readyInMinutes = value;
    notifyListeners();
  }

  // Dish Types Methods
  void addDishType(String type) {
    _dishTypes.add(type);
    notifyListeners();
  }

  void removeDishType(String type) {
    _dishTypes.remove(type);
    notifyListeners();
  }

  // Diets Methods
  void addDiet(String diet) {
    _diets.add(diet);
    notifyListeners();
  }

  void removeDiet(String diet) {
    _diets.remove(diet);
    notifyListeners();
  }

  // Ingredients Methods
  void addExtendedIngredient(ExtendedIngredient ingredient) {
    _extendedIngredients.add(ingredient);
    notifyListeners();
  }

  void removeExtendedIngredient(int index) {
    _extendedIngredients.removeAt(index);
    notifyListeners();
  }

  void setExtendedIngredients(List<ExtendedIngredient> ingredients) {
    _extendedIngredients = List.from(ingredients);
    notifyListeners();
  }

  // Instructions Methods
  void setAnalyzedInstructions(List<AnalyzedInstruction> instructions) {
    _analyzedInstructions = List.from(instructions);
    notifyListeners();
  }

  // Status Methods
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void setRecipe(Recipes? value) {
    _recipe = value;
    notifyListeners();
  }

  // Clear all data
  void clearState() {
    _title = '';
    _image = null;
    _servings = 0;
    _readyInMinutes = 0;
    _imageType = null;
    _dishTypes.clear();
    _diets.clear();
    _extendedIngredients.clear();
    _analyzedInstructions.clear();
    _isLoading = false;
    _error = null;
    _recipe = null;
    _ingredientSuggestions.clear();
    _loadingIngredientInfo.clear();
    notifyListeners();
  }

  Future<void> saveRecipe() async {
    _isLoading = true;
    notifyListeners();

    try {
      final totalNutrition = calculateTotalNutrition();
      final currentUser = _supabase.auth.currentUser;

      if (currentUser == null) throw Exception('User not authenticated');

      // Fetch the source_type from the accounts table
      final accountResponse = await _supabase
          .from('accounts')
          .select('type')
          .eq('uid', currentUser.id)
          .single();
      
      final sourceType = accountResponse['type'];
      String sourceName = '';  // Variable to hold the source name

      // Fetch the source_name based on the source_type
      if (sourceType == 'business') {
        final businessProfileResponse = await _supabase
            .from('business_profiles')
            .select('name')
            .eq('uid', currentUser.id)
            .single();

        sourceName = businessProfileResponse['name'];
      }else if (sourceType == 'nutritionist'){
        final nutriProfileResponse = await _supabase
            .from('nutritionist_profiles')
            .select('full_name')
            .eq('uid', currentUser.id)
            .single();

        sourceName = nutriProfileResponse['full_name'];
      }else if (sourceType == 'user') {
        final userProfileResponse = await _supabase
            .from('user_profiles')
            .select('name')
            .eq('uid', currentUser.id)
            .single();
        
        sourceName = userProfileResponse['name'];
      } else {
        throw Exception('Invalid source type');
      }
      // Insert the recipe into the 'recipes' table with the source_name
      final response = await _supabase.from('recipes').insert({
        'uid': currentUser.id,
        'title': _title,
        'image': _image,
        'image_type': _imageType,
        'servings': _servings,
        'ready_in_minutes': _readyInMinutes,
        'dish_types': _dishTypes,
        'diets': _diets,
        'extended_ingredients': _extendedIngredients.map((i) => i.toMap()).toList(),
        'analyzed_instructions': _analyzedInstructions.map((i) => i.toMap()).toList(),
        'nutrition': totalNutrition.toMap(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'source_name': sourceName,
        'source_type': sourceType,
      }).select().single();

      _recipe = Recipes.fromMap(response);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      final result = <Nutrient>[];
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
      for (final item in standard) {
        final amt = (totals[item[0]] ?? 0) / factor;
        result.add(Nutrient(
          title: item[0][0].toUpperCase() + item[0].substring(1),
          amount: amt,
          unit: item[1],
        ));
      }
      return Nutrition(nutrients: result);
    }

  Future<void> searchIngredients(String query, int index) async {
    if (query.isEmpty) return;

    try {
      if (!_allSuggestions.containsKey(index) || 
          _allSuggestions[index]!.isEmpty || 
          _allSuggestions[index]![0]['name'] != query) {
        _ingredientSearchOffset[index] = 0;
        _allSuggestions[index] = [];
      }

      final suggestions = await _spoonacularService.searchIngredients(
        query: query,
        number: 3,
      );

      final newSuggestions = suggestions.where((suggestion) => 
          !_allSuggestions[index]!.any((existing) => 
              existing['id'] == suggestion['id'])).toList();

      _allSuggestions[index]!.addAll(newSuggestions);
      _ingredientSuggestions[index] = _allSuggestions[index]!;
      notifyListeners();
      _ingredientSearchOffset[index] = (_ingredientSearchOffset[index] ?? 0) + 3;
    } catch (e) {
      _error = 'Failed to search ingredients: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> loadMoreIngredients(int index) async {
    try {
      final currentQuery = _extendedIngredients[index].name;
      if (currentQuery.isEmpty) return;

      final moreSuggestions = await _spoonacularService.searchIngredients(
        query: currentQuery,
        number: 3,
      );

      final newSuggestions = moreSuggestions.where((suggestion) => 
          !_allSuggestions[index]!.any((existing) => 
              existing['id'] == suggestion['id'])).toList();

      _allSuggestions[index]!.addAll(newSuggestions);
      _ingredientSuggestions[index] = _allSuggestions[index]!;
      notifyListeners();
      _ingredientSearchOffset[index] = (_ingredientSearchOffset[index] ?? 0) + 3;
    } catch (e) {
      _error = 'Failed to load more ingredients: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> selectIngredient(Map<String, dynamic> ingredient, int index) async {
    _loadingIngredientInfo[index] = true;
    notifyListeners();

    try {
      final extendedIngredient = await _spoonacularService.getIngredientInformation(ingredient['id']);

      final newIngredient = extendedIngredient.copyWith(
        amount: 0,
        unit: extendedIngredient.possibleUnits.isNotEmpty 
            ? extendedIngredient.possibleUnits.first 
            : 'g',
      );

      final newList = List<ExtendedIngredient>.from(_extendedIngredients);
      newList[index] = newIngredient;
      _extendedIngredients = newList;

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load ingredient: ${e.toString()}';
      notifyListeners();
    } finally {
      _loadingIngredientInfo[index] = false;
      notifyListeners();
    }
  }

  Future<void> updateIngredientAmountAndUnit(int index, double amount, String unit) async {
    final ingredient = _extendedIngredients[index];
    final newIngredient = ingredient.copyWith(amount: amount, unit: unit);

    final newList = List<ExtendedIngredient>.from(_extendedIngredients);
    newList[index] = newIngredient;
    _extendedIngredients = newList;
    notifyListeners();

    if (ingredient.nutrition != null) {
      await _updateIngredientNutrition(index, amount, unit);
    }
  }

  Future<void> _updateIngredientNutrition(int index, double amount, String unit) async {
    final ingredient = _extendedIngredients[index];
    try {
      final updatedIngredient = await _spoonacularService.getIngredientInformation(
        ingredient.id,
        amount: amount,
        unit: unit,
      );

      final newList = List<ExtendedIngredient>.from(_extendedIngredients);
      newList[index] = updatedIngredient;
      _extendedIngredients = newList;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update nutrition: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> uploadRecipeImage(XFile imageFile) async {
    try {
      _isLoading = true;
      notifyListeners();

      final bytes = await imageFile.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final mimeType = mime(imageFile.path) ?? 'image/jpeg';

      // Upload to Supabase storage
      final response = await _supabase.storage
          .from('recipe-images')
          .uploadBinary(fileName, bytes, fileOptions: FileOptions(contentType: mimeType));

      if (response.isEmpty) {
        throw Exception('Failed to upload image to Supabase');
      }

      // Get the public URL of the uploaded image
      final imageUrl = _supabase.storage.from('recipe-images').getPublicUrl(fileName);
      _image = imageUrl;
      _imageType = mimeType;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to upload image: ${e.toString()}';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRecipeImage(int recipeId, XFile imageFile) async {
    try {
      _isLoading = true;
      notifyListeners();

      final bytes = await imageFile.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final mimeType = mime(imageFile.path) ?? 'image/jpeg';

      // Upload the image to Supabase storage
      final response = await _supabase.storage
          .from('recipe-images')
          .uploadBinary(fileName, bytes, fileOptions: FileOptions(contentType: mimeType));

      if (response.isEmpty) {
        throw Exception('Failed to upload image to Supabase');
      }

      // Get the public URL of the uploaded image
      final imageUrl = _supabase.storage.from('recipe-images').getPublicUrl(fileName);

      // Update the recipe image in the database
      await _supabase
          .from('recipes')
          .update({'image': imageUrl, 'image_type': mimeType, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', recipeId);

      // Update local state
      _image = imageUrl;
      _imageType = mimeType;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update recipe image: ${e.toString()}';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
