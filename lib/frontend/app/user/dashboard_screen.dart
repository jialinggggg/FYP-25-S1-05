import 'package:flutter/material.dart';
import 'package:nutri_app/frontend/app/user/profile_screen.dart';
import 'package:nutri_app/frontend/app/user/report_nutri.dart';
import 'orders_screen.dart';
import 'recipes_screen.dart';
import 'main_log_screen.dart';
import 'body_stat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MainReportDashboard extends StatefulWidget {
  const MainReportDashboard({super.key});

  @override
  State<MainReportDashboard> createState() => _MainReportDashboardState();
}

class _MainReportDashboardState extends State<MainReportDashboard> {
  final SupabaseClient _supabase = Supabase.instance.client;
  DateTime? _latestNutritionDate;
  int? _latestCalories;
  DateTime? _latestBodyStatDate;
  double? _latestBMI;

  @override
  void initState() {
    super.initState();
    _fetchNutritionData();
    _fetchBodyStatData();
  }

  Future<void> _fetchNutritionData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch the latest date with meal entries
      final latestDateResponse = await _supabase
          .from('meal_entries')
          .select('created_at')
          .eq('uid', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (latestDateResponse.isEmpty) return;

      final latestDate = DateTime.parse(latestDateResponse[0]['created_at'] as String);
      final startOfDay = DateTime(latestDate.year, latestDate.month, latestDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Fetch all meal entries for the latest day
      final response = await _supabase
          .from('meal_entries')
          .select('calories, created_at')
          .eq('uid', userId)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      if (response.isNotEmpty) {
        // Calculate total calories for the day
        int totalCalories = 0;
        for (var entry in response) {
          totalCalories += (entry['calories'] as num).toInt();
        }

        setState(() {
          _latestCalories = totalCalories;
          _latestNutritionDate = latestDate;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching nutrition data: $e')),
      );
    }
  }

  Future<void> _fetchBodyStatData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('user_measurements')
          .select('bmi, created_at')
          .eq('uid', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        setState(() {
          _latestBMI = (response[0]['bmi'] as num).toDouble();
          _latestBodyStatDate = DateTime.parse(response[0]['created_at'] as String);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching body stats: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDashboardButton(
              icon: Icons.restaurant,
              title: 'Nutrition',
              date: _latestNutritionDate,
              value: _latestCalories?.toStringAsFixed(0) ?? '--',
              unit: 'kcal',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NutritionReportScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardButton(
              icon: Icons.monitor_heart,
              title: 'Body Stat',
              date: _latestBodyStatDate,
              value: _latestBMI?.toStringAsFixed(1) ?? '--',
              unit: 'BMI',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HealthReportScreen()),
                );
              },
            ),
          ],
        ),
      ),
      /// Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen()));
          } else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const RecipesScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MainLogScreen()));
          } else if (index == 4) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Recipes"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Log"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildDashboardButton({
    required IconData icon,
    required String title,
    required DateTime? date,
    required String value,
    required String unit,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.green),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Latest:",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      date != null 
                          ? DateFormat('MMM dd, yyyy').format(date)
                          : 'No data',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}