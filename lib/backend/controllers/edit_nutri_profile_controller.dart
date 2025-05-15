import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../entities/nutritionist_profile.dart';

/// Controller to edit and update a nutritionist's profile
class EditNutritionistProfileController extends ChangeNotifier {
  final SupabaseClient _supabase;
  final String _uid;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Editable fields
  String fullName;
  String organization;
  String licenseNumber;
  String issuingBody;
  DateTime issuanceDate;
  DateTime expirationDate;

  /// URLs already stored in the DB
  List<String> existingScanUrls;

  /// Newly picked files, not yet uploaded
  List<File> newLicenseScans = [];

  EditNutritionistProfileController(
    this._supabase,
    NutritionistProfile initialProfile,
    this._uid,
  )   : fullName         = initialProfile.fullName,
        organization     = initialProfile.organization ?? '',
        licenseNumber    = initialProfile.licenseNumber,
        issuingBody      = initialProfile.issuingBody,
        issuanceDate     = initialProfile.issuanceDate,
        expirationDate   = initialProfile.expirationDate,
        existingScanUrls = List<String>.from(initialProfile.licenseScanUrls);

  /// Append more picked files to the list
  void addNewScans(List<File> scans) {
    newLicenseScans.addAll(scans);
    notifyListeners();
  }

  /// Remove an already-uploaded URL
  void removeExistingScan(int index) {
    if (index >= 0 && index < existingScanUrls.length) {
      existingScanUrls.removeAt(index);
      notifyListeners();
    }
  }

  /// Remove one of the newly picked files
  void removeNewScan(int index) {
    if (index >= 0 && index < newLicenseScans.length) {
      newLicenseScans.removeAt(index);
      notifyListeners();
    }
  }

  /// Persist changes: upload new scans, then update DB
  Future<void> updateProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final bucket = _supabase.storage.from('profiles-documents');
      final uploadedUrls = <String>[];

      // Upload each new file
      for (final file in newLicenseScans) {
        final ts       = DateTime.now().millisecondsSinceEpoch;
        final name     = file.path.split('/').last;
        final path     = 'nutritionist/$_uid/${ts}_$name';
        await bucket.upload(path, file);
        final publicUrl = bucket.getPublicUrl(path);
        uploadedUrls.add(publicUrl);
      }

      // Merge existing + newly uploaded
      final allUrls = [...existingScanUrls, ...uploadedUrls];

      // Update row
      await _supabase.from('nutritionist_profiles').update({
        'full_name'         : fullName,
        'organization'      : organization,
        'license_number'    : licenseNumber,
        'issuing_body'      : issuingBody,
        'issuance_date'     : issuanceDate.toIso8601String().split('T').first,
        'expiration_date'   : expirationDate.toIso8601String().split('T').first,
        'license_scan_urls' : allUrls,
      }).eq('uid', _uid);

      // Refresh local state
      existingScanUrls = allUrls;
      newLicenseScans  = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
