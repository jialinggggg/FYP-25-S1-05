import '../entities/account.dart';
import '../entities/user_profile.dart';
import '../entities/user_medical_info.dart';
import '../entities/user_goal.dart';
import '../repositories/auth_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/user_profiles_repository.dart';
import '../repositories/user_medical_repository.dart';
import '../repositories/user_goals_repository.dart';
import '../repositories/user_measurements_repository.dart';

class SignupService {
  final AuthRepository _authRepo;
  final AccountRepository _accountRepo;
  final UserProfilesRepository _profileRepo;
  final UserMedicalRepository _medicalRepo;
  final UserGoalsRepository _goalsRepo;
  final UserMeasurementsRepository _measurementsRepo;

  SignupService({
    required AuthRepository authRepo,
    required AccountRepository accountRepo,
    required UserProfilesRepository profileRepo,
    required UserMedicalRepository medicalRepo,
    required UserGoalsRepository goalsRepo,
    required UserMeasurementsRepository measurementsRepo,
  })  : _authRepo = authRepo,
        _accountRepo = accountRepo,
        _profileRepo = profileRepo,
        _medicalRepo = medicalRepo,
        _goalsRepo = goalsRepo,
        _measurementsRepo = measurementsRepo;

  Future<void> execute({
    required String email,
    required String password,
    required UserProfile profile,
    required UserMedicalInfo medicalInfo,
    required UserGoals goals,
  }) async {
    // 1. Create auth user
    final authResponse = await _authRepo.signUpWithEmail(
      email: email,
      password: password,
    );
    final uid = authResponse.user!.id;

    // 2. Create account
    await _accountRepo.insertAccount(Account(
      uid: uid,
      email: email,
      type: 'user',
      status: 'active',
    ));

    // 3. Create profile
    await _profileRepo.insertProfile(profile.copyWith(uid: uid));

    // 4. Create medical info
    await _medicalRepo.insertMedical(medicalInfo.copyWith(uid: uid));

    // 5. Create goals
    await _goalsRepo.insertGoals(goals.copyWith(uid: uid));

    // 6. Create initial measurement
    await _measurementsRepo.insertMeasurement(
      uid: uid,
      weight: profile.weight,
    );
  }
}