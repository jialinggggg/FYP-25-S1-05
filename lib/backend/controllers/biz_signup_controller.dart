// lib/backend/controllers/biz_signup_controller.dart

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/business_profile.dart';

class BizSignupController {
  final SupabaseClient _supabase;
  BizSignupController(this._supabase);

  Future<void> execute({
    required String email,
    required String password,
    required BusinessProfile profile,
    required List<File> registrationDocuments,
  }) async {
    // 1) Sign up auth user
    final authRes = await _supabase.auth.signUp(email: email, password: password);
    final user = authRes.user;
    if (user == null) throw Exception('Sign up failed');
    final uid = user.id;

    // 2) Upload each document and collect URLs
    final bucket = _supabase.storage.from('profiles-documents');
    final List<String> urls = [];

    for (final file in registrationDocuments) {
      final filename = p.basename(file.path);
      final storagePath = 'business/$uid/$filename';

      // upload() returns the path as String
      await bucket.upload(storagePath, file);

      // getPublicUrl() returns the URL String directly
      final publicUrl = bucket.getPublicUrl(storagePath);
      urls.add(publicUrl);
    }

    // 3) Insert into accounts
    await _supabase.from('accounts').insert({
      'uid': uid,
      'email': email,
      'type': 'business',
      'status': 'pending',
    });

    // 4) Insert into business_profiles
    await _supabase.from('business_profiles').insert({
      'uid': uid,
      ...profile.toMap(),
      'registration_doc_urls': urls,
    });
  }
}
