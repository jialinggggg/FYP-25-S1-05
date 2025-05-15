// lib/backend/state/fetch_user_profile_info_controller.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// adjust these imports to wherever you keep your entity classes:
import '../entities/user_profile.dart';
import '../entities/account.dart';
import '../entities/user_goal.dart';
import '../entities/user_medical_info.dart';

class FetchUserProfileInfoController extends ChangeNotifier {
  final SupabaseClient supabaseClient;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  UserProfile? userProfile;
  Account? account;
  UserGoals? userGoals;
  UserMedicalInfo? medicalInfo;

  FetchUserProfileInfoController(this.supabaseClient);

  Future<void> loadProfileData(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // fetch raw maps
      final profileMap = await supabaseClient
          .from('user_profiles')
          .select()
          .eq('uid', userId)
          .single();
      final accountMap = await supabaseClient
          .from('accounts')
          .select()
          .eq('uid', userId)
          .single();
      final goalsMap = await supabaseClient
          .from('user_goals')
          .select()
          .eq('uid', userId)
          .single();
      final medicalMap = await supabaseClient
          .from('user_medical_info')
          .select()
          .eq('uid', userId)
          .single();

      // parse into your entities
      userProfile    = UserProfile.fromMap(profileMap);
      account        = Account.fromMap(accountMap);
      userGoals      = UserGoals.fromMap(goalsMap);
      medicalInfo    = UserMedicalInfo.fromMap(medicalMap);
    } catch (e) {
      // you may want to handle/log errors more gracefully
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await supabaseClient.auth.signOut();
  }
}
