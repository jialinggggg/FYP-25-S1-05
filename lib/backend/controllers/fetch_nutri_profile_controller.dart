import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../entities/account.dart';
import '../entities/nutritionist_profile.dart';

/// Controller to fetch and manage the nutritionist's profile info
class FetchNutritionistProfileInfoController extends ChangeNotifier {
  final SupabaseClient _supabase;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Account? _account;
  Account? get account => _account;

  NutritionistProfile? _nutritionistProfile;
  NutritionistProfile? get nutritionistProfile => _nutritionistProfile;

  FetchNutritionistProfileInfoController(this._supabase);

  /// Loads both the account and the nutritionist profile data
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

      // Fetch nutritionist profile info
      final profData = await _supabase
          .from('nutritionist_profiles')
          .select(
            'full_name, organization, license_number, issuing_body, issuance_date, expiration_date, license_scan_urls'
          )
          .eq('uid', uid)
          .single();

      final map = profData;

      // Parse issuance_date
      DateTime issuanceDate;
      final issValue = map['issuance_date'];
      if (issValue is String) {
        issuanceDate = DateTime.parse(issValue);
      } else if (issValue is DateTime) {
        issuanceDate = issValue;
      } else {
        throw Exception('Invalid issuance_date format');
      }

      // Parse expiration_date
      DateTime expirationDate;
      final expValue = map['expiration_date'];
      if (expValue is String) {
        expirationDate = DateTime.parse(expValue);
      } else if (expValue is DateTime) {
        expirationDate = expValue;
      } else {
        throw Exception('Invalid expiration_date format');
      }

      // Parse scans_urls to licenseScanUrls
      final scansList = map['license_scan_urls'];
      final List<String> licenseScanUrls =
          (scansList is List) ? scansList.map((e) => e.toString()).toList() : [];

      _nutritionistProfile = NutritionistProfile(
        fullName: map['full_name'] as String,
        organization: map['organization'] as String? ?? '',
        licenseNumber: map['license_number'] as String,
        issuingBody: map['issuing_body'] as String,
        issuanceDate: issuanceDate,
        expirationDate: expirationDate,
        licenseScanUrls: licenseScanUrls,
      );
    } catch (e) {
      // Handle or rethrow error
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Log out the current user
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
