class InputValidator {
  static bool isValidHeight(double height) => height >= 50 && height <= 300;
  static bool isValidWeight(double weight) => weight >= 20 && weight <= 500;
  
  static bool isAbove18(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      return age - 1 >= 18;
    }
    return age >= 18;
  }

  static bool validateField(String? value) => value != null && value.isNotEmpty;

  static bool validateNumericField(String? value, double min, double max) {
    final numericValue = double.tryParse(value ?? '');
    return numericValue != null && numericValue >= min && numericValue <= max;
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
      .hasMatch(email);
  }

  static Map<String, bool> validatePassword(String password) {
    return {
      'hasMinLength': password.length >= 8,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasNumber': password.contains(RegExp(r'[0-9]')),
      'hasSymbol': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }
}