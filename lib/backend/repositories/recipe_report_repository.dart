import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/recipe_report.dart';

class RecipeReportRepository {
  final SupabaseClient _supabase;

  RecipeReportRepository(this._supabase);

  Future<void> reportRecipe(RecipeReport report) async {
    try {
      await _supabase.from('recipes_report').insert(report.toMap());
    } catch (e) {
      throw Exception('Error reporting recipe: $e');
    }
  }
}