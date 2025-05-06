import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/recipes.dart';
import '../api/spoonacular_service.dart';

class RecipeListController with ChangeNotifier {
  final SupabaseClient _supabase;
  final SpoonacularService _spoonacularService;
  
  List<Recipes> _recipes = [];
  List<int> _loadedLocalRecipeIds = [];
  List<int> _loadedSpoonacularRecipeIds = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  // Store additional recipe data
  final Map<int, int> _favoriteCounts = {};
  final Map<int, double> _averageRatings = {};
  final Map<int, bool> _hasRatings = {};
  final Map<int, int> _ratingCounts = {};

  RecipeListController(this._supabase, this._spoonacularService,);

  List<Recipes> get recipes => _recipes;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  int getFavoriteCount(int recipeId) => _favoriteCounts[recipeId] ?? 0;
  int getRatingCount(int recipeId) => _ratingCounts[recipeId] ?? 0;
  double getAverageRating(int recipeId) => _averageRatings[recipeId] ?? 0.0;
  bool hasRatings(int recipeId) => _hasRatings[recipeId] ?? false;

  Future<void> _loadAdditionalRecipeData(Recipes recipe) async {
    try {
      // Load favorite count for all recipes (both EatWell and Spoonacular)
      final favoriteCount = await _getFavoriteCount(recipe.id);
      _favoriteCounts[recipe.id] = favoriteCount;

      final ratingCount = await _getRatingCount(recipe.id);
      _ratingCounts[recipe.id] = ratingCount;  // Store the rating count
      _hasRatings[recipe.id] = ratingCount > 0;
        
      if (ratingCount > 0) {
        final averageRating = await _getAverageRating(recipe.id);
        _averageRatings[recipe.id] = averageRating;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading additional data for recipe ${recipe.id}: $e');
      }
    }
  }

  Future<void> loadInitialRecipes({
    int localLimit = 6,
    int spoonacularLimit = 4,
  }) async {
    _isLoading = true;
    _loadedLocalRecipeIds = [];
    _loadedSpoonacularRecipeIds = [];
    notifyListeners();

    try {
      final localRecipes = await _getRandomRecipes(limit: localLimit);
      final spoonacularRecipes = await _spoonacularService.fetchRecipes(limit: spoonacularLimit);
      
      // Track loaded recipe IDs to prevent duplicates
      _loadedLocalRecipeIds = localRecipes.map((r) => r.id).toList();
      _loadedSpoonacularRecipeIds = spoonacularRecipes.map((r) => r.id).toList();
      
      // Combine and shuffle the recipes for variety
      _recipes = [...localRecipes, ...spoonacularRecipes]..shuffle();
      
      // Load additional data for each recipe
      await Future.wait(_recipes.map(_loadAdditionalRecipeData));
      
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
      // Get new local recipes excluding already loaded ones
      final allLocalRecipes = await _getRandomRecipes(limit: 100);
      final newLocalRecipes = allLocalRecipes
          .where((r) => !_loadedLocalRecipeIds.contains(r.id))
          .take(localLimit)
          .toList();

      // Get new Spoonacular recipes excluding already loaded ones
      final allSpoonacularRecipes = await _spoonacularService.fetchRecipes(limit: 100);
      final newSpoonacularRecipes = allSpoonacularRecipes
          .where((r) => !_loadedSpoonacularRecipeIds.contains(r.id))
          .take(spoonacularLimit)
          .toList();

      // Update loaded recipe IDs
      _loadedLocalRecipeIds.addAll(newLocalRecipes.map((r) => r.id));
      _loadedSpoonacularRecipeIds.addAll(newSpoonacularRecipes.map((r) => r.id));

      // Add new recipes to the list
      final newRecipes = [...newLocalRecipes, ...newSpoonacularRecipes]..shuffle();
      _recipes.addAll(newRecipes);
      
      // Load additional data for new recipes
      await Future.wait(newRecipes.map(_loadAdditionalRecipeData));
      
      // Check if we have more recipes to load
      _hasMore = newLocalRecipes.isNotEmpty || newSpoonacularRecipes.isNotEmpty;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Replaced repository methods with direct methods to interact with Supabase.

  Future<List<Recipes>> _getRandomRecipes({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('recipes')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return response.map<Recipes>((map) => Recipes.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to fetch random recipes: $e');
    }
  }

  Future<int> _getFavoriteCount(int recipeId) async {
    try {
      final response = await _supabase
          .from('recipes_favourite')
          .select()
          .eq('recipe_id', recipeId);
      return response.length;
    } catch (e) {
      throw Exception('Error getting favorite count: $e');
    }
  }

  Future<int> _getRatingCount(int recipeId) async {
    try {
      final response = await _supabase
          .from('recipes_rating')
          .select()
          .eq('recipe_id', recipeId);
      return response.length;
    } catch (e) {
      throw Exception('Error getting rating count: $e');
    }
  }

  Future<double> _getAverageRating(int recipeId) async {
    try {
      final response = await _supabase
          .from('recipes_rating')
          .select('rating')
          .eq('recipe_id', recipeId);
      
      if (response.isEmpty) return 0.0;
      
      final ratings = response.map<int>((item) => item['rating'] as int).toList();
      final total = ratings.reduce((sum, rating) => sum + rating);
      return total / ratings.length;
    } catch (e) {
      throw Exception('Error getting average rating: $e');
    }
  }
}
