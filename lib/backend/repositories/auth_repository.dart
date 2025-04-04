// services/auth_users_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('User registration failed');
      }
      
      return response;
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    try {
      await _supabase.auth.signInWithOtp(email: email);
      return true;
    } catch (e) {
      if (e.toString().contains('User not found')) {
        return false;
      }
      throw Exception('Email check failed: ${e.toString()}');
    }
  }

  Future<Session?> getCurrentSession() async {
    return _supabase.auth.currentSession;
  }
}