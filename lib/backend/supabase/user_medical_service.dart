import 'package:supabase_flutter/supabase_flutter.dart';


class UserMedicalService {
  final SupabaseClient _supabase;

  // Constructor to initialize Supabase client
  UserMedicalService(this._supabase);

  // Method to insert a new medical profile
  Future<void> insertMedical({
    required String uid,
    required String preExisting,
    required String allergies,
  }) async {
    try {
      // Validate inputs
      if (uid.isEmpty || preExisting.isEmpty || allergies.isEmpty) {
        throw Exception('Invalid input: All fields are required.');
      }

      // Insert the new medical profile into the 'user_medical_info' table
      await _supabase.from('user_medical_info').insert({
        'uid': uid,
        'pre_existing': preExisting,
        'allergies': allergies,
      });
    } catch (error) {
      throw Exception('Unable to insert profile: $error');
    }
  }

  // Method to fetch a user medical info by UID
  Future<Map<String, dynamic>?> fetchMedical(String uid) async {
    try {
      // Validate UID
      if (uid.isEmpty) {
        throw Exception('UID is required.');
      }

      // Fetch from the database
      final response = await _supabase
          .from('user_medical_info')
          .select()
          .eq('uid', uid)
          .single();

      return response;
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  // Method to update a medical profile
  Future<void> updateMedical({
    required String uid,
    required String preExisting,
    required String allergies,
  }) async {
    try {
      // Validate inputs
      if (uid.isEmpty || preExisting.isEmpty || allergies.isEmpty) {
        throw Exception('All fields are required.');
      }

      // Update the database
      await _supabase.from('user_medical_info').update({
        'pre_existing': preExisting,
        'allergies': allergies,
      }).eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Method to delete a medical profile
  Future<void> deleteMedical({
    required String uid,
  }) async {
    try {
      // Validate UID
      if (uid.isEmpty) {
        throw Exception('UID is required.');
      }

      // Delete from the database
      await _supabase.from('user_medical_info').delete().eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }
}