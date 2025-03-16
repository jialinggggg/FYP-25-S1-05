// lib/utils/input_validator.dart

class InputValidator {
  // Validate height (in cm)
  static bool isValidHeight(double height) {
    return height >= 50 && height <= 300; // Height must be between 50 cm and 300 cm
  }

  // Validate weight (in kg)
  static bool isValidWeight(double weight) {
    return weight >= 20 && weight <= 500; // Weight must be between 20 kg and 500 kg
  }

  // Check if the user is above 18
  static bool isAbove18(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;

    // Adjust age if the birthday hasn't occurred yet this year
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      return age - 1 >= 18;
    }
    return age >= 18;
  }

  // Validate a field and update error state
  static bool validateField(
    String? value,
    Function(bool) setError,
    String errorMessage,
  ) {
    if (value == null || value.isEmpty) {
      setError(true);
      return false;
    }
    setError(false);
    return true;
  }

  // Validate numeric fields (e.g., weight, height)
  static bool validateNumericField(
    String? value,
    Function(bool) setError,
    double min,
    double max,
    String errorMessage,
  ) {
    final numericValue = double.tryParse(value ?? '');
    if (numericValue == null || numericValue < min || numericValue > max) {
      setError(true);
      return false;
    }
    setError(false);
    return true;
  }

  // Function to validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
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
}