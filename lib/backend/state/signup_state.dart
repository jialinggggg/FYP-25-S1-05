import 'package:flutter/material.dart';
import '../entities/user_profile.dart';
import '../entities/user_medical_info.dart';
import '../entities/user_goal.dart';

class SignupState with ChangeNotifier {
  // Step 1: Basic Info
  String _name = '';
  String _country = '';
  
  // Step 2: Personal Details
  String _gender = '';
  DateTime? _birthDate;
  double _weight = 0;
  double _height = 0;
  
  // Step 3: Medical Info - Now stored as lists
  List<String> _preExistingConditions = [];
  List<String> _allergyList = [];
  
  // Step 4: Goals
  String _goal = '';
  
  // Step 5: Activity
  String _activity = '';
  
  // Step 6: Targets
  double _targetWeight = 0;
  DateTime? _targetDate;
  int _dailyCalories = 0;
  double _protein = 0;
  double _carbs = 0;
  double _fats = 0;
  
  // Step 7: Account Details
  String _email = '';
  String _password = '';
  
  // Getters
  String get name => _name;
  String get country => _country;
  String get gender => _gender;
  DateTime? get birthDate => _birthDate;
  double get weight => _weight;
  double get height => _height;
  List<String> get preExistingConditions => _preExistingConditions;
  List<String> get allergyList => _allergyList;
  String get goal => _goal;
  String get activity => _activity;
  double get targetWeight => _targetWeight;
  DateTime? get targetDate => _targetDate;
  int get dailyCalories => _dailyCalories;
  double get protein => _protein;
  double get carbs => _carbs;
  double get fats => _fats;
  String get email => _email;
  String get password => _password;

  // Convenience getters for compatibility
  String get preExisting => _preExistingConditions.isEmpty 
      ? 'NA' 
      : _preExistingConditions.join(',');
  String get allergies => _allergyList.isEmpty 
      ? 'NA' 
      : _allergyList.join(',');

  // Setters
  void setName(String value) {
    _name = value;
    notifyListeners();
  }
  
  void setCountry(String value) {
    _country = value;
    notifyListeners();
  }
  
  void setGender(String value) {
    _gender = value;
    notifyListeners();
  }
  
  void setBirthDate(DateTime value) {
    _birthDate = value;
    notifyListeners();
  }
  
  void setWeight(double value) {
    _weight = value;
    notifyListeners();
  }
  
  void setHeight(double value) {
    _height = value;
    notifyListeners();
  }

  // New methods for list-based medical info
  void setPreExistingConditions(List<String> conditions) {
    _preExistingConditions = conditions;
    notifyListeners();
  }

  void addPreExistingCondition(String condition) {
    _preExistingConditions.add(condition);
    notifyListeners();
  }

  void removePreExistingCondition(int index) {
    _preExistingConditions.removeAt(index);
    notifyListeners();
  }

  void setAllergyList(List<String> allergies) {
    _allergyList = allergies;
    notifyListeners();
  }

  void addAllergy(String allergy) {
    _allergyList.add(allergy);
    notifyListeners();
  }

  void removeAllergy(int index) {
    _allergyList.removeAt(index);
    notifyListeners();
  }

  // Backward-compatible setters
  void setPreExisting(String value) {
    _preExistingConditions = value == 'NA' ? [] : value.split(',');
    notifyListeners();
  }
  
  void setAllergies(String value) {
    _allergyList = value == 'NA' ? [] : value.split(',');
    notifyListeners();
  }
  
  void setGoal(String value) {
    _goal = value;
    notifyListeners();
  }
  
  void setActivity(String value) {
    _activity = value;
    notifyListeners();
  }
  
  void setTargetWeight(double value) {
    _targetWeight = value;
    notifyListeners();
  }
  
  void setTargetDate(DateTime value) {
    _targetDate = value;
    notifyListeners();
  }
  
  void setDailyCalories(int value) {
    _dailyCalories = value;
    notifyListeners();
  }
  
  void setProtein(double value) {
    _protein = value;
    notifyListeners();
  }
  
  void setCarbs(double value) {
    _carbs = value;
    notifyListeners();
  }
  
  void setFats(double value) {
    _fats = value;
    notifyListeners();
  }
  
  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }
  
  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }
  
  // Compose entities
  UserProfile get profile => UserProfile(
    uid: '', // Will be set during registration
    name: _name,
    country: _country,
    gender: _gender,
    birthDate: _birthDate!,
    weight: _weight,
    height: _height,
  );
  
  UserMedicalInfo get medicalInfo => UserMedicalInfo(
    uid: '', // Will be set during registration
    preExisting: _preExistingConditions,
    allergies: _allergyList,
  );
  
  UserGoals get goals => UserGoals(
    uid: '', // Will be set during registration
    goal: _goal,
    activity: _activity,
    targetWeight: _targetWeight,
    targetDate: _targetDate!,
    dailyCalories: _dailyCalories,
    protein: _protein,
    carbs: _carbs,
    fats: _fats,
  );

  // Clear all data (optional)
  void clearAll() {
    _name = '';
    _country = '';
    _gender = '';
    _birthDate = null;
    _weight = 0;
    _height = 0;
    _preExistingConditions = [];
    _allergyList = [];
    _goal = '';
    _activity = '';
    _targetWeight = 0;
    _targetDate = null;
    _dailyCalories = 0;
    _protein = 0;
    _carbs = 0;
    _fats = 0;
    _email = '';
    _password = '';
    notifyListeners();
  }
}