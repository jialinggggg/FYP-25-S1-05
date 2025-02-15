import 'package:flutter/material.dart';
import 'add_food_screen.dart';
import 'recipes_screen.dart';
import 'orders_screen.dart';

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

  Map<String, int> mealCalories = {
    "Breakfast": 0,
    "Lunch": 0,
    "Dinner": 0,
    "Snacks": 0
  };

  Map<String, List<Map<String, dynamic>>> loggedMeals = {
    "Breakfast": [],
    "Lunch": [],
    "Dinner": [],
    "Snacks": [],
  };

  /// ✅ Add Food Function
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
      setState(() {
        for (var food in selectedFoods) {
          int foodCalories = int.parse(food["calories"].split(" ")[0]);
          double foodCarbs = double.parse(food["carbs"].split(" ")[0]);
          double foodProtein = double.parse(food["protein"].split(" ")[0]);
          double foodFat = double.parse(food["fat"].split(" ")[0]);

          if (!loggedMeals[mealType]!.any((f) => f["name"] == food["name"])) {
            loggedMeals[mealType]!.add(food);
            mealCalories[mealType] = (mealCalories[mealType] ?? 0) + foodCalories;
            totalCaloriesEaten += foodCalories;
            remainingCalories = (totalDailyGoal - totalCaloriesEaten).clamp(0, totalDailyGoal);
            totalCarbs += foodCarbs;
            totalProtein += foodProtein;
            totalFat += foodFat;
          }
        }
      });
    }
  }

  /// Remove Food Function
  void _removeFood(String mealType, int index) {
    setState(() {
      var food = loggedMeals[mealType]![index];

      int foodCalories = int.parse(food["calories"].split(" ")[0]);
      double foodCarbs = double.parse(food["carbs"].split(" ")[0]);
      double foodProtein = double.parse(food["protein"].split(" ")[0]);
      double foodFat = double.parse(food["fat"].split(" ")[0]);

      totalCaloriesEaten = (totalCaloriesEaten - foodCalories).clamp(0, totalDailyGoal);
      remainingCalories = (totalDailyGoal - totalCaloriesEaten).clamp(0, totalDailyGoal);
      totalCarbs = (totalCarbs - foodCarbs).clamp(0.0, double.infinity);
      totalProtein = (totalProtein - foodProtein).clamp(0.0, double.infinity);
      totalFat = (totalFat - foodFat).clamp(0.0, double.infinity);

      mealCalories[mealType] = (mealCalories[mealType]! - foodCalories).clamp(0, double.infinity).toInt();
      loggedMeals[mealType]?.removeAt(index);
    });
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          Text(
            "$remainingCalories kcal",
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey[400]), // Adds a separator line
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
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Summary",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 10),
                _buildSummaryCard(),
                const SizedBox(height: 20),
                const Text(
                  "Meal Tracker",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
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
          if (index == 0) { // If Orders is clicked
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrdersScreen()),
            );
          } else if (index == 1) { // If Recipes is clicked
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RecipesScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Recipes"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Log"), // Default Page
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  /// Meal Tile Widget
  Widget _buildMealTile(String mealType, int kcal, String iconPath) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage(iconPath),
          backgroundColor: Colors.grey,
        ),
        title: Text(mealType, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    if (loggedMeals[mealType] == null || loggedMeals[mealType]!.isEmpty) {
      return [
        const Padding(
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
        title: Text(food["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${food["calories"]} - ${food["carbs"]} Carbs, ${food["protein"]} Protein, ${food["fat"]} Fat"),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () => _removeFood(mealType, index),
        ),
      );
    }).toList();
  }
}