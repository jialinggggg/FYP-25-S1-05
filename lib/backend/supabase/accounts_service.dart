import 'package:supabase_flutter/supabase_flutter.dart';


class AccountService {
  final SupabaseClient _supabase;

  // Constructor to initialize Supabase client
  AccountService(this._supabase);

  // Method to insert a new account
  Future<void> insertAccount({
    required String uid,
    required String email,
    required String type,
    required String status,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || type.isEmpty || status.isEmpty) {
        throw Exception('Invalid input: All fields are required.');
      }

      // Insert the new account into the 'accounts' table
      await _supabase.from('accounts').insert({
        'uid': uid,
        'email': email,
        'type': type,
        'status': status,
      });
    } catch (error) {
      throw Exception('Unable to insert account: $error');
    }
  }

  // Method to fetch an account by UID
  Future<Map<String, dynamic>?> fetchAccount(String uid) async {
    try {
      // Validate UID
      if (uid.isEmpty) {
        throw Exception('UID is required.');
      }

      // Fetch from the database
      final response = await _supabase
          .from('accounts')
          .select()
          .eq('uid', uid)
          .single();

      return response;
    } catch (e) {
      throw Exception('Error fetching account: $e');
    }
  }

  // Method to update an account (only for the logged-in user or admin)
  Future<void> updateAccount({
    required String uid,
    required String email,
    required String type,
    required String status,
  }) async {
    try {
      // Validate inputs
      if (uid.isEmpty || email.isEmpty || type.isEmpty || status.isEmpty) {
        throw Exception('All fields are required.');
      }

      // Update the database
      await _supabase.from('accounts').update({
        'email': email,
        'type': type,
        'status': status,
      }).eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to update account: $e');
    }
  }

  // Method to delete an account (only for the logged-in user or admin)
  Future<void> deleteAccount({
    required String uid,
  }) async {
    try {
      // Validate UID
      if (uid.isEmpty) {
        throw Exception('UID is required.');
      }

      // Delete from the database
      await _supabase.from('accounts').delete().eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}