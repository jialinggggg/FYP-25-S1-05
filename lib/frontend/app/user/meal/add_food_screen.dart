import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../backend/supabase/meal_entries_service.dart';
import '../../../../services/spoonacular_api_service.dart';

class AddFoodScreen extends StatefulWidget {
  final String mealType;

  const AddFoodScreen({super.key, required this.mealType}); // Use super.key

  @override
  AddFoodScreenState createState() => AddFoodScreenState();
}

class AddFoodScreenState extends State<AddFoodScreen> {
  final SpoonacularApiService _spoonacularApiService = SpoonacularApiService();
  final MealEntriesService _mealEntriesService = MealEntriesService(Supabase.instance.client);
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _loggedMeals = [];
  List<Map<String, dynamic>> _searchResults = [];
  final List<Map<String, dynamic>> _selectedMeals = [];

  @override
  void initState() {
    super.initState();
    _fetchLoggedMeals();
  }

  Future<void> _fetchLoggedMeals() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return; // Exit if user is not logged in

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final meals = await _mealEntriesService.fetchMealEntries(userId);
      setState(() {
        _loggedMeals = meals
            .where((meal) =>
                meal['type'] == widget.mealType &&
                DateTime.parse(meal['created_at']).isAfter(startOfDay) &&
                DateTime.parse(meal['created_at']).isBefore(endOfDay))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching logged meals: $e')),
        );
      }
    }
  }

  Future<void> _searchMeals(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final results = await _spoonacularApiService.searchMeals(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching meals: $e')),
        );
      }
    }
  }

  void _addMeal(Map<String, dynamic> meal) {
    setState(() {
      _selectedMeals.add(meal);
    });
  }

  void _removeMeal(int index, bool isLoggedMeal) {
    setState(() {
      if (isLoggedMeal) {
        // Mark logged meal for deletion
        _loggedMeals[index]['markedForDeletion'] = true;
      } else {
        // Remove unsaved meal
        _selectedMeals.removeAt(index - _loggedMeals.length);
      }
    });
  }

  Future<void> _saveMeals() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return; // Exit if user is not logged in

      // Delete marked meals from the database
      for (var meal in _loggedMeals) {
        if (meal['markedForDeletion'] == true) {
          await _mealEntriesService.deleteMealEntry(meal['meal_id']);
        }
      }

      // Add new meals to the database
      for (var meal in _selectedMeals) {
        await _mealEntriesService.insertMealEntry(
          spoonacularId: meal['id'],
          uid: userId,
          name: meal['title'],
          calories: _getCalories(meal), // Use _getCalories for int
          carbs: _getNutrientValue(meal, 'Carbohydrates'), // Already double
          protein: _getNutrientValue(meal, 'Protein'), // Already double
          fats: _getNutrientValue(meal, 'Fat'), // Already double
          type: widget.mealType,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meals saved successfully!')),
        );

        // Navigate back to MainLogScreen with updated data
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving meals: $e')),
        );
      }
    }
  }

  // Helper method to get calories as int
  int _getCalories(Map<String, dynamic> meal) {
    final nutrients = meal['nutrition']['nutrients'] as List<dynamic>;
    final nutrient = nutrients.firstWhere(
      (n) => n['name'] == 'Calories',
      orElse: () => {'amount': 0.0}, // Default value if nutrient is not found
    );
    return nutrient['amount'].toInt(); // Convert to int
  }

  // Helper method to get other nutrients as double
  double _getNutrientValue(Map<String, dynamic> meal, String nutrientName) {
    final nutrients = meal['nutrition']['nutrients'] as List<dynamic>;
    final nutrient = nutrients.firstWhere(
      (n) => n['name'] == nutrientName,
      orElse: () => {'amount': 0.0}, // Default value if nutrient is not found
    );
    return nutrient['amount'] as double; // Return as double
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.mealType, style: const TextStyle(color: Colors.black, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logged Meals Section (1/3 of the screen)
          Container(
            height: MediaQuery.of(context).size.height / 3,
            color: Colors.grey[200], // Light grey background
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nutrition Logged",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (_loggedMeals.isEmpty && _selectedMeals.isEmpty)
                  const Center(
                    child: Text("Nothing here yet! Add your meal to see your progress."),
                  ),
                if (_loggedMeals.isNotEmpty || _selectedMeals.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _loggedMeals.length + _selectedMeals.length,
                      itemBuilder: (context, index) {
                        final isLoggedMeal = index < _loggedMeals.length;
                        final meal = isLoggedMeal
                            ? _loggedMeals[index]
                            : _selectedMeals[index - _loggedMeals.length];

                        // Hide meals marked for deletion
                        if (isLoggedMeal && meal['markedForDeletion'] == true) {
                          return const SizedBox.shrink(); // Hide the meal
                        }

                        return ListTile(
                          title: Text(meal['title'] ?? meal['name']),
                          subtitle: Text(
                            'Calories: ${isLoggedMeal ? meal['calories'] : _getCalories(meal)} kcal | '
                            'Carbs: ${isLoggedMeal ? meal['carbs'] : _getNutrientValue(meal, 'Carbohydrates').toStringAsFixed(2)}g | '
                            'Protein: ${isLoggedMeal ? meal['protein'] : _getNutrientValue(meal, 'Protein').toStringAsFixed(2)}g | '
                            'Fats: ${isLoggedMeal ? meal['fats'] : _getNutrientValue(meal, 'Fat').toStringAsFixed(2)}g',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _removeMeal(index, isLoggedMeal),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Search Bar and Results Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for meals...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: _searchMeals,
                  ),
                  const SizedBox(height: 10),

                  // Search Results
                  if (_searchResults.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final meal = _searchResults[index];
                          return ListTile(
                            title: Text(meal['title']),
                            subtitle: Text(
                              'Calories: ${_getCalories(meal)} kcal | '
                              'Carbs: ${_getNutrientValue(meal, 'Carbohydrates')}g | '
                              'Protein: ${_getNutrientValue(meal, 'Protein')}g | '
                              'Fats: ${_getNutrientValue(meal, 'Fat')}g',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _addMeal(meal),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Save Button at the bottom
      bottomNavigationBar: Container(
        color: Colors.green,
        height: 60,
        child: InkWell(
          onTap: _saveMeals,
          child: const Center(
            child: Text(
              "Save",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}