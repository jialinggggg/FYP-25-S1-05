import '../utils/input_validator.dart';

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
    required double weight,
    required double height,
    required DateTime birthDate,
    required String goal,
    required String activity,
  }) {
    final age = DateTime.now().difference(birthDate).inDays ~/ 365;
    
    // Calculate BMR (Basal Metabolic Rate)
    double bmr;
    if (gender == 'Male') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    // Adjust for activity level
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

    // Calculate maintenance calories
    double maintenanceCalories = bmr * activityMultiplier;

    // Adjust for goals
    double targetCalories;
    double targetWeight;
    int weeksToGoal;
    
    switch (goal) {
      case 'Lose Weight':
        targetCalories = maintenanceCalories - 500; // 500 calorie deficit per day
        targetWeight = weight * 0.9; // Aim for 10% weight loss
        weeksToGoal = ((weight - targetWeight) / 0.5).round(); // 0.5kg per week
        break;
      case 'Gain Weight':
        targetCalories = maintenanceCalories + 500; // 500 calorie surplus per day
        targetWeight = weight * 1.1; // Aim for 10% weight gain
        weeksToGoal = ((targetWeight - weight) / 0.5).round(); // 0.5kg per week
        break;
      case 'Gain Muscle':
        targetCalories = maintenanceCalories + 250; // Small surplus for muscle gain
        targetWeight = weight * 1.05; // Aim for 5% weight gain (muscle)
        weeksToGoal = ((targetWeight - weight) / 0.25).round(); // 0.25kg per week (muscle grows slower)
        break;
      case 'Maintain Weight':
      default:
        targetCalories = maintenanceCalories;
        targetWeight = weight;
        weeksToGoal = 12; // Default 12 weeks for maintenance
    }

    // Calculate target date
    final targetDate = DateTime.now().add(Duration(days: weeksToGoal * 7));

    // Macronutrient distribution
    double protein;
    double fats;
    double carbs;
    
    if (goal == 'Gain Muscle') {
      protein = (weight * 2.2).roundToDouble(); // Higher protein for muscle gain
      fats = ((targetCalories * 0.25) / 9).roundToDouble(); // 25% of calories from fat
      carbs = ((targetCalories - (protein * 4) - (fats * 9)) / 4).roundToDouble();
    } else {
      protein = (weight * 1.6).roundToDouble(); // Standard protein
      fats = ((targetCalories * 0.25) / 9).roundToDouble(); // 25% of calories from fat
      carbs = ((targetCalories - (protein * 4) - (fats * 9)) / 4).roundToDouble();
    }

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