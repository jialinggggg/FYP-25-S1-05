// lib/backend/controllers/fetch_business_profile_info_controller.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../entities/account.dart';
import '../entities/business_profile.dart';

/// Controller to fetch and manage business profile info
class FetchBusinessProfileInfoController extends ChangeNotifier {
  final SupabaseClient _supabase;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Account? _account;
  Account? get account => _account;

  BusinessProfile? _businessProfile;
  BusinessProfile? get businessProfile => _businessProfile;

  FetchBusinessProfileInfoController(this._supabase);

  /// Loads both the account and the combined business profile data
  Future<void> loadProfileData(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch account info
      final accData = await _supabase
          .from('accounts')
          .select('uid, email, type, status')
          .eq('uid', uid)
          .single();
      _account = Account.fromMap(accData);

      // Fetch business profile fields
      final profData = await _supabase
          .from('business_profiles')
          .select()
          .eq('uid', uid)
          .single();
      final profMap = profData;

      // Build single BusinessProfile entity
      _businessProfile = BusinessProfile(
        businessName: profMap['name'] as String,
        registrationNo: profMap['registration_no'] as String,
        country: profMap['country'] as String,
        address: profMap['address'] as String,
        description: profMap['description'] as String? ?? '',
        contactName: profMap['contact_name'] as String,
        contactRole: profMap['contact_role'] as String,
        contactEmail: profMap['contact_email'] as String,
        // Simplest: if there's a non-empty website string, use it; otherwise default to ''
        website: (profMap['website'] as String?)?.isNotEmpty == true
            ? profMap['website'] as String
            : '',
        registrationDocUrls: profMap['registration_doc_url'] != null
            ? [profMap['registration_doc_url'] as String]
            : [],
      );
    } catch (e) {
      // Handle or rethrow
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs out the current user
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}