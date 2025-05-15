import 'package:flutter/material.dart';
import 'package:nutri_app/frontend/app/user/report/detailed_report_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../backend/controllers/fetch_nutrition_data_controller.dart';
import '../../../../backend/controllers/fetch_body_stat_data_controller.dart'; // Import controllers

class MainReportScreen extends StatefulWidget {
  const MainReportScreen({super.key});

  @override
  State<MainReportScreen> createState() => _MainReportScreenState();
}

class _MainReportScreenState extends State<MainReportScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final FetchNutritionDataController _nutritionController; 
  late final FetchBodyStatDataController _bodyStatController;
  
  DateTime? _latestNutritionDate;
  int? _latestCalories;
  DateTime? _latestBodyStatDate;
  double? _latestBMI;

  @override
  void initState() {
    super.initState();
    // Initialize the controllers in initState() using the `late final` variables
    _nutritionController = FetchNutritionDataController(supabaseClient: _supabase);
    _bodyStatController = FetchBodyStatDataController(supabaseClient: _supabase);

    _fetchNutritionData();
    _fetchBodyStatData();
  }

  Future<void> _fetchNutritionData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch nutrition data for the latest date using the FetchNutritionDataController
      await _nutritionController.fetchLatestNutritionData(userId);
      
      if (_nutritionController.error != null) {
        // Handle error if any
        throw _nutritionController.error!;
      }

      setState(() {
        _latestCalories = _nutritionController.dailyTotals['calories']?.toInt();
        _latestNutritionDate = _nutritionController.createdAt;
      });
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

      // Fetch body stat data using the FetchBodyStatDataController
      await _bodyStatController.fetchLatestBodyStatData(userId);

      if (_bodyStatController.error != null) {
        // Handle error if any
        throw _bodyStatController.error!;
      }

      setState(() {
        _latestBMI = _bodyStatController.bmi;
        _latestBodyStatDate = _bodyStatController.createdAt;
      });
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
        title: const Text('Health Dashboard',
        style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold),),
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
                  MaterialPageRoute(builder: (context) => DetailedReportScreen(reportType: 'nutrition')),
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
                  MaterialPageRoute(builder: (context) => DetailedReportScreen(reportType: 'body stat')),
                );
              },
            ),
          ],
        ),
      ),
      /// Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavBar(context)
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

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 3,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 3) return;
        Navigator.pushReplacementNamed(context, ['/orders', '/main_recipes', '/log', '/dashboard', '/profile'][index]);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Orders"),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Recipes"),
        BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Journal"),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
