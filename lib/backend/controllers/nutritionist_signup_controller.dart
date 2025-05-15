// lib/backend/controllers/nutritionist_signup_controller.dart

import 'dart:io';
import 'package:path/path.dart' as p;  
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/nutritionist_profile.dart';

class NutritionistSignupController {
  final SupabaseClient _supabase;
  NutritionistSignupController(this._supabase);

  Future<void> execute({
    required String email,
    required String password,
    required NutritionistProfile profile,
    required List<File> licenseScans,
  }) async {
    // 1) Create auth user
    final authRes = await _supabase.auth.signUp(email: email, password: password);
    final user = authRes.user;
    if (user == null) {
      throw Exception('Sign up failed');
    }
    final uid = user.id;

    // 2) Upload each scan and collect the public URLs
    final bucket = _supabase.storage.from('profiles-documents');
    final List<String> urls = [];

    for (final file in licenseScans) {
      final filename = p.basename(file.path);
      final storagePath = 'nutritionist/$uid/$filename';

      // upload() returns the path as String (or throws)
      await bucket.upload(storagePath, file);

      // getPublicUrl() returns the URL String directly
      final publicUrl = bucket.getPublicUrl(storagePath);
      urls.add(publicUrl);
    }

    // 3) Insert into accounts
    await _supabase.from('accounts').insert({
      'uid': uid,
      'email': email,
      'type': 'nutritionist',
      'status': 'pending',
    });

    // 4) Insert into nutritionist_profiles
    await _supabase.from('nutritionist_profiles').insert({
      'uid': uid,
      ...profile.toMap(),
      'license_scan_urls': urls,
    });
  }
}
