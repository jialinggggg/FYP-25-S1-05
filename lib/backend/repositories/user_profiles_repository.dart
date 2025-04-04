import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_profile.dart';

class UserProfilesRepository {
  final SupabaseClient _supabase;

  UserProfilesRepository(this._supabase);

  Future<void> insertProfile(UserProfile profile) async {
    try {
      await _supabase.from('user_profiles').insert(profile.toMap());
    } catch (error) {
      throw Exception('Unable to insert profile: $error');
    }
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('uid', uid)
          .single();
      return UserProfile.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _supabase.from('user_profiles')
          .update(profile.toMap())
          .eq('uid', profile.uid);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> deleteProfile(String uid) async {
    try {
      await _supabase.from('user_profiles').delete().eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }
}