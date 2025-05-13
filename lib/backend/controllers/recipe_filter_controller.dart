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
  byNutritionist,
  byBusiness,
  byUser,
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

    final hiddenIds = await _getHiddenRecipeIdsByType([
      'user', 'nutritionist', 'business', 'spoonacular'
    ]);

    List<Recipes> all = [];

    switch (filterType) {
      case RecipeFilterType.custom:
        final own = await _getUserRecipes(currentUser.id);
        all = own.where((r) => !hiddenIds.contains(r.id)).toList();
        break;

      case RecipeFilterType.favourite:
        final favs = await _getFavourites(currentUser.id);
        for (final fav in favs) {
          if (!hiddenIds.contains(fav.recipeId)) {
            try {
              final r = await _getRecipe(fav.recipeId, fav.sourceType);
              all.add(r);
            } catch (_) {}
          }
        }
        break;

      case RecipeFilterType.rated:
        final ratings = await _getRatingsByUser(currentUser.id);
        for (final rating in ratings) {
          if (!hiddenIds.contains(rating.recipeId)) {
            try {
              final r = await _getRecipe(rating.recipeId, rating.sourceType);
              all.add(r);
            } catch (_) {}
          }
        }
        break;

      case RecipeFilterType.byNutritionist:
      case RecipeFilterType.byBusiness:
      case RecipeFilterType.byUser:
        final type = {
          RecipeFilterType.byNutritionist: 'nutritionist',
          RecipeFilterType.byBusiness: 'business',
          RecipeFilterType.byUser: 'user',
        }[filterType]!; // Add ! to assert it's never null

        final response = await _supabase
            .from('recipes')
            .select()
            .eq('source_type', type)
            .order('created_at', ascending: false);

        all = response
            .map<Recipes>((map) => Recipes.fromMap(map))
            .where((r) => !hiddenIds.contains(r.id))
            .toList();
        break;
    }

    return all;
  }

  Future<Set<int>> _getHiddenRecipeIdsByType(List<String> types) async {
    final response = await _supabase
        .from('recipes_hide')
        .select('recipe_id')
        .inFilter('source_type', ['nutritionist', 'business']);

    return response.map((r) => r['recipe_id'] as int).toSet();
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
