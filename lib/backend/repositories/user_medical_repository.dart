import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_medical_info.dart';

class UserMedicalRepository {
  final SupabaseClient _supabase;

  UserMedicalRepository(this._supabase);

  Future<void> insertMedical(UserMedicalInfo medicalInfo) async {
    try {
      await _supabase.from('user_medical_info').insert({
        'uid': medicalInfo.uid,
        'pre_existing': medicalInfo.preExisting,
        'allergies': medicalInfo.allergies,
      });
    } catch (error) {
      throw Exception('Unable to insert medical info: $error');
    }
  }

  Future<UserMedicalInfo?> fetchMedical(String uid) async {
  try {
    final response = await _supabase
        .from('user_medical_info')
        .select()
        .eq('uid', uid)
        .single();
    
    // Ensure we properly convert the List<dynamic> to List<String>
    return UserMedicalInfo(
      uid: response['uid'] as String,
      preExisting: (response['pre_existing'] as List<dynamic>).map((e) => e.toString()).toList(),
      allergies: (response['allergies'] as List<dynamic>).map((e) => e.toString()).toList(),
    );
  } catch (e) {
    return null;
  }
}

  Future<void> updateMedical(UserMedicalInfo medicalInfo) async {
    try {
      await _supabase.from('user_medical_info')
          .update({
            'pre_existing': medicalInfo.preExisting,
            'allergies': medicalInfo.allergies,
          })
          .eq('uid', medicalInfo.uid);
    } catch (e) {
      throw Exception('Failed to update medical info: $e');
    }
  }

  Future<void> deleteMedical(String uid) async {
    try {
      await _supabase.from('user_medical_info').delete().eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to delete medical info: $e');
    }
  }
}