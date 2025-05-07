import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Controller to edit the business contact person
class EditBusinessContactController extends ChangeNotifier {
  final SupabaseClient _supabase;
  final String _uid;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String contactName;
  String contactRole;
  String contactEmail;

  EditBusinessContactController(
      this._supabase,
      this._uid,
      {
        required this.contactName,
        required this.contactRole,
        required this.contactEmail,
      });

  /// Persist contact changes
  Future<void> updateContact() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('business_profiles').update({
        'contact_name'  : contactName,
        'contact_role'  : contactRole,
        'contact_email' : contactEmail,
      }).eq('uid', _uid);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
