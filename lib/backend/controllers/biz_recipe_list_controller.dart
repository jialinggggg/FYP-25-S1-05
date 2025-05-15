import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/recipes.dart';

class BusinessRecipeListController with ChangeNotifier {
  final SupabaseClient _supabase;
  List<Recipes> _recipes = [];
  bool _isLoading = false;
  String? _error;

  BusinessRecipeListController(this._supabase);

  List<Recipes> get recipes => _recipes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches all recipes where `created_by` matches current user
  Future<void> loadUserRecipes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = _supabase.auth.currentUser;
      final userId = user?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      final response = await _supabase
          .from('recipes')
          .select()
          .eq('uid', userId)
          .order('created_at', ascending: false);

      _recipes = (response as List)
          .map((map) => Recipes.fromMap(map as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _recipes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}