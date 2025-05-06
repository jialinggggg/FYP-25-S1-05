import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_measurement.dart';

class LogDailyWeightController extends ChangeNotifier {
  final SupabaseClient supabaseClient;

  bool _isWeightLogged = false;
  bool get isWeightLogged => _isWeightLogged;

  double? _latestWeight;
  double? get latestWeight => _latestWeight;

  LogDailyWeightController({required this.supabaseClient});

  /// Try to load the measurement for [date]; if none exists, fall back
  /// to the most-recent ever logged measurement.
  Future<void> fetchWeightForDate(String uid, DateTime date) async {
    try {
      // 1) look for an entry on that date
      final startOfDay = DateTime.utc(date.year, date.month, date.day);
      final endOfDay   = startOfDay.add(const Duration(days: 1));

      final dayResponse = await supabaseClient
        .from('user_measurements')
        .select()
        .eq('uid', uid)
        .gte('created_at', startOfDay.toIso8601String())
        .lt ('created_at', endOfDay  .toIso8601String())
        .limit(1);

      if (dayResponse.isNotEmpty) {
        // Got one for the selected date
        final m = UserMeasurement.fromMap(dayResponse[0]);
        _latestWeight   = m.weight;
        _isWeightLogged = true;
      } else {
        // No entry for that date → mark false and fall back to latest ever
        _isWeightLogged = false;

        final everResponse = await supabaseClient
          .from('user_measurements')
          .select()
          .eq('uid', uid)
          .order('created_at', ascending: false)
          .limit(1);

        if (everResponse.isNotEmpty) {
          final m = UserMeasurement.fromMap(everResponse[0]);
          _latestWeight = m.weight;
        } else {
          _latestWeight = null;
        }
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch weight for $date: $e');
    }
  }

  /// Inserts or updates the weight for [date], stamping created_at accordingly,
  /// then re-fetches via fetchWeightForDate to refresh state.
  Future<void> logWeightForDate(String uid, double weight, DateTime date) async {
    try {
      // load height to compute BMI
      final profile = await supabaseClient
        .from('user_profiles')
        .select('height')
        .eq('uid', uid)
        .maybeSingle();

      if (profile == null || profile['height'] == null) {
        throw Exception('User profile not found or height is null');
      }
      final height = (profile['height'] as num).toDouble();
      final bmi    = weight / ((height / 100) * (height / 100));

      // check existing entry on that date
      final startOfDay = DateTime.utc(date.year, date.month, date.day);
      final endOfDay   = startOfDay.add(const Duration(days: 1));
      final existing = await supabaseClient
        .from('user_measurements')
        .select('measurement_id')
        .eq('uid', uid)
        .gte('created_at', startOfDay.toIso8601String())
        .lt ('created_at', endOfDay  .toIso8601String())
        .limit(1);

      final payload = {
        'uid':        uid,
        'weight':     weight,
        'height':     height,
        'bmi':        bmi,
        'created_at': date.toIso8601String(),
      };

      if (existing.isNotEmpty) {
        // update the existing record
        final id = existing[0]['measurement_id'];
        await supabaseClient
          .from('user_measurements')
          .update(payload)
          .eq('measurement_id', id);
      } else {
        // insert new
        await supabaseClient
          .from('user_measurements')
          .insert(payload);
      }

      // refresh (so UI sees isWeightLogged = true for that date)
      await fetchWeightForDate(uid, date);
    } catch (e) {
      throw Exception('Failed to log weight for $date: $e');
    }
  }
}
