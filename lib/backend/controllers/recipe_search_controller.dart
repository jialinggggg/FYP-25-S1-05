import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/recipes.dart';
import '../api/spoonacular_service.dart';

class RecipeSearchController with ChangeNotifier {
  final SupabaseClient _supabase;
  final SpoonacularService _spoonacularService;

  String _searchQuery = '';
  List<Recipes> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  RecipeSearchController(
    this._supabase,
    this._spoonacularService,
  );

  String get searchQuery => _searchQuery;
  List<Recipes> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get error => _error;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> searchRecipes(String query) async {
    if (query.isEmpty) return;

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final localResults = await _searchRecipesByName(query);
      final spoonacularResults = await _spoonacularService.fetchRecipes(query: query);
      _searchResults = [...localResults, ...spoonacularResults];
      _error = null;
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _isSearching = false;
    _error = null;
    notifyListeners();
  }

  // New method: Search for recipes directly in Supabase
  Future<List<Recipes>> _searchRecipesByName(String queryText, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('recipes')
          .select()
          .ilike('title', '%$queryText%')
          .limit(limit);

      return response.map<Recipes>((map) => Recipes.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to search recipes: $e');
    }
  }
}
