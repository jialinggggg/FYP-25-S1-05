import 'package:supabase_flutter/supabase_flutter.dart';


class UserMeasurementService {
  final SupabaseClient _supabase;

  // Constructor to initialize Supabase client
  UserMeasurementService(this._supabase);

  // Method to insert a measurement
  Future<void> insertMeasurement({
    required String uid,
    required double weight,
    required double height,
    required double bmi,
  }) async {
    try {
      // Validate inputs
      if (uid.isEmpty) {
        throw Exception('UID is required.');
      }
      if (weight <= 0 || height <= 0 || bmi <= 0) {
        throw Exception('Invalid input: Weight, height, and BMI must be positive values.');
      }

      // Calculate bmi
      bmi = weight / ((height/100) * (height/100));

      // Insert the new measurement into the 'user_measurement' table
      await _supabase.from('user_measurements').insert({
        'uid': uid,
        'weight': weight,
        'height': height,
        'bmi': bmi,
      });
    } catch (error) {
      throw Exception('Unable to insert profile: $error');
    }
  }

}