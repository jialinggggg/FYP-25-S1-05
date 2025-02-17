// lib/utils/input_validator.dart
import 'package:flutter/material.dart';

class InputValidator {
  // Check if a text field is empty
  static bool isFieldEmpty(String? value, BuildContext context, String fieldName) {
    if (value == null || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your $fieldName')),
      );
      return true;
    }
    return false;
  }

  // Check if the user is above 18
  static bool isAbove18(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      return age - 1 >= 18;
    }
    return age >= 18;
  }

  // Validate height
  static bool isValidHeight(double height, String unit) {
    if (unit == 'cm') {
      return height > 0 && height <= 300; // Height must be between 0 and 300 cm
    } else {
      return height > 0 && height <= 10; // Height must be between 0 and 10 feet
    }
  }

  // Validate weight
  static bool isValidWeight(double weight, String unit) {
    if (unit == 'kg') {
      return weight > 0 && weight <= 500; // Weight must be between 0 and 500 kg
    } else {
      return weight > 0 && weight <= 1100; // Weight must be between 0 and 1100 lbs
    }
  }
}