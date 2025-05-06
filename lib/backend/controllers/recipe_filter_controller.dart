import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/recipes.dart';
import '../entities/recipe_favourite.dart';
import '../entities/recipe_rating.dart';
import '../api/spoonacular_service.dart';

enum RecipeFilterType {
  custom,
  favourite,
  rated,
}

class RecipeFilterController with ChangeNotifier {
  final SupabaseClient _supabase;
  final SpoonacularService _spoonacularService;

  RecipeFilterType? _activeFilter;
  String? _filterLabel;
  bool _isFilterApplied = false;
  bool _isLoading = false; // New loading state
  List<Recipes> _filteredRecipes = [];
  String? _error;

  RecipeFilterController(this._supabase, this._spoonacularService);

  RecipeFilterType? get activeFilter => _activeFilter;
  String? get filterLabel => _filterLabel;
  bool get isFilterApplied => _isFilterApplied;
  bool get isLoading => _isLoading; // Getter for isLoading
  List<Recipes> get filteredRecipes => _filteredRecipes;
  String? get error => _error;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Notify listeners that the state has changed
  }

  void setFilter(RecipeFilterType filter, String label) {
    _activeFilter = filter;
    _filterLabel = label;
    _isFilterApplied = false;
    _error = null;
    notifyListeners();
  }

  Future<void> applyFilter(RecipeFilterType filterType) async {
    _isLoading = true;  // Set loading to true when starting to apply filter
    _isFilterApplied = true;
    _error = null;
    notifyListeners();

    try {
      _filteredRecipes = await _fetchFilteredRecipes(filterType);
    } catch (e) {
      _error = e.toString();
      _filteredRecipes = [];
    } finally {
      _isLoading = false;  // Set loading to false when filtering is done
    }
  }

  Future<List<Recipes>> _fetchFilteredRecipes(RecipeFilterType filterType) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    switch (filterType) {
      case RecipeFilterType.custom:
        return await _getUserRecipes(currentUser.id);
      case RecipeFilterType.favourite:
        final favourites = await _getFavourites(currentUser.id);
        final recipes = <Recipes>[];
        for (final fav in favourites) {
          try {
            final recipe = await _getRecipe(fav.recipeId, fav.sourceType);
            recipes.add(recipe);
          } catch (e) {
            continue;
          }
        }
        return recipes;
      case RecipeFilterType.rated:
        final ratings = await _getRatingsByUser(currentUser.id);
        final recipes = <Recipes>[];
        for (final rating in ratings) {
          try {
            final recipe = await _getRecipe(rating.recipeId, rating.sourceType);
            recipes.add(recipe);
          } catch (e) {
            continue;
          }
        }
        return recipes;
    }
  }

  Future<List<Recipes>> _getUserRecipes(String uid) async {
    try {
      final response = await _supabase
          .from('recipes')
          .select()
          .eq('uid', uid)
          .order('created_at', ascending: false);
      return response.map<Recipes>((map) => Recipes.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user recipes: $e');
    }
  }

  Future<List<RecipeFavourite>> _getFavourites(String uid) async {
    try {
      final response = await _supabase
          .from('recipes_favourite')
          .select()
          .eq('uid', uid)
          .order('created_at', ascending: false);
      return response.map<RecipeFavourite>((map) => RecipeFavourite.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error retrieving favourites: ${e.toString()}');
    }
  }

  Future<List<RecipeRating>> _getRatingsByUser(String uid) async {
    try {
      final response = await _supabase
          .from('recipes_rating')
          .select()
          .eq('uid', uid);
      return response.map<RecipeRating>((map) => RecipeRating.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error retrieving user ratings: ${e.toString()}');
    }
  }

  Future<Recipes> _getRecipe(int id, String sourceType) async {
    try {
      if (sourceType == 'spoonacular') {
        return await _spoonacularService.fetchRecipeById(id);
      } else {
        final response = await _supabase
            .from('recipes')
            .select()
            .eq('id', id)
            .single();
        return Recipes.fromMap(response);
      }
    } catch (e) {
      throw Exception('Failed to fetch recipe: ${e.toString()}');
    }
  }

  void clearFilter() {
    _activeFilter = null;
    _filterLabel = null;
    _isFilterApplied = false;
    _filteredRecipes = [];
    _error = null;
    notifyListeners();
  }

  bool get isFilterActive => _activeFilter != null;
}
