import 'package:supabase_flutter/supabase_flutter.dart';


class UserGoalsService {
  final SupabaseClient _supabase;

  // Constructor to initialize Supabase client
  UserGoalsService(this._supabase);

  // Method to insert a new user goal
  Future<void> insertGoals({
    required String uid,
    required double weight,
    required int dailyCalories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    try {
      // Validate inputs
      if (uid.isEmpty) {
        throw Exception('UID is required.');
      }
      if (weight <= 0 || dailyCalories <= 0 || protein <= 0 || carbs <= 0 || fats <= 0) {
        throw Exception('Invalid input: Weight, daily calories, protein, carbs, and fats must be positive values.');
      }


      // Insert the new medical profile into the 'user_medical_info' table
      await _supabase.from('user_goals').insert({
        'uid': uid,
        'weight': weight,
        'daily_calories': dailyCalories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
      });
    } catch (error) {
      throw Exception('Unable to insert profile: $error');
    }
  }

  // Method to fetch a user goal info by UID
  Future<Map<String, dynamic>?> fetchGoals(String uid) async {
    try {
      // Validate UID
      if (uid.isEmpty) {
        throw Exception('UID is required.');
      }

      // Fetch from the database
      final response = await _supabase
          .from('user_goals')
          .select()
          .eq('uid', uid)
          .single();

      return response;
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  // Method to update a goals profile
  Future<void> updateGoals({
    required String uid,
    required double weight,
    required int dailyCalories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    try {
      // Validate inputs
      if (uid.isEmpty) {
        throw Exception('UID is required.');
      }
      if (weight <= 0 || dailyCalories <= 0 || protein <= 0 || carbs <= 0 || fats <= 0) {
        throw Exception('Invalid input: Weight, daily calories, protein, carbs, and fats must be positive values.');
      }

      // Update the database
      await _supabase.from('user_goals').update({
        'uid': uid,
        'weight': weight,
        'daily_calories': dailyCalories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
      }).eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Method to delete a Goals profile
  Future<void> deleteGoals({
    required String uid,
  }) async {
    try {
      // Validate UID
      if (uid.isEmpty) {
        throw Exception('UID is required.');
      }

      // Delete from the database
      await _supabase.from('user_goals').delete().eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }
}