import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../entities/business_profile.dart';

/// Controller to edit a business’s core profile
class EditBusinessProfileController extends ChangeNotifier {
  final SupabaseClient _supabase;
  final String _uid;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Editable fields
  String businessName;
  String registrationNo;
  String country;
  String address;
  String description;
  String website;

  /// URLs already in the DB
  List<String> existingDocUrls;

  /// Newly picked files, not yet uploaded
  List<File> newDocs = [];

  EditBusinessProfileController(
      this._supabase,
      BusinessProfile initial,
      this._uid,
    )   : businessName  = initial.businessName,
          registrationNo = initial.registrationNo,
          country        = initial.country,
          address        = initial.address,
          description    = initial.description,
          website        = initial.website,
          existingDocUrls = List<String>.from(initial.registrationDocUrls);

  /// Append new chosen files
  void addNewDocs(List<File> files) {
    newDocs.addAll(files);
    notifyListeners();
  }

  /// Remove an existing URL
  void removeExistingDoc(int idx) {
    if (idx >= 0 && idx < existingDocUrls.length) {
      existingDocUrls.removeAt(idx);
      notifyListeners();
    }
  }

  /// Remove one of the newly picked files
  void removeNewDoc(int idx) {
    if (idx >= 0 && idx < newDocs.length) {
      newDocs.removeAt(idx);
      notifyListeners();
    }
  }

  /// Uploads new docs and updates the business_profiles row
  Future<void> updateProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final bucket = _supabase.storage.from('profiles-documents');
      final uploaded = <String>[];

      // 1) upload each new file
      for (final f in newDocs) {
        final ts   = DateTime.now().millisecondsSinceEpoch;
        final name = f.path.split('/').last;
        final path = 'business/$_uid/${ts}_$name';
        await bucket.upload(path, f);
        uploaded.add(bucket.getPublicUrl(path));
      }

      // 2) merge URLs
      final allUrls = [...existingDocUrls, ...uploaded];

      // 3) update DB
      await _supabase.from('business_profiles').update({
        'name'         : businessName,
        'registration_no'       : registrationNo,
        'country'               : country,
        'address'               : address,
        'description'           : description,
        'website'               : website,
        'registration_doc_urls' : allUrls,
      }).eq('uid', _uid);

      // 4) refresh local state
      existingDocUrls = allUrls;
      newDocs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
