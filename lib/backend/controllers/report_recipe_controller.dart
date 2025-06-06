import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/recipes.dart';
import '../entities/recipe_report.dart';

class ReportRecipeController with ChangeNotifier {
  final SupabaseClient _supabase;

  bool _isLoading = false;
  String? _error;
  String _selectedReportType = '';
  String _comment = '';
  bool _hasReported = false;

  bool get isLoading => _isLoading;
  bool get hasReported => _hasReported;
  String? get error => _error;
  String get selectedReportType => _selectedReportType;
  String get comment => _comment;

  ReportRecipeController(this._supabase);

  void setReportType(String type) {
    _selectedReportType = type;
    notifyListeners();
  }

  void setComment(String comment) {
    _comment = comment;
  }

  Future<bool> submitReport(Recipes recipe) async {
    if (_selectedReportType.isEmpty) {
      _error = 'Please select a report type';
      notifyListeners();
      return false;
    }

    if (_comment.isEmpty) {
      _error = 'Please enter a comment';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final report = RecipeReport(
        reportId: '', // Will be generated by Supabase
        uid: currentUser.id,
        recipeId: recipe.id,
        type: _selectedReportType,
        comment: _comment,
        status: 'pending',
        sourceType: recipe.sourceType,
        createdAt: DateTime.now(),
      );

      // Report the recipe directly to Supabase
      await _reportRecipe(report);
      
      _isLoading = false;
      _hasReported = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Method to directly insert a report into the Supabase table
  Future<void> _reportRecipe(RecipeReport report) async {
    try {
      await _supabase.from('recipes_report').insert({
        'uid': report.uid,
        'recipe_id': report.recipeId,
        'report_type': report.type,
        'comment': report.comment,
        'source_type': report.sourceType,
        'created_at': report.createdAt.toUtc().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error reporting recipe: $e');
    }
  }

  Future<void> checkIfAlreadyReported(int recipeId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    final response = await _supabase
        .from('recipes_report')
        .select('report_id')
        .eq('uid', currentUser.id)
        .eq('recipe_id', recipeId)
        .maybeSingle();

    if (response != null) {
      _hasReported = true;
    } else {
      _hasReported = false;
    }
    
    notifyListeners();
  }
}
