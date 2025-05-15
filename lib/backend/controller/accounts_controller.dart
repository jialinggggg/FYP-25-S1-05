import 'package:supabase_flutter/supabase_flutter.dart';

class AccountsController {
  final SupabaseClient client;

  AccountsController(this.client);

  Future<List<Map<String, dynamic>>> fetchAllUserAccounts() async {
    final response = await client.from('user_profiles').select('*, accounts(email,status)');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchAllBusinessAccounts() async {
    final response = await client.from('business_profiles').select('*, accounts(email,status)');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchAllNutritionistAccounts() async {
    final response = await client.from('nutritionist_profiles').select('*, accounts(email,status)');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<String> fetchProfileType(String uid) async {
    final userResponse = await client.from('user_profiles').select().eq('uid', uid).maybeSingle();
    if (userResponse != null) return 'user_profiles';

    final businessResponse = await client.from('business_profiles').select().eq('uid', uid).maybeSingle();
    if (businessResponse != null) return 'business_profiles';

    final nutritionistResponse = await client.from('nutritionist_profiles').select().eq('uid', uid).maybeSingle();
    if (nutritionistResponse != null) return 'nutritionist_profiles';

    throw Exception("Profile not found for uid: $uid");
  }

  Future<Map<String, dynamic>?> fetchProfileByType(String uid, String profileType) async {
    final response = await client.from(profileType).select().eq('uid', uid).maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> fetchAccountDetails(String uid) async {
    final response = await client.from('accounts').select().eq('uid', uid).maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> fetchUserGoals(String uid) async {
    final response = await client.from('user_goals').select().eq('uid', uid).maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> fetchUserMedicalInfo(String uid) async {
    final response = await client.from('user_medical_info').select().eq('uid', uid).maybeSingle();
    return response;
  }

  Future<void> updateProfile(
      String uid,
      String profileType,
      Map<String, dynamic> profileDetails,
      Map<String, dynamic> accountDetails,
      Map<String, dynamic>? userGoals,
      Map<String, dynamic>? userMedicalInfo) async {

    // Update profile details
    await client.from(profileType).update(profileDetails).eq('uid', uid);

    // Update account details
    await client.from('accounts').update(accountDetails).eq('uid', uid);

    // Update user goals if user profile
    if (profileType == 'user_profiles' && userGoals != null) {
      await client.from('user_goals').update(userGoals).eq('uid', uid);
    }

    // Update medical info if user profile
    if (profileType == 'user_profiles' && userMedicalInfo != null) {
      await client.from('user_medical_info').update(userMedicalInfo).eq('uid', uid);
    }
  }

  Future<void> updateAccountStatus(String uid, String newStatus) async {
    await client.from('accounts').update({'status': newStatus}).eq('uid', uid);
  }
}
