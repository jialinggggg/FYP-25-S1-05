// lib/backend/controllers/edit_medical_hist_controller.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditMedicalHistController extends ChangeNotifier {
  final SupabaseClient supabaseClient;

  bool isLoading = false;

  /// Holds whatever was last fetched
  List<String> preExistingConditions = [];
  List<String> allergies = [];

  EditMedicalHistController({
    required this.supabaseClient,
  });


   Future<void> fetchMedicalHistory(String uid) async {
    isLoading = true;
    notifyListeners();

    try {
      final resp = await supabaseClient
          .from('user_medical_info')
          .select('pre_existing, allergies')
          .eq('uid', uid)
          .maybeSingle();

      if (resp != null) {
        // ← use the exact column name you SELECTed
        preExistingConditions = List<String>.from(resp['pre_existing'] ?? []);
        allergies             = List<String>.from(resp['allergies']   ?? []);
      } else {
        preExistingConditions = [];
        allergies             = [];
      }
    } catch (e) {
      debugPrint('Error fetching medical history: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Upserts a new row (or updates existing) for this [uid].
  Future<void> updateMedicalHistory(
    String uid, {
    required List<String> preExisting,
    required List<String> allergiesList,
  }) async {
    isLoading = true;
    notifyListeners();

    final data = {
      'uid': uid,
      'pre_existing': preExisting,
      'allergies': allergiesList,
    };

    try {
      await supabaseClient
          .from('user_medical_info')
          .upsert(data, onConflict: 'uid');

      // reflect the new values locally
      preExistingConditions = preExisting;
      allergies = allergiesList;
    } catch (e) {
      throw Exception('Failed to update medical history: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
