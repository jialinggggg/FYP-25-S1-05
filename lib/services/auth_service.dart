import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;

  // Initialize _supabase in the constructor
  AuthService() : _supabase = Supabase.instance.client;

  // Function to log in a user and fetch their role and status
  Future<Map<String, String>> login(String email, String password) async {
    try {
      // Sign in with email and password
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed: User not found');
      }

      // Fetch user role and status from the "user_roles" table
      final userRoleResponse = await _supabase
          .from('accounts')
          .select('type, status')
          .eq('email', email)
          .single();

      // Return the user's role and status
      return {
        'type': userRoleResponse['type'] as String,
        'status': userRoleResponse['status'] as String,
      };
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Function to check if a user is logged in
  Future<bool> isLoggedIn() async {
    final session = _supabase.auth.currentSession;
    return session != null;
  }

  // Function to log out a user
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}