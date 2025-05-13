import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/recipes.dart';
import '../entities/recipe_rating.dart';

class ViewRecipeDetailController with ChangeNotifier {
  final SupabaseClient _supabase;
  final Recipes _recipe;
  
  bool _isFavourite = false;
  bool _isLoading = false;
  bool _isOwner = false;
  bool _isExternalRecipe = false;
  bool _hasRated = false;
  List<RecipeRating> _reviews = [];
  int _favoriteCount = 0;
  int _ratingCount = 0;
  double _averageRating = 0.0;
  String? _error;
  bool _isHidden = false;
  List<String> _userAllergies = [];
  String? _matchedAllergen; // this will hold the first matched allergen
  bool _hasAllergyConflict = false;

  bool get hasAllergyConflict => _hasAllergyConflict;
  String? get matchedAllergen => _matchedAllergen;
  bool get isHidden => _isHidden;
  Recipes get recipe => _recipe;
  bool get isLoading => _isLoading;
  bool get isFavourite => _isFavourite;
  bool get isOwner => _isOwner;
  bool get isExternalRecipe => _isExternalRecipe;
  bool get hasRated => _hasRated;
  List<RecipeRating> get reviews => _reviews;
  int get favoriteCount => _favoriteCount;
  int get ratingCount => _ratingCount;
  double get averageRating => _averageRating;
  String? get error => _error;

  ViewRecipeDetailController(
    this._supabase,
    this._recipe,
  ) {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      // 1. Load user allergies
      final userMap = await _supabase
          .from('user_medical_info')
          .select()
          .eq('uid', currentUser.id)
          .maybeSingle();

      if (userMap != null) {
        _userAllergies = List<String>.from(userMap['allergies'] ?? []);
      }

      // 2. Check for allergens in the recipe
      _checkRecipeForAllergies();

      // 3. Continue loading
      _isExternalRecipe = _recipe.sourceType?.toLowerCase() == 'spoonacular';

      await Future.wait([
        _checkFavoriteStatus(),
        _loadReviewsAndRatings(),
        _loadFavoriteCount(),
        _loadRatingStats(),
      ]);

      if (!_isExternalRecipe && currentUser != null) {
        _isOwner = await _isOwnerCheck();
        await _checkIfRecipeIsHidden();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }


  Future<bool> isCurrentUser(RecipeRating review) async {
    final currentUser = _supabase.auth.currentUser;
    return review.uid == currentUser?.id;
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        final response = await _supabase
            .from('recipes_favourite')
            .select()
            .eq('recipe_id', _recipe.id)
            .eq('uid', currentUser.id)
            .single()
            .maybeSingle(); // Use maybeSingle() to avoid error if no row is returned

        _isFavourite = response != null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to check favorite status: ${e.toString()}';
      notifyListeners();
    }
  }


  Future<void> _loadFavoriteCount() async {
    try {
      final response = await _supabase
          .from('recipes_favourite')
          .select()
          .eq('recipe_id', _recipe.id);

      _favoriteCount = response.length;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load favorite count: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> _loadRatingStats() async {
    try {
      final response = await _supabase
          .from('recipes_rating')
          .select('rating')
          .eq('recipe_id', _recipe.id);

      _ratingCount = response.length;
      _averageRating = response.isEmpty
          ? 0.0
          : response.map<int>((item) => item['rating'] as int).reduce((sum, rating) => sum + rating) /
              _ratingCount;

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load rating stats: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> _loadReviewsAndRatings() async {
    try {
      final response = await _supabase
          .from('recipes_rating')
          .select()
          .eq('recipe_id', _recipe.id)
          .order('created_at', ascending: false);

      _reviews = response.map<RecipeRating>((map) => RecipeRating.fromMap(map)).toList();

      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        _hasRated = _reviews.any((review) => review.uid == currentUser.id); // Check if the current user has rated
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load reviews: ${e.toString()}';
      notifyListeners();
    }
  }


  Future<bool> _isOwnerCheck() async {
    try {
      final response = await _supabase
          .from('recipes')
          .select('uid')
          .eq('id', _recipe.id)
          .single();

      final currentUser = _supabase.auth.currentUser;
      return response['uid'] == currentUser?.id;
    } catch (e) {
      _error = 'Failed to check ownership: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleFavourite() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      if (_isFavourite) {
        await _supabase.from('recipes_favourite').delete().eq('recipe_id', _recipe.id).eq('uid', currentUser.id);
      } else {
        await _supabase.from('recipes_favourite').insert({
          'recipe_id': _recipe.id,
          'uid': currentUser.id,
          'source_type': _recipe.sourceType ?? 'user',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
      _isFavourite = !_isFavourite;
      await _loadFavoriteCount();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update favorite status: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> submitReview({
    required int rating,
    required String comment,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      // Insert the new review into the 'recipes_rating' table
      await _supabase.from('recipes_rating').insert({
        'uid': currentUser.id,
        'recipe_id': _recipe.id,
        'rating': rating,
        'comment': comment,
        'source_type': _recipe.sourceType, // Insert the source_type
      });

      // Load reviews and rating stats after inserting the review
      await _loadReviewsAndRatings();
      await _loadRatingStats();

      // Notify listeners that the review submission is complete
      notifyListeners();
    } catch (e) {
      _error = 'Failed to submit review: ${e.toString()}';
      notifyListeners();
    }
  }


  Future<void> updateReview({
    required String ratingId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _supabase
          .from('recipes_rating')
          .update({
            'rating': rating,
            'comment': comment,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('rating_id', ratingId);

      await _loadReviewsAndRatings();
      await _loadRatingStats();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update review: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> deleteReview(String ratingId) async {
    try {
      await _supabase.from('recipes_rating').delete().eq('rating_id', ratingId);
      await _loadReviewsAndRatings();
      await _loadRatingStats();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete review: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> _checkIfRecipeIsHidden() async {
    try {
      final response = await _supabase
          .from('recipes_hide')
          .select('recipe_id')
          .eq('recipe_id', _recipe.id)
          .eq('source_type', _recipe.sourceType!)
          .maybeSingle();

      _isHidden = response != null;
    } catch (e) {
      _isHidden = false;
    }
  }

  void _checkRecipeForAllergies() {
    final ingredients = _recipe.extendedIngredients ?? [];
    for (final allergy in _userAllergies) {
      final found = ingredients.any(
        (i) => i.name.toLowerCase().contains(allergy.toLowerCase()),
      );
      if (found) {
        _hasAllergyConflict = true;
        _matchedAllergen = allergy;
        break;
      }
    }
  }

}
