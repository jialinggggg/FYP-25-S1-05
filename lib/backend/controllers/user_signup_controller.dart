import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_profile.dart';
import '../entities/user_medical_info.dart';
import '../entities/user_goal.dart';

/// Controller to handle user signup by interacting directly with Supabase.
class SignupController {
  final SupabaseClient _supabase;

  SignupController(this._supabase);

  /// Executes the signup flow:
  /// 1. Create auth user
  /// 2. Insert account record
  /// 3. Insert user profile
  /// 4. Insert medical info
  /// 5. Insert user goals
  /// 6. Insert initial measurement
  Future<void> execute({
    required String email,
    required String password,
    required UserProfile profile,
    required UserMedicalInfo medicalInfo,
    required UserGoals goals,
  }) async {
    // 1. Sign up user in Supabase Auth
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    final user = authResponse.user;
    if (user == null) {
      throw Exception('Sign up failed: no user returned');
    }
    final uid = user.id;

    // 2. Insert into accounts table
    await _supabase.from('accounts').insert({
      'uid': uid,
      'email': email,
      'type': 'user',
      'status': 'active',
    });

    // 3. Insert into user_profiles table
    await _supabase.from('user_profiles').insert({
      ...profile.toMap(),
      'uid': uid,
    });

    // 4. Insert into user_medical_info table
    await _supabase.from('user_medical_info').insert({
      'uid': uid,
      'pre_existing': medicalInfo.preExisting,
      'allergies': medicalInfo.allergies,
    });

    // 5. Insert into user_goals table
    await _supabase.from('user_goals').insert({
      ...goals.toMap(),
      'uid': uid,
    });

    // 6. Insert initial measurement into user_measurements table
    final height = profile.height;
    final weight = profile.weight;
    final bmi = weight / ((height / 100) * (height / 100));
    await _supabase.from('user_measurements').insert({
      'uid': uid,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
