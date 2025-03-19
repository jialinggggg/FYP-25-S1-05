import 'package:supabase_flutter/supabase_flutter.dart';

class MealEntriesService {
  final SupabaseClient _supabase;

  MealEntriesService(this._supabase);

  // Method to insert a new meal entry
  Future<void> insertMealEntry({
    required int spoonacularId,
    required String uid,
    required String name,
    required int calories,
    required double carbs,
    required double protein,
    required double fats,
    required String type,
  }) async {
    try {
      await _supabase.from('meal_entries').insert({
        'spoonacular_id': spoonacularId,
        'uid': uid,
        'name': name,
        'calories': calories,
        'carbs': carbs,
        'protein': protein,
        'fats': fats,
        'type': type,
      });
    } catch (e) {
      throw Exception('Error inserting meal entry: $e');
    }
  }

  // Method to fetch all meal entries for a user
  Future<List<Map<String, dynamic>>> fetchMealEntries(String uid) async {
    try {
      final response = await _supabase
          .from('meal_entries')
          .select()
          .eq('uid', uid)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      throw Exception('Error fetching meal entries: $e');
    }
  }

  // Method to update a meal entry
  Future<void> updateMealEntry({
    required int mealId,
    required String name,
    required int calories,
    required double carbs,
    required double protein,
    required double fats,
    required String type,
  }) async {
    try {
      await _supabase.from('meal_entries').update({
        'name': name,
        'calories': calories,
        'carbs': carbs,
        'protein': protein,
        'fats': fats,
        'type': type,
      }).eq('meal_id', mealId);
    } catch (e) {
      throw Exception('Error updating meal entry: $e');
    }
  }

  // Method to delete a meal entry
  Future<void> deleteMealEntry(String mealId) async {
    try {
      await _supabase.from('meal_entries').delete().eq('meal_id', mealId);
    } catch (e) {
      throw Exception('Error deleting meal entry: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchLatestDate(String userId) async {
  try {
    final response = await _supabase
        .from('meal_entries')
        .select('created_at')
        .eq('uid', userId)
        .order('created_at', ascending: false)
        .limit(1);

    if (response.isNotEmpty) {
      // Parse the 'created_at' string into a DateTime object in UTC
      final createdAtString = response[0]['created_at'] as String;
      final createdAtUtc = DateTime.parse(createdAtString).toUtc();

      // Convert the UTC DateTime to local time zone (SGT)
      final createdAtLocal = createdAtUtc.toLocal();

      // Update the response with the local DateTime
      response[0]['created_at'] = createdAtLocal;
    }

    return response;
  } catch (e) {
    throw Exception('Error fetching latest date: $e');
  }
}

  // Method to calculate total calories, carbs, protein, and fats for the day
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

      final List<Map<String, dynamic>> meals = response;

      int totalCalories = 0;
      double totalCarbs = 0.0;
      double totalProtein = 0.0;
      double totalFats = 0.0;

      for (var meal in meals) {
        totalCalories += meal['calories'] as int;
        totalCarbs += meal['carbs'] as double;
        totalProtein += meal['protein'] as double;
        totalFats += meal['fats'] as double;
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

  // Method to calculate the breakdown of total calories by meal type
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

      final List<Map<String, dynamic>> meals = response;

      Map<String, int> caloriesByMealType = {
        'Breakfast': 0,
        'Lunch': 0,
        'Dinner': 0,
        'Snacks': 0,
      };

      for (var meal in meals) {
        final mealType = meal['type'] as String;
        final calories = meal['calories'] as int;

        if (caloriesByMealType.containsKey(mealType)) {
          caloriesByMealType[mealType] = (caloriesByMealType[mealType] ?? 0) + calories;
        }
      }

      return caloriesByMealType;
    } catch (e) {
      throw Exception('Error calculating calories by meal type: $e');
    }
  }
}
