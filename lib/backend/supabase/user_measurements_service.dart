import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_profiles_service.dart';

class UserMeasurementService {
  final SupabaseClient _supabase;
  final UserProfilesService _userProfilesService;

  // Constructor to initialize Supabase client and UserProfilesService
  UserMeasurementService(this._supabase, this._userProfilesService);

  Future<void> insertMeasurement({
  required String uid,
  required double weight,
}) async {
  try {
    // Validate inputs
    if (uid.isEmpty) {
      throw Exception('UID is required.');
    }
    if (weight <= 0) {
      throw Exception('Invalid input: Weight must be a positive value.');
    }

    // Fetch the user's profile to get the height
    final profile = await _userProfilesService.fetchProfile(uid);
    if (profile == null || profile['height'] == null) {
      throw Exception('User profile or height not found.');
    }

    final height = profile['height'];

    // Insert the new measurement into the 'user_measurements' table
    await _supabase.from('user_measurements').insert({
      'uid': uid,
      'weight': weight,
      'height': height,
      'bmi': weight / ((height / 100) * (height / 100)),
    });
  } catch (error) {
    throw Exception('Unable to insert measurement: $error');
  }
}

  // Method to fetch the latest measurement of the authenticated user
  Future<Map<String, dynamic>?> fetchLatestMeasurement(String uid) async {
    try {
      final response = await _supabase
          .from('user_measurements')
          .select()
          .eq('uid', uid)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first;
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching latest measurement: $e');
    }
  }

  // Method to update a measurement
  Future<void> updateMeasurement({
    required String measurementId,
    required double weight,
  }) async {
    try {
      // Fetch the user's profile to get the height
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('User not authenticated.');
      }

      final profile = await _userProfilesService.fetchProfile(uid);
      if (profile == null || profile['height'] == null) {
        throw Exception('User profile or height not found.');
      }

      final height = profile['height'];

      // Update the measurement in the 'user_measurements' table
      await _supabase.from('user_measurements').update({
        'weight': weight,
        'height': height,
        'bmi': weight / ((height / 100) * (height / 100)),
      }).eq('measurement_id', measurementId);
    } catch (e) {
      throw Exception('Error updating measurement: $e');
    }
  }
}