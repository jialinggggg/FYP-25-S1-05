import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Validate email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Function to check if email exists in Supabase Auth
  Future<bool> isEmailAvailable(String email) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('email', email);

      return response.isEmpty; // If empty, email is available
    } catch (e) {
      throw Exception('Error checking email availability: $e');
    }
  }

  // Create a user account and insert data into the database
  Future<void> createAccount({
    required String email,
    required String password,
    required String name,
    required String location,
    required String gender,
    required int age,
    required double weight,
    required double height,
    required String preExisting,
    required String allergies,
    required String goal,
    required double desiredWeight,
    required int dailyCalories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    try {
      // Create user account with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('User not created');
      }

      // Get the auto-generated UUID from the user object
      final userId = user.id;

      // Insert profile data
      await _supabase.from('profiles').insert({
        'user_id': userId,
        'name': name,
        'location': location,
        'gender': gender,
        'age': age,
        'weight': weight,
        'height': height,
      });

      // Insert medical history data
      await _supabase.from('medical_history').insert({
        'user_id': userId,
        'pre_existing': preExisting,
        'allergies': allergies,
      });

      // Insert user goals data
      await _supabase.from('user_goals').insert({
        'user_id': userId,
        'goal': goal,
        'desired_weight': desiredWeight,
        'daily_calories': dailyCalories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
      });
    } catch (error) {
      throw Exception('Unable to create account: $error');
    }
  }
}