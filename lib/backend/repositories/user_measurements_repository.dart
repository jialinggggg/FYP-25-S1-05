import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_measurement.dart';
import 'user_profiles_repository.dart';

class UserMeasurementsRepository {
  final SupabaseClient _supabase;
  final UserProfilesRepository _userProfilesService;

  UserMeasurementsRepository(this._supabase, this._userProfilesService);

  Future<UserMeasurement> insertMeasurement({
    required String uid,
    required double weight,
  }) async {
    try {
      final profile = await _userProfilesService.fetchProfile(uid);
      if (profile == null) throw Exception('User profile not found');

      final measurementData = {
        'uid': uid,
        'weight': weight,
        'height': profile.height,
        'bmi': weight / ((profile.height / 100) * (profile.height / 100)),
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
        .from('user_measurements')
        .insert(measurementData)
        .select()
        .single();
      
      return UserMeasurement.fromMap(response);
    } catch (error) {
      throw Exception('Unable to insert measurement: $error');
    }
  }

  Future<UserMeasurement?> fetchLatestMeasurement(String uid) async {
    try {
      final response = await _supabase
          .from('user_measurements')
          .select()
          .eq('uid', uid)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return UserMeasurement.fromMap(response.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching latest measurement: $e');
    }
  }

  Future<void> updateMeasurement(UserMeasurement measurement) async {
    try {
      final profile = await _userProfilesService.fetchProfile(measurement.uid);
      if (profile == null) throw Exception('User profile not found');

      final updatedMeasurement = measurement.copyWith(
        height: profile.height,
        bmi: measurement.weight / ((profile.height / 100) * (profile.height / 100)),
      );

      await _supabase.from('user_measurements')
          .update(updatedMeasurement.toMap())
          .eq('measurement_id', measurement.measurementId);
    } catch (e) {
      throw Exception('Error updating measurement: $e');
    }
  }
}