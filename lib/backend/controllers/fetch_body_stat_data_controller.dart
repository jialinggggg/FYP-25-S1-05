import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // Import ChangeNotifier
import '../entities/user_measurement.dart';

class FetchBodyStatDataController extends ChangeNotifier {
  final SupabaseClient supabaseClient;

  double? _bmi;
  DateTime? _createdAt;
  String? _error;
  List<UserMeasurement> _healthData = [];

  // Getters for the properties
  double? get bmi => _bmi;
  DateTime? get createdAt => _createdAt;
  String? get error => _error;
  List<UserMeasurement> get healthData => _healthData;

  FetchBodyStatDataController({required this.supabaseClient});

  // Fetch the latest body stat data (bmi, created_at)
  Future<void> fetchLatestBodyStatData(String userId) async {
    try {
      final response = await supabaseClient
          .from('user_measurements')
          .select('bmi, created_at')
          .eq('uid', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final createdAtString = response[0]['created_at'] as String;
        final createdAtUtc = DateTime.parse(createdAtString).toUtc();
        final createdAtLocal = createdAtUtc.toLocal();

        _bmi = (response[0]['bmi'] as num).toDouble();
        _createdAt = createdAtLocal;
        _error = null;  // Clear error in case of successful fetch
      } else {
        _error = 'No body stat data found';
      }
      notifyListeners();  // Notify listeners about the data change
    } catch (e) {
      _error = 'Error fetching body stat data: $e';
      notifyListeners();  // Notify listeners in case of an error
    }
  }

  // Fetch body stat data based on user dates (e.g., month or custom range)
  Future<void> fetchBodyStatDataByDateRange(String uid, DateTime startDate, DateTime endDate) async {
    try {
      final response = await supabaseClient
          .from('user_measurements')
          .select()
          .eq('uid', uid)
          .gte('created_at', startDate.toUtc().toIso8601String())
          .lte('created_at', endDate.toUtc().toIso8601String())
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        // Map response to UserMeasurement without modifying the UserMeasurement class
        _healthData = response.map<UserMeasurement>((entry) {
          // Return UserMeasurement object using the current data
          return UserMeasurement.fromMap(entry);
        }).toList();
        _error = null;  // Clear error in case of successful fetch
      } else {
        _error = 'No body stat data found in this range';
      }
      notifyListeners();  // Notify listeners about the data change
    } catch (e) {
      _error = 'Error fetching body stat data: $e';
      notifyListeners();  // Notify listeners in case of an error
    }
  }

  // Helper method to check if there is data available
  bool get hasData => _healthData.isNotEmpty || (_bmi != null && _createdAt != null);
}
