import 'input_validator.dart';

class InputValidationService {
  String? validateBasicInfo(String name, String country) {
    if (!InputValidator.validateField(name)) return 'Please enter your name';
    if (!InputValidator.validateField(country)) return 'Please select your country';
    return null;
  }

  String? validatePersonalDetails({
    required String gender,
    required DateTime? birthDate,
    required String weight,
    required String height,
  }) {
    if (!InputValidator.validateField(gender)) return 'Please select your gender';
    if (birthDate == null) return 'Please enter your birthdate';
    if (!InputValidator.validateNumericField(weight, 20, 500)) {
      return 'Please enter a valid weight (20-500 kg)';
    }
    if (!InputValidator.validateNumericField(height, 50, 300)) {
      return 'Please enter a valid height (50-300 cm)';
    }
    if (!InputValidator.isAbove18(birthDate)) {
      return 'You must be above 18 to sign up';
    }
    return null;
  }

  Map<String, dynamic> calculateRecommendedGoals({
    required String gender,
    required double weight,      // in kg
    required double height,      // in cm
    required DateTime birthDate,
    required String goal,
    required String activity,
  }) {
    final now = DateTime.now();
    final age = now.difference(birthDate).inDays ~/ 365;

    // Convert height to meters & compute BMI bounds
    final heightM = height / 100;
    final minWeight = 18.5 * heightM * heightM;
    final maxWeight = 24.9 * heightM * heightM;

    // 1) BMR
    double bmr;
    if (gender == 'Male') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    // 2) Activity adjustment
    double activityMultiplier;
    switch (activity) {
      case 'Sedentary':
        activityMultiplier = 1.2;
        break;
      case 'Lightly Active':
        activityMultiplier = 1.375;
        break;
      case 'Moderately Active':
        activityMultiplier = 1.55;
        break;
      case 'Very Active':
        activityMultiplier = 1.725;
        break;
      default:
        activityMultiplier = 1.55;
    }
    final maintenanceCalories = bmr * activityMultiplier;

    double targetCalories;
    double targetWeight;
    int weeksToGoal;

    switch (goal) {
      case 'Lose Weight':
        // 500-calorie deficit
        targetCalories = maintenanceCalories - 500;
        // clamp into normal BMI
        targetWeight = weight > maxWeight
          ? maxWeight
          : (weight < minWeight ? minWeight : weight);
        weeksToGoal = ((weight - targetWeight).abs() / 0.5).round();
        break;

      case 'Gain Weight':
        // 500-calorie surplus
        targetCalories = maintenanceCalories + 500;
        // clamp into normal BMI
        targetWeight = weight < minWeight
          ? minWeight
          : (weight > maxWeight ? maxWeight : weight);
        weeksToGoal = ((targetWeight - weight).abs() / 0.5).round();
        break;

      case 'Gain Muscle':
        // small surplus
        targetCalories = maintenanceCalories + 250;
        // clamp into normal BMI
        targetWeight = weight < minWeight
          ? minWeight
          : (weight > maxWeight ? maxWeight : weight);
        // muscle gains ~0.25 kg/week
        weeksToGoal = ((targetWeight - weight).abs() / 0.25).round();
        break;

      case 'Maintain Weight':
      default:
        targetCalories = maintenanceCalories;
        targetWeight = weight;
        weeksToGoal = 12;
    }

    // target date
    final targetDate = now.add(Duration(days: weeksToGoal * 7));

    // macros
    double protein;
    double fats = ((targetCalories * 0.25) / 9).roundToDouble();
    double carbs;

    if (goal == 'Gain Muscle') {
      protein = (weight * 2.2).roundToDouble();
    } else {
      protein = (weight * 1.6).roundToDouble();
    }
    carbs = ((targetCalories - (protein * 4) - (fats * 9)) / 4).roundToDouble();

    return {
      'targetWeight': targetWeight,
      'targetDate': targetDate,
      'dailyCalories': targetCalories.round(),
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }


  String? validateAccountDetails(String email, String password) {
    if (!InputValidator.isValidEmail(email)) return 'Please enter a valid email';
    
    final passwordValidation = InputValidator.validatePassword(password);
    if (!passwordValidation['hasMinLength']! || 
        !passwordValidation['hasUppercase']! || 
        !passwordValidation['hasNumber']! || 
        !passwordValidation['hasSymbol']!) {
      return 'Password does not meet requirements';
    }
    return null;
  }
}