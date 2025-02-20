import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/encryption.dart'; // Import the encryption utility

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
      final response = await _supabase
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
    required DateTime birthDate, // Change age to birthDate
    required double weight,
    required double height,
    required String weightUnit,
    required String heightUnit,
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
      // Generate and store encryption key and IV
      final encryptionKey = Encryption.generateEncryptionKey();
      final encryptionIV = Encryption.generateIV();
      await Encryption.storeEncryptionKeys(encryptionKey, encryptionIV);

      // Encrypt sensitive data
      final encryptedPreExisting = Encryption.encryptAES(preExisting, encryptionKey, encryptionIV);
      final encryptedAllergies = Encryption.encryptAES(allergies, encryptionKey, encryptionIV);

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
        'birth_date': birthDateString, // Use the converted string
        'weight': weight,
        'height': height,
      });

      // Insert medical history data with encrypted fields
      await _supabase.from('user_medical_info').insert({
        'user_id': userId,
        'pre_existing': encryptedPreExisting,
        'allergies': encryptedAllergies,
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