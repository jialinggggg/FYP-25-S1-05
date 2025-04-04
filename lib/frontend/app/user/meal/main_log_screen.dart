import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_food_screen.dart';
import '../report/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../recipes/recipes_screen.dart';
import '../order/orders_screen.dart';
import '../../../../backend/supabase/user_goals_service.dart';
import '../../../../backend/supabase/meal_entries_service.dart';
import '../../../../backend/supabase/user_measurements_service.dart';
import '../../../../backend/supabase/user_profiles_service.dart';

class MainLogScreen extends StatefulWidget {
  const MainLogScreen({super.key});

  @override
  MainLogScreenState createState() => MainLogScreenState();
}

class MainLogScreenState extends State<MainLogScreen> {
  int _selectedIndex = 2;
  final TextEditingController _weightController = TextEditingController();
  int remainingCalories = 0;
  int totalCaloriesEaten = 0;
  double totalCarbs = 0;
  double totalProtein = 0;
  double totalFat = 0;
  double? userWeight;
  int totalDailyGoal = 0;
  double height = 0;
  bool _hasLoggedWeightToday = false;
  bool _isEditingWeight = false;
  String? _measurementId;

  // Declare services as late
  late final UserGoalsService _userGoalsService;
  late final MealEntriesService _mealEntriesService;
  late final UserProfilesService _userProfilesService;
  late final UserMeasurementService _userMeasurementService;

  @override
  void initState() {
    super.initState();

    // Initialize services
    _userGoalsService = UserGoalsService(Supabase.instance.client);
    _mealEntriesService = MealEntriesService(Supabase.instance.client);
    _userProfilesService = UserProfilesService(Supabase.instance.client);
    _userMeasurementService = UserMeasurementService(
      Supabase.instance.client,
      _userProfilesService,
    );

    // Fetch data
    _fetchDailyCalories();
    _fetchDailyTotals();
    _checkIfWeightLoggedToday();
  }

  Map<String, int> mealCalories = {
    "Breakfast": 0,
    "Lunch": 0,
    "Dinner": 0,
    "Snacks": 0,
  };

  /// Navigation Logic
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Orders
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrdersScreen()),
        );
        break;
      case 1: // Recipes
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RecipesScreen()),
        );
        break;
      case 2: // Log (stay here)
        break;
      case 3: // Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainReportDashboard()),
        );
        break;
      case 4: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  Future<void> _fetchDailyCalories() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final goals = await _userGoalsService.fetchGoals(userId);
      if (goals != null) {
        setState(() {
          totalDailyGoal = goals['daily_calories'];
          remainingCalories = totalDailyGoal;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching daily calories: $e')),
        );
      }
    }
  }

  /// Fetch daily totals and update UI
  Future<void> _fetchDailyTotals() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final dailyTotals = await _mealEntriesService.calculateDailyTotals(userId, DateTime.now());
      final mealTypeCalories = await _mealEntriesService.calculateCaloriesByMealType(userId, DateTime.now());

      setState(() {
        totalCaloriesEaten = dailyTotals['totalCalories'] as int;
        totalCarbs = double.parse((dailyTotals['totalCarbs'] as double).toStringAsFixed(2));
        totalProtein = double.parse((dailyTotals['totalProtein'] as double).toStringAsFixed(2));
        totalFat = double.parse((dailyTotals['totalFats'] as double).toStringAsFixed(2));
        remainingCalories = (totalDailyGoal - totalCaloriesEaten).clamp(0, totalDailyGoal);

        mealCalories = mealTypeCalories;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching daily totals: $e')),
        );
      }
    }
  }

  /// Check if the user has logged their weight today
  Future<void> _checkIfWeightLoggedToday() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await Supabase.instance.client
          .from('user_measurements')
          .select()
          .eq('uid', userId)
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String());

      if (response.isNotEmpty) {
        setState(() {
          _hasLoggedWeightToday = true;
          _measurementId = response.first['measurement_id'].toString();
          _weightController.text = response.first['weight'].toStringAsFixed(0);
        });
      } else {
        final latestMeasurement = await _userMeasurementService.fetchLatestMeasurement(userId);
        if (latestMeasurement != null) {
          setState(() {
            _weightController.text = latestMeasurement['weight'].toStringAsFixed(0);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking weight log: $e')),
        );
      }
    }
  }

  /// Submit or update weight
  Future<void> _submitOrUpdateWeight() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final weight = double.tryParse(_weightController.text);
      if (weight == null || weight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid weight.')),
        );
        return;
      }

      if (_hasLoggedWeightToday) {
        // Update existing measurement
        await _userMeasurementService.updateMeasurement(
          measurementId: _measurementId!,
          weight: weight,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Weight updated successfully!')),
          );
        }
      } else {
        // Insert new measurement
        await _userMeasurementService.insertMeasurement(
          uid: userId,
          weight: weight,
        );
        setState(() {
          _hasLoggedWeightToday = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Weight logged successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging weight: $e')),
        );
      }
    }
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
                color: Colors.black54),
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
              _buildMacroIndicator(totalCaloriesEaten.toDouble(), "Calories", Colors.yellow[800]!),
              _buildMacroIndicator(totalCarbs, "Carbs", Colors.amber[800]!),
              _buildMacroIndicator(totalProtein, "Protein", Colors.purple[800]!),
              _buildMacroIndicator(totalFat, "Fats", Colors.lightBlue[800]!),
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

  /// Builds the Daily Weight Widget with text input and increment/decrement buttons
  Widget _buildDailyWeightWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hasLoggedWeightToday && !_isEditingWeight ? Colors.grey[300] : Colors.grey[200],
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
                onPressed: _hasLoggedWeightToday && !_isEditingWeight ? null : () {
                  setState(() {
                    double currentWeight = double.tryParse(_weightController.text) ?? 0;
                    currentWeight = (currentWeight - 1).clamp(0, double.infinity);
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
                  enabled: !_hasLoggedWeightToday || _isEditingWeight,
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
                onPressed: _hasLoggedWeightToday && !_isEditingWeight ? null : () {
                  setState(() {
                    double currentWeight = double.tryParse(_weightController.text) ?? 0;
                    currentWeight += 1;
                    _weightController.text = currentWeight.toStringAsFixed(0);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_hasLoggedWeightToday && !_isEditingWeight)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEditingWeight = true;
                });
              },
              child: const Text("Edit Weight"),
            ),
          if (!_hasLoggedWeightToday || _isEditingWeight)
            ElevatedButton(
              onPressed: () async {
                await _submitOrUpdateWeight();
                setState(() {
                  _isEditingWeight = false;
                });
              },
              child: Text(_hasLoggedWeightToday ? "Update Weight" : "Submit Weight"),
            ),
        ],
      ),
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

  Widget _buildMealTile(String mealType, int kcal, String iconPath) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage(iconPath),
          backgroundColor: Colors.grey,
        ),
        title: Text(mealType, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$kcal kcal"),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddFoodScreen(
                  mealType: mealType,
                ),
              ),
            );

            // Refresh data when returning from AddFoodScreen
            if (result == true) {
              _fetchDailyTotals();
            }
          },
        ),
      ),
    );
  }
}