import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Function to validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Function to check if email exists in Supabase Auth
  Future<bool> isEmailAvailable(String email) async {
    try {
    // Attempt to sign up with the email
    await _supabase.auth.signUp(
      email: email,
      password: '1234', // Use a dummy password
    );

    // If no error is thrown, the email is available
    return true;
  } catch (e) {
    // If an error is thrown, the email is already registered
    return false;
  }
  }

  // Function to validate password
  static Map<String, bool> validatePassword(String password) {
    return {
      'hasMinLength': password.length >= 8,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasNumber': password.contains(RegExp(r'[0-9]')),
      'hasSymbol': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }

  // Create a user account and insert data into the database
  Future<void> createAccount({
    required String email,
    required String password,
    required String name,
    required String location,
    required String gender,
    required DateTime birthDate, // Change age to birthDate
    required double weight,
    required double height,
    required String? preExisting,
    required String? allergies,
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

      // Convert DateTime to ISO 8601 string
      final birthDateString = birthDate.toIso8601String();

      // Insert profile data
      await _supabase.from('user_profiles').insert({
        'user_id': userId,
        'name': name,
        'location': location,
        'gender': gender,
        'birth_date': birthDateString,
        'start_weight': weight,
        'height': height, // Use the converted string
      });

      await _supabase.from('user_measurements').insert({
        'user_id': userId,
        'weight': weight,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Insert medical history data with encrypted fields
      await _supabase.from('user_medical_info').insert({
        'user_id': userId,
        'pre_existing': preExisting,
        'allergies': allergies,
      });

      // Insert user goals data
      await _supabase.from('user_goals').insert({
        'user_id': userId,
        'desired_weight': desiredWeight,
        'daily_calories_goal': dailyCalories,
        'protein_goal': protein,
        'carbs_goal': carbs,
        'fats_goal': fats,
      });
    } catch (error) {
      throw Exception('Unable to create account: $error');
    }
  }

  Future<void> deleteAccount(String email) async {
  try {
    // Retrieve the user list from Supabase Auth
    final users = await _supabase.auth.admin.listUsers();

    // Find the user with the matching email
    final user = users.firstWhere(
      (user) => user.email == email,
      orElse: () => throw Exception('User with email $email not found'),
    );

    final userId = user.id;

    // Delete user profile data
    await _supabase.from('user_profiles').delete().eq('user_id', userId);

    // Delete user measurements data
    await _supabase.from('user_measurements').delete().eq('user_id', userId);

    // Delete user medical history data
    await _supabase.from('user_medical_info').delete().eq('user_id', userId);

    // Delete user goals data
    await _supabase.from('user_goals').delete().eq('user_id', userId);

    // Delete the user account from Supabase Auth
    await _supabase.auth.admin.deleteUser(userId);

  } catch (error) {
    throw Exception('Unable to delete account: $error');
  }
}

  // Fetch user profile data
  Future<Map<String, dynamic>> fetchProfile(String userId) async {
    final response = await _supabase
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .single();
    return response;
  }

  /// Fetch user email from Supabase Auth
  Future<String> fetchUserEmail() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.email ?? "";
  }
  // Update user profile data
  Future<void> updateProfile(
    String userId, {
    required String name,
    required DateTime birthDate,
    required String location,
    required String gender,
    required double startWeight,
    required double height,
  }) async {
    await _supabase.from('user_profiles').update({
      'name': name,
      'birth_date': birthDate.toIso8601String(),
      'location': location,
      'gender': gender,
      'start_weight': startWeight,
      'height': height,
    }).eq('user_id', userId);
  }

  /// Fetch user medical history
  Future<Map<String, dynamic>> fetchMedicalHistory(String userId) async {
    final response = await _supabase
        .from('user_medical_info')
        .select()
        .eq('user_id', userId)
        .single();
    return response;
  }

  /// Update user medical history
  Future<void> updateMedicalHistory(
    String userId, {
    required String? preExistingConditions,
    required String? allergies,
  }) async {
    await _supabase.from('user_medical_info').update({
      'pre_existing': preExistingConditions,
      'allergies': allergies,
    }).eq('user_id', userId);
  }

  /// Fetch user goals
  Future<Map<String, dynamic>> fetchGoals(String userId) async {
    final response = await _supabase
        .from('user_goals')
        .select()
        .eq('user_id', userId)
        .single();
    return response;
  }

  /// Update user goals
  Future<void> updateGoals(
    String userId, {
    required double desiredWeight,
    required int dailyCaloriesGoal,
    required double proteinGoal,
    required double carbsGoal,
    required double fatsGoal,
  }) async {
    await _supabase.from('user_goals').update({
      'desired_weight': desiredWeight,
      'daily_calories_goal': dailyCaloriesGoal,
      'protein_goal': proteinGoal,
      'carbs_goal': carbsGoal,
      'fats_goal': fatsGoal,
    }).eq('user_id', userId);
  }

    // Reusable function to fetch meal entries
  static Future<List<Map<String, dynamic>>> fetchMealEntries(
      SupabaseClient supabase, String userId, DateTime startDate, DateTime endDate) async {
    return await supabase
        .from('meal_entries')
        .select('*')
        .eq('user_id', userId)
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String())
        .order('created_at', ascending: false);
  }

  // Reusable function to fetch health data
  static Future<List<Map<String, dynamic>>> fetchHealthData(SupabaseClient supabase, String userId) async {
    return await supabase
        .from('user_measurements')
        .select('weight, height, bmi, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }
}