// lib/backend/controllers/fetch_nutrition_data_controller.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/meal_log.dart';

/// Holds one day’s nutrient totals
class DailyNutrition {
  final DateTime date;
  final Map<String, double> totals;
  DailyNutrition({ required this.date, required this.totals });
}

class FetchNutritionDataController extends ChangeNotifier {
  final SupabaseClient supabaseClient;

  // single‐day (latest) totals
  DateTime? _createdAt;
  Map<String, double> _dailyTotals = {};

  // multi‐day range totals
  List<DailyNutrition> _dailyData = [];

  String? _error;

  FetchNutritionDataController({ required this.supabaseClient });

  // getters
  DateTime?            get createdAt   => _createdAt;
  Map<String,double>   get dailyTotals => _dailyTotals;
  List<DailyNutrition> get dailyData   => _dailyData;
  String?              get error       => _error;
  bool                 get hasData     =>
      _dailyData.isNotEmpty || _dailyTotals.isNotEmpty;

  /// Unchanged: fetches the single latest meal‐log entry and then calls
  /// calculateDailyTotals for that day.
  Future<void> fetchLatestNutritionData(String uid) async {
    try {
      final response = await supabaseClient
          .from('meal_log')
          .select()
          .eq('uid', uid)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        _error = 'No meal entries found for the user';
        notifyListeners();
        return;
      }

      final latestMeal = MealLog.fromMap(response[0]);
      _createdAt = latestMeal.createdAt;

      await calculateDailyTotals(uid, latestMeal.createdAt);
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch the latest nutrition data: $e';
      notifyListeners();
    }
  }

  /// Unchanged: aggregates all meals on a single [date] into _dailyTotals.
  Future<void> calculateDailyTotals(String uid, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay   = startOfDay.add(const Duration(days: 1));

      final response = await supabaseClient
          .from('meal_log')
          .select()
          .eq('uid', uid)
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String());

      if (response.isEmpty) {
        _error = 'No meals found for the specified date';
        notifyListeners();
        return;
      }

      final meals = response.map<MealLog>((m) => MealLog.fromMap(m)).toList();

      final totals = <String, double>{
        'calories': 0,
        'protein': 0,
        'carbohydrates': 0,
        'fat': 0,
        'saturated fat': 0,
        'cholesterol': 0,
        'sodium': 0,
        'potassium': 0,
        'calcium': 0,
        'iron': 0,
        'vitamin a': 0,
        'vitamin c': 0,
        'vitamin d': 0,
        'fiber': 0,
        'sugar': 0,
      };

      for (var meal in meals) {
        for (var n in meal.nutrition.nutrients) {
          final key = n.title.toLowerCase();
          if (totals.containsKey(key)) {
            totals[key] = totals[key]! + n.amount;
          }
        }
      }

      totals['calories'] = totals['calories']!.roundToDouble();
      _dailyTotals = totals;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to calculate daily totals: $e';
      notifyListeners();
    }
  }

  /// NEW: fetch all meals between [startDate…endDate], group by day,
  /// and build a ListDailyNutrition in [_dailyData].
  Future<void> fetchNutritionDataByDateRange(
      String uid, DateTime startDate, DateTime endDate) async {
    try {
      final adjustedEnd = DateTime(
        endDate.year, endDate.month, endDate.day, 23, 59, 59,
      );

      final response = await supabaseClient
          .from('meal_log')
          .select()
          .eq('uid', uid)
          .gte('created_at', startDate.toUtc().toIso8601String())
          .lte('created_at', adjustedEnd.toUtc().toIso8601String())
          .order('created_at', ascending: true);

      final meals = (response as List)
          .map((m) => MealLog.fromMap(m as Map<String, dynamic>))
          .toList();

      if (meals.isEmpty) {
        _dailyData = [];
        _error = 'No meals found in this date range';
        notifyListeners();
        return;
      }

      // Group by calendar-day
      final Map<DateTime, List<MealLog>> groups = {};
      for (var meal in meals) {
        final day = DateTime(meal.createdAt.year,
                             meal.createdAt.month,
                             meal.createdAt.day);
        groups.putIfAbsent(day, () => []).add(meal);
      }

      // Sum each day’s nutrients
      final List<DailyNutrition> list = [];
      for (var entry in groups.entries) {
        final Map<String, double> dayTotals = {
          'calories': 0,
          'protein': 0,
          'carbohydrates': 0,
          'fat': 0,
          'saturated fat': 0,
          'cholesterol': 0,
          'sodium': 0,
          'potassium': 0,
          'calcium': 0,
          'iron': 0,
          'vitamin a': 0,
          'vitamin c': 0,
          'vitamin d': 0,
          'fiber': 0,
          'sugar': 0,
        };
        for (var meal in entry.value) {
          for (var n in meal.nutrition.nutrients) {
            final key = n.title.toLowerCase();
            if (dayTotals.containsKey(key)) {
              dayTotals[key] = dayTotals[key]! + n.amount;
            }
          }
        }
        dayTotals['calories'] = dayTotals['calories']!.roundToDouble();
        list.add(DailyNutrition(date: entry.key, totals: dayTotals));
      }

      // Sort ascending by date
      list.sort((a, b) => a.date.compareTo(b.date));
      _dailyData = list;
      _error = null;
    } catch (e) {
      _dailyData = [];
      _error = 'Error fetching nutrition data: $e';
    }

    notifyListeners();
  }
}
