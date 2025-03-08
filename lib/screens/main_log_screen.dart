// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_food_screen.dart';
import 'recipes_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class MainLogScreen extends StatefulWidget {
  const MainLogScreen({super.key});

  @override
  MainLogScreenState createState() => MainLogScreenState();
}

class MainLogScreenState extends State<MainLogScreen> {
  final int totalDailyGoal = 2000;
  int remainingCalories = 2000;
  int totalCaloriesEaten = 0;
  double totalCarbs = 0;
  double totalProtein = 0;
  double totalFat = 0;
<<<<<<< HEAD
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
          MaterialPageRoute(builder: (context) => const DashboardScreen())
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

=======
>>>>>>> parent of 465792e (try)

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
    _fetchLoggedMeals(); // Fetch data when the screen loads
  }

  /// Function to Fetch Data from Supabase
  Future<void> _fetchLoggedMeals() async {
    try {
      // Ensure you select all columns (including 'id')
      final data = await Supabase.instance.client
          .from('foods')
          .select(); // selects all columns by default
      if ((data as List).isEmpty) {
        print('No data found.');
      } else {
        print('Fetched meals: $data');
        setState(() {
          for (var food in data as List<dynamic>) {
            String mealType = food['meal_type'];
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
        int foodCalories = int.parse(food["calories"].split(" ")[0]);
        double foodCarbs = double.parse(food["carbs"].split(" ")[0]);
        double foodProtein = double.parse(food["protein"].split(" ")[0]);
        double foodFat = double.parse(food["fat"].split(" ")[0]);

        // Check if the food already exists locally
        if (!loggedMeals[mealType]!.any((f) => f["name"] == food["name"])) {
          // First update local state
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

          // Then insert the food into Supabase and update the local record with the returned id
          try {
            final inserted = await Supabase.instance.client
                .from('foods')
                .insert({
<<<<<<< HEAD
              'user_id': Supabase.instance.client.auth.currentUser?.id,
=======
>>>>>>> parent of 465792e (try)
              'name': food["name"],
              'calories': food["calories"],
              'carbs': food["carbs"],
              'protein': food["protein"],
              'fat': food["fat"],
              'meal_type': mealType,
            }).select();

            print('Food added to Supabase: $inserted');

            // Make sure to update the local food item with its generated id.
            if (inserted.isNotEmpty) {
              setState(() {
                // Update the last inserted food with its id from Supabase
                loggedMeals[mealType]!.last['id'] = inserted.first['id'];
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
    // Get the food to remove
    final food = loggedMeals[mealType]![index];
    final foodId = food['id']; // Make sure 'id' exists

    if (foodId == null) {
      print('Food id is null, cannot delete.');
      return;
    }

    // Parse the nutrition info to update local totals
    int foodCalories = int.parse(food["calories"].split(" ")[0]);
    double foodCarbs = double.parse(food["carbs"].split(" ")[0]);
    double foodProtein = double.parse(food["protein"].split(" ")[0]);
    double foodFat = double.parse(food["fat"].split(" ")[0]);

    // First update the local state
    setState(() {
      totalCaloriesEaten =
          (totalCaloriesEaten - foodCalories).clamp(0, totalDailyGoal);
      remainingCalories =
          (totalDailyGoal - totalCaloriesEaten).clamp(0, totalDailyGoal);
      totalCarbs = (totalCarbs - foodCarbs).clamp(0.0, double.infinity);
      totalProtein = (totalProtein - foodProtein).clamp(0.0, double.infinity);
      totalFat = (totalFat - foodFat).clamp(0.0, double.infinity);

      mealCalories[mealType] =
          (mealCalories[mealType]! - foodCalories).clamp(0, double.infinity).toInt();

      // Remove the item from the local list
      loggedMeals[mealType]?.removeAt(index);
    });

    // Then make the call to Supabase to delete the row from the 'foods' table
    try {
      final response = await Supabase.instance.client
          .from('foods')
          .delete()
          .eq('id', foodId);
      print('Food deleted from Supabase: $response');
    } catch (error) {
      print('Error deleting food from Supabase: $error');
    }
  }

  /// Builds the Summary Card Widget
  Widget _buildSummaryCard() {
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
                color: Colors.black54),
          ),
          Text(
            "$remainingCalories kcal",
            style:
                const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey[400]),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMacroIndicator(totalCarbs, "Carbs", Colors.brown),
              _buildMacroIndicator(totalProtein, "Protein", Colors.blue),
              _buildMacroIndicator(totalFat, "Fat", Colors.yellow[800]!),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds Macro Indicator Widgets
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
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Main Log Updated Frame",
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Summary",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                const SizedBox(height: 10),
                _buildSummaryCard(),
                const SizedBox(height: 20),
                const Text(
                  "Meal Tracker",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    _buildMealTile("Breakfast",
                        mealCalories["Breakfast"] ?? 0, "assets/breakfast.png"),
                    _buildMealTile("Lunch",
                        mealCalories["Lunch"] ?? 0, "assets/lunch.png"),
                    _buildMealTile("Dinner",
                        mealCalories["Dinner"] ?? 0, "assets/dinner.png"),
                    _buildMealTile("Snacks",
                        mealCalories["Snacks"] ?? 0, "assets/snacks.png"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: 2, // Log is the default page
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrdersScreen()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RecipesScreen()),
            );
          } else if (index == 4) {  // <-- Added this for Profile navigation
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()), // Navigate to Profile
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: "Orders"),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant), label: "Recipes"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Log"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

<<<<<<< HEAD


=======
>>>>>>> parent of 465792e (try)
  /// Meal Tile Widget
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

  /// Meal List Widget
  List<Widget> _buildMealList(String mealType) {
    if (loggedMeals[mealType] == null ||
        loggedMeals[mealType]!.isEmpty) {
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
        title: Text(food["name"],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            "${food["calories"]} - ${food["carbs"]} Carbs, ${food["protein"]} Protein, ${food["fat"]} Fat"),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline,
              color: Colors.red),
          onPressed: () => _removeFood(mealType, index),
        ),
      );
    }).toList();
  }
}

