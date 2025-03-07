import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Function to log in a user
  Future<void> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed: User not found');
      }
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