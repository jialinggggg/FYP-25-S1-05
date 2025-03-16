import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessProfilesService {
  final SupabaseClient _supabase;

  // Constructor to initialize Supabase client
  BusinessProfilesService(this._supabase);

  // Method to insert a new business profile
  Future<void> insertBizProfile({
    required String uid,
    required String name,
    required String registration,
    required String country,
    required String address,
    required String type,
    required String description,
  }) async {
    try {
      // Validate inputs
      if (uid.isEmpty || name.isEmpty || country.isEmpty || registration.isEmpty
          || address.isEmpty || type.isEmpty || description.isEmpty) {
        throw Exception('Invalid input: All fields are required.');
      }


      // Insert the new profile into the 'business_profiles' table
      await _supabase.from('business_profiles').insert({
        'uid': uid,
        'name': name,
        'country': country,
        'registration_no': registration,
        'address': address,
        'type': type,
        'description': description,
      });
    } catch (error) {
      throw Exception('Unable to insert profile: $error');
    }
  }

  // Method to fetch a business profile by UID
  Future<Map<String, dynamic>?> fetchBizProfile(String uid) async {
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

  // Method to update a business profile (only for the logged-in user or admin)
  Future<void> updateBizProfile({
    required String uid,
    required String name,
    required String registration,
    required String country,
    required String address,
    required String type,
    required String description,
  }) async {
    try {
      // Validate inputs
      if (uid.isEmpty || name.isEmpty || country.isEmpty || registration.isEmpty
          || address.isEmpty || type.isEmpty || description.isEmpty) {
        throw Exception('Invalid input: All fields are required.');
      }

      // Update the database
      await _supabase.from('business_profiles').update({
        'uid': uid,
        'name': name,
        'country': country,
        'registration_no': registration,
        'address': address,
        'type': type,
        'description': description,
      }).eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Method to delete a business profile (only for the logged-in user or admin)
  Future<void> deleteProfile({
    required String uid,
  }) async {
    try {
      // Validate UID
      if (uid.isEmpty) {
        throw Exception('UID is required.');
      }

      // Delete from the database
      await _supabase.from('business_profiles').delete().eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }
}
