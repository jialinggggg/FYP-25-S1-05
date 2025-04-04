// profile_controller.dart
import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';

class UserProfileState extends ChangeNotifier {
  final UserProfileService _userProfileState;
  bool _isLoading = true;

  // Profile Data
  String name = "";
  String email = "";
  String location = "";
  DateTime? birthDate;
  String gender = "";
  double startWeight = 0.0;
  double height = 0.0;

  // Goals Data
  String goal = "";
  String activity = "";
  double targetWeight = 0;
  DateTime? targetDate;
  int dailyCalories = 0;
  double fats = 0.0;
  double protein = 0;
  double carbs = 0;

  // Medical History
  List <String> preExistingConditions = [];
  List <String> allergies = [];

  bool get isLoading => _isLoading;

  UserProfileState(this._userProfileState);

  Future<void> loadProfileData(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _userProfileState.getUserProfileData(userId);

      // Update profile data
      name = data['profile']['name'] ?? "";
      email = data['account']['email'] ?? "";
      location = data['profile']['country'] ?? "";
      birthDate = DateTime.tryParse(data['profile']['birth_date'] ?? "");
      gender = data['profile']['gender'] ?? "";
      startWeight = double.tryParse(data['profile']['weight']?.toString() ?? '0.0') ?? 0.0;
      height = double.tryParse(data['profile']['height']?.toString() ?? '0.0') ?? 0.0;

      // Update goals data
      goal = data['goals']['goal'] ?? "";
      activity = data['goals']['activity'] ?? "";
      targetWeight = double.tryParse(data['goals']['target_weight']?.toString() ?? '0.0') ?? 0.0;
      targetDate = DateTime.tryParse(data['goals']['target_date'] ?? "");
      dailyCalories = data['goals']['daily_calories'] ?? 0;
      fats = double.tryParse(data['goals']['fats']?.toString() ?? '0.0') ?? 0.0;
      protein = double.tryParse(data['goals']['protein']?.toString() ?? '0.0') ?? 0.0;
      carbs = double.tryParse(data['goals']['carbs']?.toString() ?? '0.0') ?? 0.0;

      // Update medical history
      preExistingConditions = (data['medical']['pre_existing'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
allergies = (data['medical']['allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _userProfileState.logout();
  }
}