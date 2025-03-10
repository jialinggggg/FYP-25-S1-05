import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key});

  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String _selectedFilter = 'latest';
  String _selectedMetric = 'bmi';
  DateTime _selectedDate = DateTime.now();
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  List<HealthData> _healthData = [];

  @override
  void initState() {
    super.initState();
    _fetchHealthData();
  }

  Future<void> _fetchHealthData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('user_measurements')
          .select('weight, height, bmi, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _healthData = response.map((entry) {
        return HealthData(
          date: DateTime.parse(entry['created_at'] as String),
          weight: (entry['weight'] as num).toDouble(),
          height: (entry['height'] as num).toDouble(),
          bmi: (entry['bmi'] as num).toDouble(),
        );
      }).toList();

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  List<HealthData> get _filteredData {
    switch (_selectedFilter) {
      case 'latest':
        return _healthData.take(7).toList();
      case 'monthly':
        return _healthData.where((data) =>
            data.date.month == _selectedDate.month &&
            data.date.year == _selectedDate.year).toList();
      case 'custom':
        return _healthData.where((data) =>
            (_customStartDate?.isBefore(data.date) ?? true) &&
            (_customEndDate?.isAfter(data.date) ?? true)).toList();
      default:
        return _healthData;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _filteredData.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Reports'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilterButtons(),
            const SizedBox(height: 16),
            _buildDateDisplay(),
            const SizedBox(height: 24),
            _buildMetricSelector(),
            const SizedBox(height: 24),
            if (!hasData)
              _buildNoDataAvailable()
            else
              _buildLineChart(),
            const SizedBox(height: 24),
            if (!hasData)
              const SizedBox.shrink()
            else
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

  Widget _buildFilterButtons() {
    return Row(
      children: [
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

  void _navigateMonth(int months) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + months, 1);
    });
  }

  String _getDateRangeText() {
    switch (_selectedFilter) {
      case 'latest':
        return 'Last 7 Records';
      case 'monthly':
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case 'custom':
        return _customStartDate != null && _customEndDate != null
            ? '${DateFormat('MMM dd').format(_customStartDate!)} - ${DateFormat('MMM dd').format(_customEndDate!)}'
            : 'Select Date Range';
      default:
        return '';
    }
  }

  Widget _buildMetricSelector() {
  return ToggleButtons(
    borderRadius: BorderRadius.circular(8),
    selectedColor: Colors.white,
    fillColor: Colors.green,
    constraints: const BoxConstraints(minHeight: 40),
    isSelected: [
      _selectedMetric == 'bmi',
      _selectedMetric == 'weight',
      _selectedMetric == 'height',
    ],
    onPressed: (index) {
      setState(() {
        _selectedMetric = ['bmi', 'weight', 'height'][index];
      });
    },
    children: const [
      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('BMI')),
      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Weight')),
      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Height')),
    ],
  );
}


Widget _buildLineChart() {
  // Create a copy of the filtered data and sort it
  final sortedData = List<HealthData>.from(_filteredData)
    ..sort((a, b) => a.date.compareTo(b.date));


  return SizedBox(
    height: 300,
    child: SfCartesianChart(
      key: ValueKey(_selectedMetric), // Force rebuild on metric change
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat.MMMd(),
        intervalType: DateTimeIntervalType.days,
        title: AxisTitle(text: 'Date'),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: _selectedMetric.toUpperCase()),
      ),
      series: <CartesianSeries>[
        LineSeries<HealthData, DateTime>(
          dataSource: sortedData,
          xValueMapper: (HealthData data, _) => data.date,
          yValueMapper: (HealthData data, _) => _getMetricValue(data),
          name: _selectedMetric,
          color: Colors.green,
          markerSettings: const MarkerSettings(isVisible: true),
        )
      ],
    ),
  );
}

  double _getMetricValue(HealthData data) {
    switch (_selectedMetric) {
      case 'bmi':
        return data.bmi;
      case 'weight':
        return data.weight;
      case 'height':
        return data.height;
      default:
        return 0;
    }
  }

   Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('BMI')),
          DataColumn(label: Text('Weight (kg)')),
          DataColumn(label: Text('Height (cm)')),
        ],
        rows: _filteredData.map((data) => DataRow(
          cells: [
            DataCell(Text(DateFormat('MMM dd, yyyy').format(data.date))),
            DataCell(Text(data.bmi.toStringAsFixed(1))),
            DataCell(Text(data.weight.toStringAsFixed(1))),
            DataCell(Text(data.height.toStringAsFixed(1))),
          ],
        )).toList(),
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
        _selectedFilter = 'custom';
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
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
  }
}

class HealthData {
  final DateTime date;
  final double weight;
  final double height;
  final double bmi;

  HealthData({
    required this.date,
    required this.weight,
    required this.height,
    required this.bmi,
  });
}