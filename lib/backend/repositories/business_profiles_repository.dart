import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/business_profile.dart';

class BusinessProfilesRepository {
  final SupabaseClient _supabase;

  BusinessProfilesRepository(this._supabase);

  Future<void> insertProfile(BusinessProfile profile) async {
    try {
      await _supabase.from('business_profiles').insert(profile.toMap());
    } catch (error) {
      throw Exception('Unable to insert profile: $error');
    }
  }

  Future<BusinessProfile?> fetchProfile(String uid) async {
    try {
      final response = await _supabase
          .from('business_profiles')
          .select()
          .eq('uid', uid)
          .single();
      return BusinessProfile.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfile(BusinessProfile profile) async {
    try {
      await _supabase.from('business_profiles')
          .update(profile.toMap())
          .eq('uid', profile.uid);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> deleteProfile(String uid) async {
    try {
      await _supabase.from('business_profiles').delete().eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }
}