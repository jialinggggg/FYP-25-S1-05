import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../backend/controllers/fetch_body_stat_data_controller.dart';
import '../../../../backend/controllers/fetch_nutrition_data_controller.dart';
import '../../../../backend/entities/user_measurement.dart';

class DetailedReportScreen extends StatefulWidget {
  const DetailedReportScreen({
    super.key,
    required this.reportType,
  });

  final String reportType;

  @override
  State<DetailedReportScreen> createState() => _DetailedReportScreenState();
}

class _DetailedReportScreenState extends State<DetailedReportScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late FetchBodyStatDataController _bodyStatController;
  late FetchNutritionDataController _nutritionController;

  // --- Filters ---
  String _selectedFilter = 'latest';
  DateTime _selectedDate = DateTime.now();
  DateTime? _customStartDate, _customEndDate;

  // --- Body-stat metric ---
  late String _selectedMetric;

  // --- Nutrition nutrient dropdown ---
  final List<String> _availableNutrients = [
    'calories','protein','carbohydrates','fat','saturated fat',
    'cholesterol','sodium','potassium','calcium','iron',
    'vitamin a','vitamin c','vitamin d','fiber','sugar',
  ];
  late String _selectedNutrient;

  @override
  void initState() {
    super.initState();

    _selectedMetric   = "bmi";
    _selectedNutrient = _availableNutrients.first;

    _bodyStatController = FetchBodyStatDataController(
      supabaseClient: _supabase,
    )..addListener(() => setState(() {}));

    _nutritionController = FetchNutritionDataController(
      supabaseClient: _supabase,
    )..addListener(() => setState(() {}));

    _fetchData();
  }

  Future<void> _fetchData() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    if (widget.reportType == 'body stat') {
      // Body-stat: exactly as before
      if (_selectedFilter == 'custom' &&
          _customStartDate != null &&
          _customEndDate != null) {
        await _bodyStatController.fetchBodyStatDataByDateRange(
          uid, _customStartDate!, _customEndDate!,
        );
      } else if (_selectedFilter == 'monthly') {
        final start = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final end   = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
        await _bodyStatController.fetchBodyStatDataByDateRange(
          uid, start, end,
        );
      } else {
        // latest → last 30 days
        await _bodyStatController.fetchBodyStatDataByDateRange(
          uid,
          DateTime.now().subtract(const Duration(days: 30)),
          DateTime.now(),
        );
      }
    } else {
      // Nutrition: now supports Latest / Monthly / Custom ranges
      if (_selectedFilter == 'custom' &&
          _customStartDate != null &&
          _customEndDate != null) {
        await _nutritionController.fetchNutritionDataByDateRange(
          uid, _customStartDate!, _customEndDate!,
        );
      } else if (_selectedFilter == 'monthly') {
        final start = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final end   = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
        await _nutritionController.fetchNutritionDataByDateRange(
          uid, start, end,
        );
      } else {
        // latest → last 30 days
        await _nutritionController.fetchNutritionDataByDateRange(
          uid,
          DateTime.now().subtract(const Duration(days: 30)),
          DateTime.now(),
        );
      }
    }
  }

  @override
  void dispose() {
    _bodyStatController.removeListener(() {});
    _nutritionController.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBodyStat     = widget.reportType == 'body stat';
    final hasBodyData    = _bodyStatController.hasData;
    final hasNutrition   = _nutritionController.hasData;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBodyStat ? 'Body Stat Report' : 'Nutrition Report',
          style: const TextStyle(
            color: Colors.green,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilterButtons(),
            const SizedBox(height: 16),
            _buildDateDisplay(),
            const SizedBox(height: 24),
            if (isBodyStat)
              _buildMetricSelector()
            else
              _buildNutrientDropdown(),
            const SizedBox(height: 24),
            if (isBodyStat && !hasBodyData)
              _buildNoData('No body stat data available')
            else if (!isBodyStat && !hasNutrition)
              _buildNoData('No nutrition data available')
            else
              _buildChart(),
            const SizedBox(height: 24),
            if (isBodyStat && hasBodyData)
              _buildBodyStatTable()
            else if (!isBodyStat && hasNutrition)
              _buildNutritionTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Row(
      children: ['latest','monthly','custom'].map((filter) {
        final label =
            '${filter[0].toUpperCase()}${filter.substring(1)}';
        return Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: _selectedFilter == filter
                  ? Colors.green[100]
                  : null,
              foregroundColor: _selectedFilter == filter
                  ? Colors.green
                  : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (filter == 'custom') {
                _showCustomDatePicker();
              } else {
                setState(() {
                  _selectedFilter = filter;
                  if (filter != 'custom') {
                    _selectedDate = DateTime.now();
                  }
                });
                _fetchData();
              }
            },
            child: Text(label),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateDisplay() {
    if (_selectedFilter == 'monthly') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigateMonth(-1),
          ),
          Text(
            _getDateRangeText(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigateMonth(1),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        _getDateRangeText(),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildMetricSelector() {
    final metrics = ['bmi','weight','height'];
    return ToggleButtons(
      borderRadius: BorderRadius.circular(8),
      selectedColor: Colors.white,
      fillColor: Colors.green,
      constraints: const BoxConstraints(minHeight: 40),
      isSelected: metrics.map((m) => m == _selectedMetric).toList(),
      onPressed: (i) => setState(() => _selectedMetric = metrics[i]),
      children: metrics
          .map((m) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(m.toUpperCase()),
              ))
          .toList(),
    );
  }

  Widget _buildNutrientDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedNutrient,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        filled: true,
        fillColor: Colors.green[50],
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
      ),
      icon: Icon(Icons.arrow_drop_down, color: Colors.green),
      style: TextStyle(color: Colors.green.shade900, fontSize: 16),
      isExpanded: true,
      items: _availableNutrients.map((nutrient) {
        final label = '${nutrient[0].toUpperCase()}${nutrient.substring(1)}';
        return DropdownMenuItem(
          value: nutrient,
          child: Text(label, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedNutrient = val);
      },
    );
  }



  Widget _buildChart() {
    if (widget.reportType == 'body stat') {
      // ——— Body-stat line chart ———
      final data = List<UserMeasurement>.from(_bodyStatController.healthData)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (data.isEmpty) return const SizedBox.shrink();

      DateTime minX, maxX;
      if (_selectedFilter == 'latest') {
        final slice = data.length > 7 ? data.sublist(data.length - 7) : data;
        minX = slice.first.createdAt;
        maxX = slice.last.createdAt;
      } else if (_selectedFilter == 'monthly') {
        minX = DateTime(_selectedDate.year, _selectedDate.month, 1);
        maxX = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23,59,59);
      } else if (_selectedFilter == 'custom' &&
                 _customStartDate != null &&
                 _customEndDate != null) {
        minX = _customStartDate!;
        maxX = DateTime(_customEndDate!.year, _customEndDate!.month,
                         _customEndDate!.day, 23, 59, 59);
      } else {
        minX = data.first.createdAt;
        maxX = data.last.createdAt;
      }

      return SizedBox(
        height: 300,
        child: SfCartesianChart(
          key: ValueKey(_selectedMetric),
          primaryXAxis: DateTimeAxis(
            dateFormat: DateFormat.MMMd(),
            intervalType: DateTimeIntervalType.days,
            minimum: minX,
            maximum: maxX,
            title: AxisTitle(text: 'Date'),
          ),
          primaryYAxis: NumericAxis(
            title: AxisTitle(text: _selectedMetric.toUpperCase()),
          ),
          series: <CartesianSeries>[
            LineSeries<UserMeasurement, DateTime>(
              dataSource: data,
              xValueMapper: (d, _) => d.createdAt,
              yValueMapper: (d, _) {
                switch (_selectedMetric) {
                  case 'weight':
                    return d.weight;
                  case 'height':
                    return d.height;
                  default:
                    return d.bmi;
                }
              },
              name: _selectedMetric.toUpperCase(),
              markerSettings: const MarkerSettings(isVisible: true),
              color: Colors.green,
            ),
          ],
        ),
      );
    } else {
      // ——— Nutrition line chart ———
      final data = _nutritionController.dailyData;
      if (data.isEmpty) return const SizedBox.shrink();

      DateTime minX, maxX;
      if (_selectedFilter == 'latest') {
        final slice = data.length > 7 ? data.sublist(data.length - 7) : data;
        minX = slice.first.date;
        maxX = slice.last.date;
      } else if (_selectedFilter == 'monthly') {
        minX = DateTime(_selectedDate.year, _selectedDate.month, 1);
        maxX = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23,59,59);
      } else if (_selectedFilter == 'custom' &&
                 _customStartDate != null &&
                 _customEndDate != null) {
        minX = _customStartDate!;
        maxX = DateTime(_customEndDate!.year, _customEndDate!.month,
                         _customEndDate!.day, 23,59,59);
      } else {
        minX = data.first.date;
        maxX = data.last.date;
      }

      return SizedBox(
        height: 300,
        child: SfCartesianChart(
          key: ValueKey(_selectedNutrient), 
          primaryXAxis: DateTimeAxis(
            dateFormat: DateFormat.MMMd(),
            intervalType: DateTimeIntervalType.days,
            minimum: minX,
            maximum: maxX,
            title: AxisTitle(text: 'Date'),
          ),
          primaryYAxis: NumericAxis(
            title: AxisTitle(text: _selectedNutrient.toUpperCase()),
          ),
          series: <CartesianSeries>[
            LineSeries<DailyNutrition, DateTime>(
              dataSource: data,
              xValueMapper: (d, _) => d.date,
              yValueMapper: (d, _) => d.totals[_selectedNutrient] ?? 0,
              name: _selectedNutrient.toUpperCase(),
              markerSettings: const MarkerSettings(isVisible: true),
              color: Colors.green,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBodyStatTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('BMI')),
          DataColumn(label: Text('Weight (kg)')),
          DataColumn(label: Text('Height (cm)')),
        ],
        rows: _bodyStatController.healthData.map((d) {
          final label = _bmiCategoryLabel(d.bmi);
          final color = _bmiCategoryColor(d.bmi);
          return DataRow(cells: [
            DataCell(Text(DateFormat('MMM dd, yyyy').format(d.createdAt))),
            DataCell(
              Chip(
                label: Text(label),
                backgroundColor: color.withAlpha(50),
                labelStyle: TextStyle(color: color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
            DataCell(Text(d.bmi.toStringAsFixed(1))),
            DataCell(Text(d.weight.toStringAsFixed(1))),
            DataCell(Text(d.height.toStringAsFixed(1))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildNutritionTable() {
    // Prepare your column headers: Date + each nutrient name
    final columns = <DataColumn>[
      const DataColumn(label: Text('Date')),
      for (var n in _availableNutrients)
        DataColumn(label: Text(
          '${n[0].toUpperCase()}${n.substring(1)}',
          overflow: TextOverflow.ellipsis,
        )),
    ];

    // Build one DataRow per day
    final rows = _nutritionController.dailyData.map((d) {
      // First cell is the formatted date
      final cells = <DataCell>[
        DataCell(Text(DateFormat('MMM dd, yyyy').format(d.date))),
      ];
      // Then one cell per nutrient, formatted to 1 decimal
      cells.addAll(_availableNutrients.map((n) {
        final val = d.totals[n] ?? 0;
        return DataCell(Text(val.toStringAsFixed(1)));
      }));
      return DataRow(cells: cells);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: rows,
        columnSpacing: 24,
        horizontalMargin: 12,
      ),
    );
  }

  Widget _buildNoData(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedFilter   = 'custom';
        _customStartDate  = picked.start;
        _customEndDate    = picked.end;
      });
      _fetchData();
    }
  }

  String _getDateRangeText() {
    switch (_selectedFilter) {
      case 'latest':
        return 'Last 7 Records';
      case 'monthly':
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          return '${DateFormat('MMM dd').format(_customStartDate!)} - '
                 '${DateFormat('MMM dd').format(_customEndDate!)}';
        }
        return 'Select Date Range';
      default:
        return '';
    }
  }

  String _bmiCategoryLabel(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25)   return 'Normal';
    if (bmi < 30)   return 'Overweight';
    if (bmi < 35)   return 'Obese';
                     return 'Extremely Obese';
  }

  Color _bmiCategoryColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25)   return Colors.green;
    if (bmi < 30)   return Colors.orange;
    if (bmi < 40)   return Colors.red;
                     return Colors.red[900]!;
  }

  void _navigateMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + delta,
        1,
      );
    });
    _fetchData();
  }
}
