import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class NutritionReportScreen extends StatefulWidget {
  const NutritionReportScreen({super.key});

  @override
  State<NutritionReportScreen> createState() => _NutritionReportScreenState();
}

class _NutritionReportScreenState extends State<NutritionReportScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String _selectedFilter = 'daily';
  String _selectedMetric = 'calories';
  String _dailyViewType = 'macronutrients'; // Toggle between macronutrients and meals
  DateTime _selectedDate = DateTime.now();
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  List<MealEntry> _mealEntries = [];

  @override
  void initState() {
    super.initState();
    _fetchNutritionData();
  }

  Future<void> _fetchNutritionData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      DateTime startDate;
      DateTime endDate;

      switch (_selectedFilter) {
        case 'latest':
          // Get last 100 entries to find unique dates
          final response = await _supabase
              .from('meal_entries')
              .select('created_at')
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(100);

          // Extract unique dates
          final uniqueDates = response
              .map((e) => DateTime.parse(e['created_at'] as String))
              .map((date) => DateTime(date.year, date.month, date.day))
              .toSet()
              .toList();

          // Take up to 7 unique dates, or all available if less than 7
          final daysToShow = uniqueDates.length >= 7 ? 7 : uniqueDates.length;
          final selectedDates = uniqueDates.sublist(0, daysToShow);

          if (selectedDates.isEmpty) {
            // No data available
            _mealEntries = [];
            if (mounted) setState(() {});
            return;
          }

          startDate = selectedDates.last;
          endDate = selectedDates.first.add(const Duration(days: 1));
          break;
        case 'monthly':
          startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
          endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          break;
        case 'custom':
          startDate = _customStartDate ?? DateTime.now();
          endDate = _customEndDate ?? DateTime.now();
          break;
        default: // daily
          startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
          endDate = startDate.add(const Duration(days: 1));
      }

      final dataResponse = await _supabase
          .from('meal_entries')
          .select('*')
          .eq('user_id', userId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      _mealEntries = dataResponse.map((entry) => MealEntry(
            date: DateTime.parse(entry['created_at'] as String),
            calories: (entry['meal_calories'] as num).toInt(),
            protein: (entry['meal_protein'] as num).toDouble(),
            carbs: (entry['meal_carbs'] as num).toDouble(),
            fats: (entry['meal_fats'] as num).toDouble(),
            name: entry['meal_name'] as String,
            type: entry['meal_type'] as String,
          )).toList();

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
  }

  void _navigateDay(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _fetchNutritionData();
  }

  void _navigateMonth(int months) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + months, 1);
    });
    _fetchNutritionData();
  }

  Map<String, double> _getDailyMacronutrients() {
    return {
      'Protein': _mealEntries.fold(0.0, (sum, entry) => sum + entry.protein),
      'Carbs': _mealEntries.fold(0.0, (sum, entry) => sum + entry.carbs),
      'Fats': _mealEntries.fold(0.0, (sum, entry) => sum + entry.fats),
    };
  }

  Map<String, double> _getMealTypeCalories() {
    final Map<String, double> mealCalories = {};
    for (final entry in _mealEntries) {
      mealCalories[entry.type] = (mealCalories[entry.type] ?? 0) + entry.calories.toDouble();
    }
    return mealCalories;
  }

  @override
  Widget build(BuildContext context) {
    final isDaily = _selectedFilter == 'daily';
    final dailyMacro = _getDailyMacronutrients();
    final mealCalories = _getMealTypeCalories();
    final totalCalories = _mealEntries.fold(0, (sum, entry) => sum + entry.calories);
    final hasData = _mealEntries.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilterButtons(),
            const SizedBox(height: 16),
            if (isDaily) _buildDateNavigation() else _buildDateDisplay(),
            if (isDaily) _buildDailyViewToggle(),
            if (!isDaily) _buildMetricSelector(),
            const SizedBox(height: 24),
            if (!hasData)
              _buildNoDataAvailable()
            else if (isDaily)
              _dailyViewType == 'macronutrients'
                  ? _buildPieChart(dailyMacro)
                  : _buildPieChart(mealCalories)
            else
              _buildNutritionChart(),
            const SizedBox(height: 24),
            if (hasData && isDaily) _buildDailySummary(totalCalories, dailyMacro),
            const SizedBox(height: 24),
            if (hasData && isDaily)
              isDaily
                ? _buildDailyDataTable()
                : _buildDataTable(),
            if (hasData && !isDaily)
              _buildDataTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataAvailable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'No data available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildDailyViewToggle() {
    return ToggleButtons(
      borderRadius: BorderRadius.circular(8),
      selectedColor: Colors.white,
      fillColor: Colors.green,
      constraints: const BoxConstraints(minHeight: 40),
      isSelected: [
        _dailyViewType == 'macronutrients',
        _dailyViewType == 'meals',
      ],
      onPressed: (index) {
        setState(() {
          _dailyViewType = ['macronutrients', 'meals'][index];
        });
      },
      children: const [
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Macronutrients')),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Meals')),
      ],
    );
  }

  Widget _buildDateDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_selectedFilter == 'monthly')
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigateMonth(-1),
          ),
        Text(
          _getDateRangeText(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        if (_selectedFilter == 'monthly')
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigateMonth(1),
          ),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: _filterButtonStyle('daily'),
            onPressed: () => _updateFilter('daily'),
            child: const Text('Daily'),
          ),
        ),
        Expanded(
          child: TextButton(
            style: _filterButtonStyle('latest'),
            onPressed: () => _updateFilter('latest'),
            child: const Text('Latest'),
          ),
        ),
        Expanded(
          child: TextButton(
            style: _filterButtonStyle('monthly'),
            onPressed: () => _updateFilter('monthly'),
            child: const Text('Monthly'),
          ),
        ),
        Expanded(
          child: TextButton(
            style: _filterButtonStyle('custom'),
            onPressed: () => _showCustomDatePicker(),
            child: const Text('Custom'),
          ),
        ),
      ],
    );
  }

  ButtonStyle _filterButtonStyle(String filter) {
    return TextButton.styleFrom(
      backgroundColor: _selectedFilter == filter ? Colors.green[100] : null,
      foregroundColor: _selectedFilter == filter ? Colors.green : Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildDateNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _navigateDay(-1),
        ),
        Text(
          DateFormat('MMMM dd, yyyy').format(_selectedDate),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _navigateDay(1),
        ),
      ],
    );
  }

  String _getDateRangeText() {
    switch (_selectedFilter) {
      case 'latest':
        return 'Last 7 Days';
      case 'monthly':
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case 'custom':
        return _customStartDate != null && _customEndDate != null
            ? '${DateFormat('MMM dd').format(_customStartDate!)} - ${DateFormat('MMM dd').format(_customEndDate!)}'
            : 'Select Date Range';
      default:
        return DateFormat('MMMM dd, yyyy').format(DateTime.now());
    }
  }

  Widget _buildMetricSelector() {
    return ToggleButtons(
      borderRadius: BorderRadius.circular(8),
      selectedColor: Colors.white,
      fillColor: Colors.green,
      constraints: const BoxConstraints(minHeight: 40),
      isSelected: [
        _selectedMetric == 'calories',
        _selectedMetric == 'macronutrients',
      ],
      onPressed: (index) {
        setState(() {
          _selectedMetric = ['calories', 'macronutrients'][index];
        });
      },
      children: const [
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Calories')),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Macronutrients')),
      ],
    );
  }

  Widget _buildPieChart(Map<String, double> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 300,
        child: SfCircularChart(
          series: <CircularSeries>[
            PieSeries<MapEntry<String, double>, String>(
              dataSource: data.entries.toList(),
              xValueMapper: (entry, _) => entry.key,
              yValueMapper: (entry, _) => entry.value,
              dataLabelSettings: const DataLabelSettings(
                isVisible: true,
                labelPosition: ChartDataLabelPosition.outside,
              ),
              pointColorMapper: (entry, _) => _getColor(entry.key),
            )
          ],
        ),
      ),
    );
  }

  Color _getColor(String key) {
    switch (key) {
      case 'Protein':
        return Colors.green;
      case 'Carbs':
        return Colors.orange;
      case 'Fats':
        return Colors.red;
      case 'Breakfast':
        return Colors.blue;
      case 'Lunch':
        return Colors.green;
      case 'Dinner':
        return Colors.orange;
      case 'Snack':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDailySummary(int calories, Map<String, double> macronutrients) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nutrition Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Calories', '${calories}kcal'),
              _buildSummaryItem('Protein', '${macronutrients['Protein']!.toStringAsFixed(1)}g'),
              _buildSummaryItem('Carbs', '${macronutrients['Carbs']!.toStringAsFixed(1)}g'),
              _buildSummaryItem('Fats', '${macronutrients['Fats']!.toStringAsFixed(1)}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildNutritionChart() {
    // Group entries by date and calculate totals
    final Map<DateTime, Map<String, dynamic>> dailyTotals = {};

    for (final entry in _mealEntries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (!dailyTotals.containsKey(date)) {
        dailyTotals[date] = {
          'calories': 0,
          'protein': 0.0,
          'carbs': 0.0,
          'fats': 0.0,
        };
      }

      dailyTotals[date]!['calories'] += entry.calories;
      dailyTotals[date]!['protein'] += entry.protein;
      dailyTotals[date]!['carbs'] += entry.carbs;
      dailyTotals[date]!['fats'] += entry.fats;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 300,
        child: SfCartesianChart(
          primaryXAxis: DateTimeAxis(
            dateFormat: DateFormat.MMMd(),
            intervalType: DateTimeIntervalType.days,
          ),
          series: _selectedMetric == 'calories'
              ? <CartesianSeries>[
                  LineSeries<MapEntry<DateTime, Map<String, dynamic>>, DateTime>(
                    dataSource: dailyTotals.entries.toList(),
                    xValueMapper: (entry, _) => entry.key,
                    yValueMapper: (entry, _) => entry.value['calories'],
                    name: 'Calories',
                    color: Colors.green,
                    markerSettings: const MarkerSettings(isVisible: true),
                  )
                ]
              : <CartesianSeries>[
                  LineSeries<MapEntry<DateTime, Map<String, dynamic>>, DateTime>(
                    dataSource: dailyTotals.entries.toList(),
                    xValueMapper: (entry, _) => entry.key,
                    yValueMapper: (entry, _) => entry.value['protein'],
                    name: 'Protein',
                    color: Colors.green,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                  LineSeries<MapEntry<DateTime, Map<String, dynamic>>, DateTime>(
                    dataSource: dailyTotals.entries.toList(),
                    xValueMapper: (entry, _) => entry.key,
                    yValueMapper: (entry, _) => entry.value['carbs'],
                    name: 'Carbs',
                    color: Colors.orange,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                  LineSeries<MapEntry<DateTime, Map<String, dynamic>>, DateTime>(
                    dataSource: dailyTotals.entries.toList(),
                    xValueMapper: (entry, _) => entry.key,
                    yValueMapper: (entry, _) => entry.value['fats'],
                    name: 'Fats',
                    color: Colors.red,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildDailyDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Meal Name')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Calories')),
          DataColumn(label: Text('Protein (g)')),
          DataColumn(label: Text('Carbs (g)')),
          DataColumn(label: Text('Fats (g)')),
        ],
        rows: _mealEntries.map((entry) => DataRow(
          cells: [
            DataCell(Text(entry.name)),
            DataCell(Text(entry.type)),
            DataCell(Text(entry.calories.toString())),
            DataCell(Text(entry.protein.toStringAsFixed(1))),
            DataCell(Text(entry.carbs.toStringAsFixed(1))),
            DataCell(Text(entry.fats.toStringAsFixed(1))),
          ],
        )).toList(),
      ),
    );
  }

Widget _buildDataTable() {
  // Group entries by date and calculate totals
  final Map<DateTime, Map<String, dynamic>> dailyTotals = {};

  for (final entry in _mealEntries) {
    final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
    if (!dailyTotals.containsKey(date)) {
      dailyTotals[date] = {
        'calories': 0,
        'protein': 0.0,
        'carbs': 0.0,
        'fats': 0.0,
      };
    }
    
    dailyTotals[date]!['calories'] += entry.calories;
    dailyTotals[date]!['protein'] += entry.protein;
    dailyTotals[date]!['carbs'] += entry.carbs;
    dailyTotals[date]!['fats'] += entry.fats;
  }

  // Convert to sorted list
  final sortedDates = dailyTotals.keys.toList()..sort((a, b) => b.compareTo(a));

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Total Calories')),
        DataColumn(label: Text('Total Protein (g)')),
        DataColumn(label: Text('Total Carbs (g)')),
        DataColumn(label: Text('Total Fats (g)')),
      ],
      rows: sortedDates.map((date) {
        final totals = dailyTotals[date]!;
        return DataRow(
          cells: [
            DataCell(Text(DateFormat('MMM dd, yyyy').format(date))),
            DataCell(Text(totals['calories'].toString())),
            DataCell(Text(totals['protein'].toStringAsFixed(1))),
            DataCell(Text(totals['carbs'].toStringAsFixed(1))),
            DataCell(Text(totals['fats'].toStringAsFixed(1))),
          ],
        );
      }).toList(),
    ),
  );
}

  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedFilter = 'custom';
      });
      _fetchNutritionData();
    }
  }

  void _updateFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'latest') {
        _selectedDate = DateTime.now();
      } else if (filter == 'monthly') {
        _selectedDate = DateTime.now();
      }
    });
    _fetchNutritionData();
  }
}

class MealEntry {
  final DateTime date;
  final String name;
  final String type;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;

  MealEntry({
    required this.date,
    required this.name,
    required this.type,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}