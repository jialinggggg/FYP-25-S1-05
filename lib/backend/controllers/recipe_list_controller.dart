import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/recipes.dart';
import '../api/spoonacular_service.dart';
import '../api/nutridigm_service.dart';
import '../entities/nutrition.dart';
import '../entities/user_medical_info.dart';
import 'dart:math';

class RecipeListController with ChangeNotifier {
  final SupabaseClient _supabase;
  final SpoonacularService _spoonacularService;
  final NutridigmService _nutridigmService;
  final spoonacularOffset = Random().nextInt(100);

  List<Recipes> _recipes = [];
  List<int> _loadedLocalRecipeIds = [];
  List<int> _loadedSpoonacularRecipeIds = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  final Map<int, int> _favoriteCounts = {};
  final Map<int, double> _averageRatings = {};
  final Map<int, bool> _hasRatings = {};
  final Map<int, int> _ratingCounts = {};

  RecipeListController(this._supabase, this._spoonacularService, this._nutridigmService);

  List<Recipes> get recipes => _recipes;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  int getFavoriteCount(int recipeId) => _favoriteCounts[recipeId] ?? 0;
  int getRatingCount(int recipeId) => _ratingCounts[recipeId] ?? 0;
  double getAverageRating(int recipeId) => _averageRatings[recipeId] ?? 0.0;
  bool hasRatings(int recipeId) => _hasRatings[recipeId] ?? false;

  Future<void> loadInitialRecipes({
    int localLimit = 6,
    int spoonacularLimit = 4,
  }) async {
    _isLoading = true;
    _loadedLocalRecipeIds = [];
    _loadedSpoonacularRecipeIds = [];
    notifyListeners();

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      final userMap = await _supabase
          .from('user_medical_info')
          .select()
          .eq('uid', currentUser.id)
          .single();
      final userInfo = UserMedicalInfo.fromMap(userMap);

      final hiddenLocalIds = await _getHiddenRecipeIdsByType(['user', 'business', 'nutritionist']);
      final hiddenSpoonacularIds = await _getHiddenRecipeIdsByType(['spoonacular']);

      final localCandidates = await _getRandomRecipes(limit: localLimit * 3);
      final filteredLocal = localCandidates.where((r) {
        return !hiddenLocalIds.contains(r.id) &&
              _matchRecipeToAllergies(r, userInfo.allergies) &&
              _matchRecommendedNutrients(r, userInfo.preExisting);
      }).take(localLimit).toList();

      final ingredientQuery = await _getNutridigmQuery(userInfo.preExisting);

      final spoonacularRecipes = await _spoonacularService.fetchRecipesWithConditions(
        recommendedIngredients: ingredientQuery,
        allergies: userInfo.allergies,
        limit: spoonacularLimit * 3,
        offset: spoonacularOffset,
      );
      final filteredSpoonacular = spoonacularRecipes.where((r) {
        return !hiddenSpoonacularIds.contains(r.id) &&
              _matchRecommendedNutrients(r, userInfo.preExisting);
      }).take(spoonacularLimit).toList();

      _recipes = [...filteredLocal, ...filteredSpoonacular]..shuffle();
      await Future.wait(_recipes.map(_loadAdditionalRecipeData));

      _loadedLocalRecipeIds = filteredLocal.map((r) => r.id).toList();
      _loadedSpoonacularRecipeIds = filteredSpoonacular.map((r) => r.id).toList();
      _hasMore = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _recipes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreRecipes({
    int localLimit = 6,
    int spoonacularLimit = 4,
  }) async {
    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      final userMap = await _supabase
          .from('user_medical_info')
          .select()
          .eq('uid', currentUser.id)
          .single();
      final userInfo = UserMedicalInfo.fromMap(userMap);

      final hiddenLocalIds = await _getHiddenRecipeIdsByType(['user', 'business', 'nutritionist']);
      final hiddenSpoonacularIds = await _getHiddenRecipeIdsByType(['spoonacular']);

      // 🔍 Filter new local recipes
      final allLocalCandidates = await _getRandomRecipes(limit: localLimit * 3);
      final newLocal = allLocalCandidates.where((r) =>
        !_loadedLocalRecipeIds.contains(r.id) &&
        !hiddenLocalIds.contains(r.id) &&
        _matchRecipeToAllergies(r, userInfo.allergies) &&
        _matchRecommendedNutrients(r, userInfo.preExisting),
      ).take(localLimit).toList();

      // 🍽 Fetch and filter Spoonacular recipes using updated method
      final ingredientQuery = await _getNutridigmQuery(userInfo.preExisting);
      final offset = Random().nextInt(100);

      final newSpoonacularRaw = await _spoonacularService.fetchRecipesWithConditions(
        recommendedIngredients: ingredientQuery,
        allergies: userInfo.allergies,
        diets: _getSpoonacularDiets(userInfo.preExisting),
        limit: spoonacularLimit * 3,
        offset: offset,
      );

      final newSpoonacular = newSpoonacularRaw.where((r) =>
        !_loadedSpoonacularRecipeIds.contains(r.id) &&
        !hiddenSpoonacularIds.contains(r.id) &&
        _matchRecommendedNutrients(r, userInfo.preExisting),
      ).take(spoonacularLimit).toList();

      final newRecipes = [...newLocal, ...newSpoonacular];

      if (newRecipes.isEmpty) {
        _hasMore = false;
      } else {
        _recipes.addAll(newRecipes);
        _loadedLocalRecipeIds.addAll(newLocal.map((r) => r.id));
        _loadedSpoonacularRecipeIds.addAll(newSpoonacular.map((r) => r.id));
        await Future.wait(newRecipes.map(_loadAdditionalRecipeData));
        _hasMore = true;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<Set<int>> _getHiddenRecipeIdsByType(List<String> types) async {
    final response = await _supabase
        .from('recipes_hide')
        .select('recipe_id')
        .inFilter('source_type', types);

    return response.map((r) => r['recipe_id'] as int).toSet();
  }

  Future<void> _loadAdditionalRecipeData(Recipes recipe) async {
    try {
      final favoriteCount = await _getFavoriteCount(recipe.id);
      _favoriteCounts[recipe.id] = favoriteCount;

      final ratingCount = await _getRatingCount(recipe.id);
      _ratingCounts[recipe.id] = ratingCount;
      _hasRatings[recipe.id] = ratingCount > 0;

      if (ratingCount > 0) {
        final averageRating = await _getAverageRating(recipe.id);
        _averageRatings[recipe.id] = averageRating;
      }
    } catch (_) {}
  }

  Future<List<Recipes>> _getRandomRecipes({int limit = 5}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in.');
      }

      // 🔒 Fetch hidden local recipe IDs
      final hiddenResponse = await _supabase
          .from('recipes_hide')
          .select('recipe_id')
          .inFilter('source_type', ['user', 'nutritionist', 'business']);

      final hiddenIds = hiddenResponse.map((r) => r['recipe_id'] as int).toList();

      final response = await _supabase
          .from('recipes')
          .select()
          .neq('uid', currentUser.id)
          .not('id', 'in', hiddenIds)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map<Recipes>((map) => Recipes.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to fetch random recipes: $e');
    }
  }


  Future<int> _getFavoriteCount(int recipeId) async {
    final response = await _supabase
        .from('recipes_favourite')
        .select()
        .eq('recipe_id', recipeId);
    return response.length;
  }

  Future<int> _getRatingCount(int recipeId) async {
    final response = await _supabase
        .from('recipes_rating')
        .select()
        .eq('recipe_id', recipeId);
    return response.length;
  }

  Future<double> _getAverageRating(int recipeId) async {
    final response = await _supabase
        .from('recipes_rating')
        .select('rating')
        .eq('recipe_id', recipeId);
    if (response.isEmpty) return 0.0;
    final ratings = response.map<int>((item) => item['rating'] as int).toList();
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }


  bool _matchRecipeToAllergies(Recipes recipe, List<String> allergies) {
    final ingredients = recipe.extendedIngredients ?? [];
    for (final allergy in allergies) {
      if (ingredients.any((i) =>
          i.name.toLowerCase().contains(allergy.toLowerCase()))) {
        return false;
      }
    }
    return true;
  }

  double _getAmount(List<Nutrient> nutrients, String key) {
    return nutrients.firstWhere(
      (n) => n.title.toLowerCase() == key.toLowerCase(),
      orElse: () => Nutrient(title: key, amount: 0, unit: ''),
    ).amount;
  }

  List<String> _getSpoonacularDiets(List<String> conditions) {
    final diets = <String>{};

    if (conditions.contains('type 2 diabetes')) {
      diets.addAll(['low carb', 'low sugar']);
    }

    if (conditions.contains('high blood pressure')) {
      diets.add('low sodium');
    }

    return diets.toList();
  }

  Future<List<String>> _getNutridigmQuery(List<String> conditions) async {
    final Set<String> ingredients = {};
    for (final condition in conditions) {
      final id = _mapConditionToId(condition);
      if (id != null) {
        final result = await _nutridigmService.fetchTopDoDonts(id);
        for (final item in result) {
          if (item.containsKey("displayAs")) {
            final ingredient = item["displayAs"] as String;
            if (!ingredient.contains(' ') && ingredient.length > 2) {
              ingredients.add(ingredient);
            }
          }
        }
      }
    }
    return ingredients.take(5).toList();
  }

  int? _mapConditionToId(String condition) {
    switch (condition.toLowerCase()) {
      case 'type 2 diabetes':
        return 16;
      case 'high blood pressure':
        return 2;
      default:
        return null;
    }
  }

  bool _matchRecommendedNutrients(Recipes recipe, List<String> conditions) {
    final nutrients = recipe.nutrition?.nutrients ?? [];

    if (conditions.contains('type 2 diabetes')) {
      final sugar = _getAmount(nutrients, 'Sugar');
      final carbs = _getAmount(nutrients, 'Carbohydrates');
      if (sugar >= 5 || carbs >= 30) return false;
    }

    if (conditions.contains('high blood pressure')) {
      final sodium = _getAmount(nutrients, 'Sodium');
      if (sodium >= 140) return false;
    }

    return true;
  }
}
