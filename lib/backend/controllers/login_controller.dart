// lib/backend/controllers/login_controller.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/account.dart';

class LoginController {
  final SupabaseClient _supabase;

  LoginController(this._supabase);

  /// Sign in with email & password, then fetch and map the
  /// corresponding `accounts` row into an Account.
  Future<Account> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) {
        throw Exception('Authentication failed.');
      }

      // Query the accounts table for type & status
      final data = await _supabase
          .from('accounts')
          .select('uid, email, type, status')
          .eq('uid', user.id)
          .single();

      // `data` is a Map<String, dynamic>
      return Account.fromMap(data);
    } on AuthException catch (e) {
      // Supabase auth errors (invalid credentials, etc.)
      throw Exception(e.message);
    } on PostgrestException catch (e) {
      // Database-level errors
      throw Exception(e.message);
    } catch (e) {
      // Fallback
      throw Exception('Login error: $e');
    }
  }
}
