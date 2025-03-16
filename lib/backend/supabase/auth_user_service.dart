import 'package:supabase_flutter/supabase_flutter.dart';

class AuthUsersService {
  final SupabaseClient _supabase;

  // Constructor to initialize Supabase client
  AuthUsersService(this._supabase);

  // Method to sign up a new user (insert into auth.users)
  Future<String> signUp({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Invalid input: Email and password are required.');
      }

      // Sign up the user (this automatically inserts into auth.users)
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      // Return the UID (id) of the newly created user
      return response.user?.id ?? '';
  } on AuthException catch (e) {
    // Re-throw with original error message
    throw AuthException(e.message);
  } catch (e) {
    throw Exception('Signup failed: $e');
  }
}

  // Method to fetch the current authenticated user's UID
  Future<String?> fetchCurrentUserId() async {
    try {
      // Get the current authenticated user
      final user = _supabase.auth.currentUser;

      // Return the UID (id) of the user
      return user?.id;
    } catch (e) {
      throw Exception('Error fetching current user ID: $e');
    }
  }

  // Method to fetch user data by UID
  Future<Map<String, dynamic>?> fetchUser(String uid) async {
    try {
      // Validate UID
      if (uid.isEmpty) {
        throw Exception('UID is required.');
      }

      // Fetch from the auth.users table
      final response = await _supabase
          .from('auth.users')
          .select()
          .eq('id', uid)
          .single();

      return response;
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  // Method to update user email (only for the logged-in user or admin)
  Future<void> updateUserEmail({
    required String uid,
    required String newEmail,
  }) async {
    try {
      // Validate inputs
      if (uid.isEmpty || newEmail.isEmpty) {
        throw Exception('All fields are required.');
      }

      // Update the user's email in auth.users
      await _supabase.auth.updateUser(
        UserAttributes(email: newEmail),
      );
    } catch (e) {
      throw Exception('Failed to update user email: $e');
    }
  }

  // Method to delete a user (only for the logged-in user or admin)
  Future<void> deleteUser({
    required String uid,
  }) async {
    try {
      // Validate UID
      if (uid.isEmpty) {
        throw Exception('UID is required.');
      }

      // Delete the user from auth.users
      await _supabase.auth.admin.deleteUser(uid);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // New method to check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      // Attempt to fetch users with the given email from auth.users
      final result = await _supabase
          .from('accounts')
          .select('email')
          .eq('email', email);

      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking email: $e');
    }
  }

  // Log in user and fetch role/status
  Future<Map<String, dynamic>> logIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) throw Exception('Login failed');

      // Fetch additional user data from public.profiles table
      final profile = await _supabase
          .from('accounts')
          .select('type, status')
          .eq('uid', user.id)
          .single();

      return {
        'uid': user.id,
        'email': user.email,
        'type' : profile['type'],
        'status': profile['status'],
      };
    } on AuthException catch (e) {
      throw Exception('Login error: ${e.message}');
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  // Log out user
  Future<void> logOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }
}
