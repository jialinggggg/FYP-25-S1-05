// profile_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/user_profiles_repository.dart';
import '../repositories/user_goals_repository.dart';
import '../repositories/user_medical_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/auth_repository.dart';
import '../entities/user_profile.dart';
import '../entities/user_goal.dart';
import '../entities/user_medical_info.dart';

class UserProfileService {
  final SupabaseClient _supabase;
  late final UserProfilesRepository _profileRepository;
  late final UserGoalsRepository _goalsRepository;
  late final UserMedicalRepository _medicalRepository;
  late final AccountRepository _accountsRepository;
  late final AuthRepository _authRepository; // Added this line

  UserProfileService(this._supabase) {
    _profileRepository = UserProfilesRepository(_supabase);
    _goalsRepository = UserGoalsRepository(_supabase);
    _medicalRepository = UserMedicalRepository(_supabase);
    _accountsRepository = AccountRepository(_supabase);
    _authRepository = AuthRepository(_supabase); // Initialize auth repository
  }

  Future<Map<String, dynamic>> getUserProfileData(String userId) async {
  try {
    final profileData = await _profileRepository.fetchProfile(userId);
    final goalsData = await _goalsRepository.fetchGoals(userId);
    final medicalHistory = await _medicalRepository.fetchMedical(userId);
    final accountData = await _accountsRepository.fetchAccount(userId);

    return {
      'profile': profileData?.toMap() ?? {},
      'goals': goalsData?.toMap() ?? {},
      'medical': {
        'pre_existing': medicalHistory?.preExisting ?? [],
        'allergies': medicalHistory?.allergies ?? [],
      },
      'account': accountData?.toMap() ?? {},
    };
  } catch (e) {
    throw Exception('Failed to fetch user profile data: $e');
  }
}

  Future<void> updateProfile(UserProfile profile) async {
    await _profileRepository.updateProfile(profile);
  }

  Future<void> updateGoals(UserGoals goals) async {
    await _goalsRepository.updateGoals(goals);
  }

  Future<void> updateMedical(UserMedicalInfo medicalInfo) async {
    await _medicalRepository.updateMedical(medicalInfo);
  }

  Future<void> logout() async {
    await _authRepository.signOut(); // Changed to use signOut() from AuthRepository
  }
}