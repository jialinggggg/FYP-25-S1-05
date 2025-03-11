import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfilesService {
  final SupabaseClient _supabase;

  // Constructor to initialize Supabase client
  UserProfilesService(this._supabase);

  // Method to insert a new user profile
  Future<void> insertProfile({
    required String uid,
    required String name,
    required String country,
    required String gender,
    required DateTime birthdate,
    required double weight,
    required double height,
  }) async {
    try {
      // Validate inputs
      if (uid.isEmpty || name.isEmpty || country.isEmpty || gender.isEmpty) {
        throw Exception('Invalid input: All fields are required.');
      }
      if (weight <= 0 || height <= 0) {
        throw Exception('Invalid input: Weight and height must be positive values.');
      }

      // Insert the new profile into the 'user_profiles' table
      await _supabase.from('user_profiles').insert({
        'uid': uid,
        'name': name,
        'country': country,
        'gender': gender,
        'birth_date': birthdate.toIso8601String(), // Convert DateTime to ISO 8601 string
        'weight': weight,
        'height': height,
      });
    } catch (error) {
      throw Exception('Unable to insert profile: $error');
    }
  }

  // Method to fetch a user profile by UID
  Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    try {
      // Validate UID
      if (uid.isEmpty) {
        throw Exception('UID is required.');
      }

      // Fetch from the database
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('uid', uid)
          .single();

      return response;
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  // Method to update a user profile (only for the logged-in user or admin)
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String country,
    required String gender,
    required DateTime birthdate,
    required double weight,
    required double height,
  }) async {
    try {
      // Validate inputs
      if (uid.isEmpty || name.isEmpty || country.isEmpty || gender.isEmpty) {
        throw Exception('All fields are required.');
      }
      if (weight <= 0 || height <= 0) {
        throw Exception('Invalid input: Weight and height must be positive values.');
      }

      // Update the database
      await _supabase.from('user_profiles').update({
        'name': name,
        'country': country,
        'gender': gender,
        'birth_date': birthdate.toIso8601String(), // Convert DateTime to ISO 8601 string
        'weight': weight,
        'height': height,
      }).eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Method to delete a user profile (only for the logged-in user or admin)
  Future<void> deleteProfile({
    required String uid,
  }) async {
    try {
      // Validate UID
      if (uid.isEmpty) {
        throw Exception('UID is required.');
      }

      // Delete from the database
      await _supabase.from('user_profiles').delete().eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }
}
