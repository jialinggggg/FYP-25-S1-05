// lib/utils/input_validator.dart
import 'package:flutter/material.dart';

class InputValidator {
  // Display an error message with an icon
  static Widget buildErrorMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.error, // Error icon
            color: Colors.red,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            message,
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold, // Make error text bold
            ),
          ),
        ],
      ),
    );
  }

  // Decoration for text fields with error highlighting
  static InputDecoration buildInputDecoration({
    required String hintText,
    required bool hasError,
  }) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderSide: BorderSide(
          color: hasError ? Colors.red : Colors.grey, // Highlight border in red if there's an error
          width: hasError ? 2.0 : 1.0, // Make the border thicker if there's an error
        ),
      ),
      hintText: hintText,
      errorBorder: OutlineInputBorder( // Red border when there's an error
        borderSide: BorderSide(
          color: Colors.red,
          width: 2.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder( // Red border when the field is focused and has an error
        borderSide: BorderSide(
          color: Colors.red,
          width: 2.0,
        ),
      ),
    );
  }

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
}