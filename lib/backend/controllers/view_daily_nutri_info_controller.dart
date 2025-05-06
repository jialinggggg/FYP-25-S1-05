import 'package:flutter/material.dart'; // ← Add this for ChangeNotifier
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/meal_log.dart';
import '../entities/user_goal.dart';

class ViewDailyNutritionInfoController extends ChangeNotifier { // ← Extend ChangeNotifier
  final SupabaseClient supabaseClient;

  ViewDailyNutritionInfoController({required this.supabaseClient});

  Map<String, double> _dailyTotals = {};
  Map<String, double> get dailyTotals => _dailyTotals;

  double _remainingCalories = 0.0;
  double get remainingCalories => _remainingCalories;

  Map<String, double> _mealTypeCalories = {
    'Breakfast': 0.0,
    'Lunch': 0.0,
    'Dinner': 0.0,
    'Snacks': 0.0,
  };
  Map<String, double> get mealTypeCalories => _mealTypeCalories;

  double _dailyCalorieGoal = 2000.0;
  double get dailyCalorieGoal => _dailyCalorieGoal;


  Future<void> calculateDailyTotals(String uid, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await supabaseClient
          .from('meal_log')
          .select()
          .eq('uid', uid)
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String());

      final meals = response.map<MealLog>((map) => MealLog.fromMap(map)).toList();

      // Initialize a map to hold nutrient totals
      Map<String, double> totalNutrients = {
        'calories': 0.0,
        'protein': 0.0,
        'carbohydrates': 0.0, 
        'fat': 0.0,
        'saturated fat': 0.0,
        'cholesterol': 0.0,
        'sodium': 0.0,
        'potassium': 0.0,
        'calcium': 0.0,
        'iron': 0.0,
        'vitamin a': 0.0,
        'vitamin c': 0.0,
        'vitamin d': 0.0,
        'fiber': 0.0,
        'sugar': 0.0,
      };

      // Sum the nutrients for the day
      for (var item in meals) {
        for (var nutrient in item.nutrition.nutrients) {
          if (totalNutrients.containsKey(nutrient.title.toLowerCase())) {
            totalNutrients[nutrient.title.toLowerCase()] =
                totalNutrients[nutrient.title.toLowerCase()]! + nutrient.amount;
          }
        }
      }

      // Round calories to nearest integer
      totalNutrients['calories'] = totalNutrients['calories']!.roundToDouble();

      _dailyTotals = totalNutrients;
      notifyListeners(); // ← Notify the UI
    } catch (e) {
      throw Exception('Failed to calculate daily totals: $e');
    }
  }

  Future<void> calculateRemainingCalories(String uid, DateTime date) async {
    try {
      final response = await supabaseClient
          .from('user_goals')
          .select()
          .eq('uid', uid)
          .single();

      final userGoal = UserGoals.fromMap(response);

      // Reuse updated dailyTotals instead of calling again
      await calculateDailyTotals(uid, date);

      final totalCaloriesConsumed = _dailyTotals['calories'] ?? 0.0;
      _remainingCalories = (userGoal.dailyCalories - totalCaloriesConsumed).roundToDouble();

      notifyListeners(); // ← Notify the UI
    } catch (e) {
      throw Exception('Failed to calculate remaining calories: $e');
    }
  }

  Future<void> fetchMealTypeCalories(String uid, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await supabaseClient
          .from('meal_log')
          .select()
          .eq('uid', uid)
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String());

      // Reset first
      _mealTypeCalories = {
        'Breakfast': 0.0,
        'Lunch': 0.0,
        'Dinner': 0.0,
        'Snacks': 0.0,
      };

      final meals = response.map<MealLog>((map) => MealLog.fromMap(map)).toList();

      for (var meal in meals) {
        if (_mealTypeCalories.containsKey(meal.mealType)) {
          for (var nutrient in meal.nutrition.nutrients) {
            if (nutrient.title.toLowerCase() == 'calories') {
              _mealTypeCalories[meal.mealType] =
                  _mealTypeCalories[meal.mealType]! + nutrient.amount;
            }
          }
        }
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch meal type calories: $e');
    }
  }

  Future<void> fetchDailyGoalCalories(String uid) async {
    try {
      final response = await supabaseClient
          .from('user_goals')
          .select('daily_calories')
          .eq('uid', uid)
          .single();

      _dailyCalorieGoal = (response['daily_calories'] as num).toDouble();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch daily calorie goal: $e');
    }
  }
  }
