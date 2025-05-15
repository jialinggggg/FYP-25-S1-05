import 'package:supabase_flutter/supabase_flutter.dart';

class LoginController {
  final SupabaseClient client;

  LoginController({required this.client});

  /// Login and check if user is an admin
  Future<bool> loginAsAdmin(String email, String password) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception("Invalid credentials");
    }

    final account = await client
        .from('accounts')
        .select('type')
        .eq('uid', user.id)
        .maybeSingle();

    if (account == null || account['type'] != 'admin') {
      await client.auth.signOut();
      throw Exception("Unauthorized: Only admins can log in");
    }

    return true;
  }

  Future<void> logout() async {
    await client.auth.signOut();
  }
}
