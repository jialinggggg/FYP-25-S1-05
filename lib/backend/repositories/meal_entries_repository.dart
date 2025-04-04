import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/meal_entry.dart';

class MealEntriesRepository {
  final SupabaseClient _supabase;

  MealEntriesRepository(this._supabase);

  Future<void> insertMealEntry(MealEntry entry) async {
    try {
      await _supabase.from('meal_entries').insert(entry.toMap());
    } catch (e) {
      throw Exception('Error inserting meal entry: $e');
    }
  }

  Future<List<MealEntry>> fetchMealEntries(String uid) async {
    try {
      final response = await _supabase
          .from('meal_entries')
          .select()
          .eq('uid', uid)
          .order('created_at', ascending: false);
      return response.map<MealEntry>((map) => MealEntry.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error fetching meal entries: $e');
    }
  }

  Future<void> updateMealEntry(MealEntry entry) async {
    try {
      await _supabase.from('meal_entries')
          .update(entry.toMap())
          .eq('meal_id', entry.mealId!);
    } catch (e) {
      throw Exception('Error updating meal entry: $e');
    }
  }

  Future<void> deleteMealEntry(String mealId) async {
    try {
      await _supabase.from('meal_entries').delete().eq('meal_id', mealId);
    } catch (e) {
      throw Exception('Error deleting meal entry: $e');
    }
  }

  Future<DateTime?> fetchLatestDate(String userId) async {
    try {
      final response = await _supabase
          .from('meal_entries')
          .select('created_at')
          .eq('uid', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return DateTime.parse(response[0]['created_at'] as String).toLocal();
    } catch (e) {
      throw Exception('Error fetching latest date: $e');
    }
  }

  Future<Map<String, dynamic>> calculateDailyTotals(String uid, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('meal_entries')
          .select()
          .eq('uid', uid)
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String());

      final meals = response.map<MealEntry>((map) => MealEntry.fromMap(map)).toList();

      int totalCalories = 0;
      double totalCarbs = 0.0;
      double totalProtein = 0.0;
      double totalFats = 0.0;

      for (var meal in meals) {
        totalCalories += meal.calories;
        totalCarbs += meal.carbs;
        totalProtein += meal.protein;
        totalFats += meal.fats;
      }

      return {
        'totalCalories': totalCalories,
        'totalCarbs': totalCarbs,
        'totalProtein': totalProtein,
        'totalFats': totalFats,
      };
    } catch (e) {
      throw Exception('Error calculating daily totals: $e');
    }
  }

  Future<Map<String, int>> calculateCaloriesByMealType(String uid, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('meal_entries')
          .select()
          .eq('uid', uid)
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String());

      final meals = response.map<MealEntry>((map) => MealEntry.fromMap(map)).toList();

      Map<String, int> caloriesByMealType = {
        'Breakfast': 0,
        'Lunch': 0,
        'Dinner': 0,
        'Snacks': 0,
      };

      for (var meal in meals) {
        if (caloriesByMealType.containsKey(meal.type)) {
          caloriesByMealType[meal.type] = 
              (caloriesByMealType[meal.type] ?? 0) + meal.calories;
        }
      }

      return caloriesByMealType;
    } catch (e) {
      throw Exception('Error calculating calories by meal type: $e');
    }
  }
}