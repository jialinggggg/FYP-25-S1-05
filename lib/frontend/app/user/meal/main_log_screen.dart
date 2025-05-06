import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:nutri_app/backend/controllers/view_daily_nutri_info_controller.dart';
import 'package:nutri_app/backend/controllers/log_daily_weight_controller.dart';
import 'package:nutri_app/backend/controllers/view_encouragement_controller.dart';
import 'package:nutri_app/frontend/app/user/meal/log_meal_screen.dart';

class MainLogScreen extends StatefulWidget {
  const MainLogScreen({super.key});

  @override
  State<MainLogScreen> createState() => _MainLogScreenState();
}

class _MainLogScreenState extends State<MainLogScreen> {
  late final SupabaseClient _supabase;
  final TextEditingController _weightController = TextEditingController();
  late final PageController _pageController;
  late final Timer _timer;

  int _currentPage = 0;
  bool _isEditing = false;
  bool _showDetailedNutrition = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _pageController = PageController();
    _startAutoSlide();
    _loadDataForDate(_selectedDate);
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _currentPage = (_currentPage + 1) % 2);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _loadDataForDate(DateTime date) {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    // 1) weight for the selected date (or fallback)
    context.read<LogDailyWeightController>().fetchWeightForDate(uid, date);

    // 2) encouragement (always based on today’s streak & weight)
    final enc = context.read<ViewEncouragementController>();
    enc.fetchMealLoggingStreak(uid);
    enc.fetchWeightEncouragement(uid);

    // 3) nutrition summary for the selected date
    final nut = context.read<ViewDailyNutritionInfoController>();
    nut.calculateRemainingCalories(uid, date);
    nut.fetchMealTypeCalories(uid, date);
    nut.fetchDailyGoalCalories(uid);
  }

  void _previousDate() {
    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
    _loadDataForDate(_selectedDate);
  }

  void _nextDate() {
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
    _loadDataForDate(_selectedDate);
  }

  Future<void> _saveWeight() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null || !mounted) return;

    try {
      final w = double.parse(_weightController.text);
      await context
          .read<LogDailyWeightController>()
          .logWeightForDate(uid, w, _selectedDate);

      await context.read<ViewEncouragementController>().fetchWeightEncouragement(uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weight saved!'), backgroundColor: Colors.green),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save weight: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meal Journal',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildBannerSection(),
              const SizedBox(height: 20),
              _buildDateSelector(),
              const SizedBox(height: 20),
              const Text(
                'Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 10),
              _buildSummaryCard(),
              const SizedBox(height: 20),
              const Text(
                'Meal Tracker',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 10),
              _buildMealTiles(),
              const SizedBox(height: 20),
              _buildWeightWidget(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBannerSection() {
    return Consumer<ViewEncouragementController>(
      builder: (_, ctrl, __) {
        final streak = ctrl.mealStreakMessage;
        final wEnc = ctrl.weightEncouragement['message'] ?? '';
        if (streak.isEmpty && wEnc.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 80,
          child: PageView(
            controller: _pageController,
            children: [
              if (streak.isNotEmpty) _buildBanner(streak, 'success'),
              if (wEnc.isNotEmpty) _buildBanner(wEnc, ctrl.weightEncouragement['status'] ?? 'neutral'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBanner(String msg, String status) {
    late IconData icon;
    late Color color;
    switch (status) {
      case 'success':
        icon = Icons.emoji_events;
        color = Colors.orange;
        break;
      case 'warning':
        icon = Icons.warning_amber;
        color = Colors.redAccent;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.blue;
        break;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: TextStyle(fontSize: 16, color: color))),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.green),
          onPressed: _previousDate,
        ),
        Text(
          DateFormat('MMM d, yyyy').format(_selectedDate),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.green),
          onPressed: _nextDate,
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Consumer<ViewDailyNutritionInfoController>(
      builder: (_, ctrl, __) {
        final taken = ctrl.dailyTotals['calories'] ?? 0.0;
        final goal = ctrl.dailyCalorieGoal;
        final rem = goal - taken;
        final pct = (taken / goal).clamp(0.0, 1.0);
        final over = rem < 0;
        final remTxt = over ? '${rem.abs().toInt()} kcal' : '${rem.toInt()} kcal';
        final label = over ? 'Over' : 'Remaining';
        final col = over ? const Color(0xFFEF6666) : Colors.green;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              const Text(
                'Remaining Calories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              CircularPercentIndicator(
                radius: 80,
                lineWidth: 12,
                percent: pct,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(remTxt, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                progressColor: col,
                backgroundColor: Colors.grey[300]!,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.grey),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _nutriItem('Calories', taken.toStringAsFixed(0), 'kcal'),
                  _nutriItem('Protein', ctrl.dailyTotals['protein']?.toStringAsFixed(1) ?? '0.0', 'g'),
                  _nutriItem('Carbs', ctrl.dailyTotals['carbohydrates']?.toStringAsFixed(1) ?? '0.0', 'g'),
                  _nutriItem('Fats', ctrl.dailyTotals['fat']?.toStringAsFixed(1) ?? '0.0', 'g'),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _showDetailedNutrition = !_showDetailedNutrition),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showDetailedNutrition ? 'Hide Detailed Nutrition' : 'See Detailed Nutrition',
                      style: const TextStyle(color: Colors.green),
                    ),
                    Icon(_showDetailedNutrition ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: Colors.green),
                  ],
                ),
              ),
              if (_showDetailedNutrition) ..._detailedNutrition(ctrl.dailyTotals),
            ],
          ),
        );
      },
    );
  }

  Widget _nutriItem(String label, String val, String unit) {
    return Column(
      children: [
        Row(
          children: [
            Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(width: 2),
            Text(unit, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  List<Widget> _detailedNutrition(Map<String, double> totals) {
    const nutrients = [
      'Calories','Protein','Carbohydrates','Fat','Saturated Fat','Cholesterol',
      'Sodium','Potassium','Calcium','Iron','Vitamin A','Vitamin C','Vitamin D','Fiber','Sugar'
    ];
    return nutrients.map((n) {
      final v = totals[n.toLowerCase()] ?? 0.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(n, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 14)),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildMealTiles() {
    return Column(
      children: ['Breakfast', 'Lunch', 'Dinner', 'Snacks']
          .map((meal) => _buildMealTile(meal, 'assets/${meal.toLowerCase()}.png'))
          .toList(),
    );
  }

  Widget _buildMealTile(String mealType, String icon) {
    return Consumer<ViewDailyNutritionInfoController>(
      builder: (_, ctrl, __) {
        final taken = ctrl.mealTypeCalories[mealType] ?? 0.0;
        final goal = ctrl.dailyCalorieGoal;
        final ratio = <String, double>{
          'Breakfast': 0.25,
          'Lunch': 0.30,
          'Dinner': 0.30,
          'Snacks': 0.15,
        }[mealType]!;
        final target = goal * ratio;

        return Card(
          child: ListTile(
            leading: CircleAvatar(backgroundImage: AssetImage(icon)),
            title: Text(mealType, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${taken.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} kcal'),
            trailing: const Icon(Icons.add_circle_outline),
            onTap: () {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LogMealScreen(
                    mealType: mealType,
                    selectedDate: _selectedDate,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWeightWidget() {
    return Consumer<LogDailyWeightController>(
      builder: (_, ctrl, __) {
        if (ctrl.latestWeight != null && _weightController.text.isEmpty) {
          _weightController.text = ctrl.latestWeight!.toStringAsFixed(1);
        }
        final isLogged = ctrl.isWeightLogged;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLogged && !_isEditing ? Colors.grey[300] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text('Log Your Weight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle),
                    onPressed: (isLogged && !_isEditing)
                        ? null
                        : () {
                            final c = double.tryParse(_weightController.text) ?? 0.0;
                            setState(() => _weightController.text = (c - 0.5).toStringAsFixed(1));
                          },
                    color: (isLogged && !_isEditing) ? Colors.grey : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _weightController,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      enabled: !isLogged || _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: (isLogged && !_isEditing)
                        ? null
                        : () {
                            final c = double.tryParse(_weightController.text) ?? 0.0;
                            setState(() => _weightController.text = (c + 0.5).toStringAsFixed(1));
                          },
                    color: (isLogged && !_isEditing) ? Colors.grey : Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: (isLogged && !_isEditing) ? null : _saveWeight,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(_isEditing ? 'Save Weight' : 'Submit Weight'),
              ),
              if (isLogged && !_isEditing)
                TextButton(
                  onPressed: () => setState(() => _isEditing = true),
                  child: const Text('Edit Weight', style: TextStyle(color: Colors.green)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 2,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      onTap: (i) {
        if (i == 2) return;
        Navigator.pushReplacementNamed(
          context,
          ['/orders', '/main_recipes', '/log', '/dashboard', '/profile'][i],
        );
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Recipes'),
        BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Journal'),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
