import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../api/spoonacular_service.dart';
import '../entities/meal_log.dart';
import '../entities/recipes.dart';
import '../entities/nutrition.dart';

class LogMealController extends ChangeNotifier {
  final SupabaseClient supabaseClient;
  final SpoonacularService spoonacularService;

  LogMealController(this.supabaseClient, this.spoonacularService);

  List<MealLog> _loggedMeals = [];
  List<MealLog> get loggedMeals => _loggedMeals;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<MealLog> _mealsToAdd = [];
  final List<String> _mealsToRemove = [];

  // Fetch logged meals for a specific user on a specific day
  Future<void> fetchLoggedMeals(String uid, DateTime date, String mealType) async {
    try {
      _isLoading = true; // Set loading to true while fetching data
      notifyListeners(); // Notify listeners about the state change

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final mealLogResponse = await supabaseClient
          .from('meal_log')
          .select()
          .eq('uid', uid)
          .eq('meal_type', mealType)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      // Check if the response contains data
      if (mealLogResponse.isEmpty) {
         _loggedMeals = []; // Set an empty list if no records are found
         _isLoading = false; // Set loading to false after fetching
        notifyListeners(); // Notify listeners that the data has been updated
        return; // Exit the function gracefully
      }

      // Parse the fetched data into MealLog objects
      _loggedMeals = (mealLogResponse as List)
          .map((mealData) => MealLog.fromMap(mealData))
          .toList();

      _isLoading = false; // Set loading to false after fetching
      notifyListeners(); // Notify listeners that the data has been updated
    } catch (e) {
      _isLoading = false; // Stop loading if there's an error
      notifyListeners(); // Notify listeners that loading has stopped
      throw Exception('Failed to fetch logged meals: $e');
    }
  }

  // Add a new meal log using the Recipes data
  void addLogMeal(Recipes recipe, String uid, String mealType, DateTime date) {
    try {
      var uuid = Uuid();
      String mealId = uuid.v4();

      MealLog newMealLog = MealLog(
        mealId: mealId,
        uid: uid,
        recipeId: recipe.id,
        sourceType: recipe.sourceType ?? 'Unknown',
        mealName: recipe.title,
        mealType: mealType,
        image: recipe.image ?? "https://via.placeholder.com/150",
        nutrition: recipe.nutrition ?? Nutrition(nutrients: []),
        createdAt: date,
      );

      _mealsToAdd.add(newMealLog);
      _loggedMeals.add(newMealLog);
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to add meal log: $e");
    }
  }

  // Remove a meal log
  void removeLogMeal(String mealId) {
    try {
      _mealsToRemove.add(mealId);
      _mealsToAdd.removeWhere((meal) => meal.mealId == mealId);
      _loggedMeals.removeWhere((meal) => meal.mealId == mealId);
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to remove meal log: $e");
    }
  }

  // Save meals to database (insert new and remove deleted)
  Future<void> saveMeals() async {
    try {
      // Insert new meals
      if (_mealsToAdd.isNotEmpty) {
        final payload = _mealsToAdd.map((meal) => meal.toMap()).toList();
        await supabaseClient.from('meal_log').insert(payload);
      }

      // Delete removed meals
      if (_mealsToRemove.isNotEmpty) {
        await supabaseClient
            .from('meal_log')
            .delete()
            .inFilter('meal_id', _mealsToRemove); // Use inFilter for batch delete
      }

      // Clear buffers
      _mealsToAdd.clear();
      _mealsToRemove.clear();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to save meals: $e');
    }
  }
}
