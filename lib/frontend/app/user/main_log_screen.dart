// ignore_for_file: avoid_print

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_food_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'recipes_screen.dart';
import 'orders_screen.dart';

class MainLogScreen extends StatefulWidget {
  const MainLogScreen({super.key});

  @override
  MainLogScreenState createState() => MainLogScreenState();
}

/// Placeholder Screens for Missing Pages
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          "$title Page Coming Soon...",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class MainLogScreenState extends State<MainLogScreen> {
  /// Navigation Index
  int _selectedIndex = 2; // MainLog is the current page

  final int totalDailyGoal = 2000;
  final TextEditingController _weightController = TextEditingController();
  int remainingCalories = 2000;
  int totalCaloriesEaten = 0;
  double totalCarbs = 0;
  double totalProtein = 0;
  double totalFat = 0;
  double? userWeight;

  /// Navigation Logic
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Orders
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrdersScreen())
        );
        break;
      case 1: // Recipes
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RecipesScreen())
        );
        break;
      case 2: // Log (stay here)
        break;
      case 3: // Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainReportDashboard())
        );
        break;
      case 4: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen())
        );
        break;
    }
  }


  Map<String, int> mealCalories = {
    "Breakfast": 0,
    "Lunch": 0,
    "Dinner": 0,
    "Snacks": 0,
  };

  Map<String, List<Map<String, dynamic>>> loggedMeals = {
    "Breakfast": [],
    "Lunch": [],
    "Dinner": [],
    "Snacks": [],
  };

  @override
  void initState() {
    super.initState();
    _fetchLoggedMeals();
    // Initialize the weight controller with current weight or default to "0"
    _weightController.text = userWeight?.toStringAsFixed(0) ?? '0';
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  /// Function to Fetch Data from Supabase
  Future<void> _fetchLoggedMeals() async {
    try {
      // Fetch from meal_entries table.
      final data = await Supabase.instance.client
          .from('meal_entries')
          .select(); // selects all columns by default
      if ((data as List).isEmpty) {
        print('No data found.');
      } else {
        print('Fetched meals: $data');
        setState(() {
          for (var food in data as List<dynamic>) {
            String mealType = food['type'];
            if (loggedMeals.containsKey(mealType)) {
              loggedMeals[mealType]!.add(food);
            }
          }
        });
      }
    } catch (e) {
      print('Error fetching meals: $e');
    }
  }

  /// Add Food Function with Supabase
  void _addFood(String mealType) async {
  final List<Map<String, dynamic>>? selectedFoods = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddFoodScreen(
        mealType: mealType,
        existingFoods: List.from(loggedMeals[mealType]!),
      ),
    ),
  );

  if (selectedFoods != null && selectedFoods.isNotEmpty) {
    for (var food in selectedFoods) {
      // Safely parse values; if null or unparsable, default to 0 or 0.0.
      int foodCalories = int.tryParse(
              food["calories"]?.toString().split(" ")[0] ?? "") ??
          0;
      double foodCarbs = double.tryParse(
              food["carbs"]?.toString().split(" ")[0] ?? "") ??
          0.0;
      double foodProtein = double.tryParse(
              food["protein"]?.toString().split(" ")[0] ?? "") ??
          0.0;
      double foodFat = double.tryParse(
              food["fats"]?.toString().split(" ")[0] ?? "") ??
          0.0;

      // Check if the food already exists locally using the meal_name key.
      if (!loggedMeals[mealType]!
          .any((f) => f["name"] == food["name"])) {
        // First update local state.
        setState(() {
          loggedMeals[mealType]!.add(food);
          mealCalories[mealType] =
              (mealCalories[mealType] ?? 0) + foodCalories;
          totalCaloriesEaten += foodCalories;
          remainingCalories = (totalDailyGoal - totalCaloriesEaten)
              .clamp(0, totalDailyGoal);
          totalCarbs += foodCarbs;
          totalProtein += foodProtein;
          totalFat += foodFat;
        });

        // Ensure that the user is authenticated.
        String? userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          print('User is not authenticated. Please sign in.');
          // Optionally, navigate to the login screen or show a dialog.
          return;
        }

        // Insert into the meal_entries table.
        try {
          final inserted = await Supabase.instance.client
              .from('meal_entries')
              .insert({
            'uid': userId,
            'name': food['name'] ?? '',
            'calories': foodCalories,
            'carbs': foodCarbs,
            'protein': foodProtein,
            'fats': foodFat,
            'type': mealType,
          }).select();

          print('Food added to Supabase: $inserted');

          // Update the last inserted food with its primary key (meal_id) from Supabase.
          if (inserted.isNotEmpty) {
            setState(() {
              loggedMeals[mealType]!.last['meal_id'] =
                  inserted.first['meal_id'];
            });
          }
        } catch (e) {
          print('Error adding food: $e');
        }
      }
    }
  }
}


  /// Remove Food Function
  Future<void> _removeFood(String mealType, int index) async {
    // Get the food to remove.
    final food = loggedMeals[mealType]![index];
    // Use the primary key from your table.
    final foodId = food['meal_id'];

    if (foodId == null) {
      print('Food id is null, cannot delete.');
      return;
    }

    // Safely parse the nutrition info to update local totals.
    int foodCalories = int.tryParse(
            food["calories"]?.toString().split(" ")[0] ?? "") ??
        0;
    double foodCarbs = double.tryParse(
            food["carbs"]?.toString().split(" ")[0] ?? "") ??
        0.0;
    double foodProtein = double.tryParse(
            food["protein"]?.toString().split(" ")[0] ?? "") ??
        0.0;
    double foodFat = double.tryParse(
            food["fats"]?.toString().split(" ")[0] ?? "") ??
        0.0;

    // First update the local state.
    setState(() {
      totalCaloriesEaten =
          (totalCaloriesEaten - foodCalories).clamp(0, totalDailyGoal);
      remainingCalories =
          (totalDailyGoal - totalCaloriesEaten).clamp(0, totalDailyGoal);
      totalCarbs = (totalCarbs - foodCarbs).clamp(0.0, double.infinity);
      totalProtein = (totalProtein - foodProtein).clamp(0.0, double.infinity);
      totalFat = (totalFat - foodFat).clamp(0.0, double.infinity);

      mealCalories[mealType] = (mealCalories[mealType]! - foodCalories)
          .clamp(0, double.infinity)
          .toInt();

      // Remove the item from the local list.
      loggedMeals[mealType]?.removeAt(index);
    });

    // Delete from the correct table: meal_entries.
    try {
      final response = await Supabase.instance.client
          .from('meal_entries')
          .delete()
          .eq('meal_id', foodId);
      print('Food deleted from Supabase: $response');
    } catch (error) {
      print('Error deleting food from Supabase: $error');
    }
  }

  /// Builds the Daily Weight Widget with text input and increment/decrement buttons
  Widget _buildDailyWeightWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Log Your Weight",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () {
                  setState(() {
                    double currentWeight = double.tryParse(_weightController.text) ?? 0;
                    currentWeight = (currentWeight - 1).clamp(0, double.infinity);
                    userWeight = currentWeight;
                    _weightController.text = currentWeight.toStringAsFixed(0);
                  });
                },
              ),
              SizedBox(
                width: 100, // Fixed width to help center the input field
                child: TextField(
                  controller: _weightController,
                  textAlign: TextAlign.center, // Center the text inside the field
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Weight (kg)",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    double? newWeight = double.tryParse(value);
                    if (newWeight != null) {
                      setState(() {
                        userWeight = newWeight;
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                onPressed: () {
                  setState(() {
                    double currentWeight = double.tryParse(_weightController.text) ?? 0;
                    currentWeight += 1;
                    userWeight = currentWeight;
                    _weightController.text = currentWeight.toStringAsFixed(0);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              double? submittedWeight = double.tryParse(_weightController.text);
              if (submittedWeight != null) {
                setState(() {
                  userWeight = submittedWeight;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Weight logged: ${submittedWeight.toStringAsFixed(0)} kg"),
                  ),
                );
              }
            },
            child: const Text("Submit Weight"),
          ),
        ],
      ),
    );
  }

  /// Builds the Summary Card Widget
  Widget _buildSummaryCard() {
    double progress = totalCaloriesEaten / totalDailyGoal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            "Remaining Calories",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54
            ),
          ),
          const SizedBox(height: 10),

          /// Circular Progress Indicator
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 12.0,
            percent: progress.clamp(0.0, 1.0),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$remainingCalories kcal",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Remaining",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            progressColor: Colors.green,
            backgroundColor: Colors.grey[300]!,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 800,
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey[400]),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMacroIndicator(totalCarbs, "Carbs", Colors.amber[800]!),
              _buildMacroIndicator(totalProtein, "Protein", Colors.purple[800]!),
              _buildMacroIndicator(totalFat, "Fat", Colors.lightBlue[800]!),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds Macro Indicator Widgets.
  Widget _buildMacroIndicator(double value, String label, Color color) {
    return Column(
      children: [
        Text(
          "$value g",
          style:
          TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
        ),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Food Log",
          style: TextStyle(color: Colors.green[800], fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Summary",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                _buildSummaryCard(),
                const SizedBox(height: 20),
                const Text(
                  "Meal Tracker",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    _buildMealTile("Breakfast", mealCalories["Breakfast"] ?? 0, "assets/breakfast.png"),
                    _buildMealTile("Lunch", mealCalories["Lunch"] ?? 0, "assets/lunch.png"),
                    _buildMealTile("Dinner", mealCalories["Dinner"] ?? 0, "assets/dinner.png"),
                    _buildMealTile("Snacks", mealCalories["Snacks"] ?? 0, "assets/snacks.png"),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDailyWeightWidget(), // Moved this here below Meal Tracker
              ],
            ),
          ),
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_rounded), label: "Recipes"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.list_bullet_below_rectangle,), label: "Logs"),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  /// Meal Tile Widget.
  Widget _buildMealTile(String mealType, int kcal, String iconPath) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage(iconPath),
          backgroundColor: Colors.grey,
        ),
        title: Text(mealType,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$kcal kcal"),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _addFood(mealType),
        ),
        children: _buildMealList(mealType),
      ),
    );
  }

  /// Meal List Widget.
  List<Widget> _buildMealList(String mealType) {
    if (loggedMeals[mealType] == null || loggedMeals[mealType]!.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "No food logged yet.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ];
    }
    return loggedMeals[mealType]!.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> food = entry.value;
      return ListTile(
        title: Text(
          food["name"] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${food["calories"] ?? 0} - ${food["carbs"] ?? 0} Carbs, ${food["protein"] ?? 0} Protein, ${food["fats"] ?? 0} Fat",
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () => _removeFood(mealType, index),
        ),
      );
    }).toList();
  }
}
