
import 'package:flutter/material.dart';

class DatePicker {
  // Function to show a date picker for birth date
  static Future<DateTime?> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    return picked;
  }
}
