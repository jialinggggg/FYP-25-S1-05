// lib/backend/controllers/edit_profile_controller.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_profile.dart';

class EditProfileController extends ChangeNotifier {
  final SupabaseClient _supabase;
  final String userId;

  EditProfileController(this._supabase, this.userId) {
    loadProfile();
  }

  // --- State ---
  bool _isLoading = false;
  String? _error;

  String _name = '';
  String _country = '';
  String _gender = '';
  DateTime? _birthDate;
  double _weight = 0.0;
  double _height = 0.0;
  

  // --- Getters ---
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get name => _name;
  String get country => _country;
  String get gender => _gender;
  DateTime? get birthDate => _birthDate;
  double get weight => _weight;
  double get height => _height;

  // --- Setters ---
  set name(String v) { _name = v; notifyListeners(); }
  set country(String v) { _country = v; notifyListeners(); }
  set gender(String v) { _gender = v; notifyListeners(); }
  set birthDate(DateTime? v) { _birthDate = v; notifyListeners(); }
  set weight(double v) { _weight = v; notifyListeners(); }
  set height(double v) { _height = v; notifyListeners(); }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? v) { _error = v; notifyListeners(); }

  /// Load existing profile from Supabase into controller fields.
  Future<void> loadProfile() async {
    _setLoading(true);
    try {
      final resp = await _supabase
        .from('user_profiles')
        .select()
        .eq('uid', userId)
        .single();
      final p = UserProfile.fromMap(resp);

      _name      = p.name;
      _country   = p.country;
      _gender    = p.gender;
      _birthDate = p.birthDate;
      _weight    = p.weight;
      _height    = p.height;

      _setError(null);
    } catch (e) {
      _setError('Failed to load profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Push all fields back to Supabase.
  Future<void> updateProfile() async {
    _setLoading(true);
    try {
      final p = UserProfile(
        uid:       userId,
        name:      _name,
        country:   _country,
        gender:    _gender,
        birthDate: _birthDate!,
        weight:    _weight,
        height:    _height,
      );

      await _supabase
        .from('user_profiles')
        .update(p.toMap())
        .eq('uid', userId);

      _setError(null);
    } catch (e) {
      _setError('Failed to update profile: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
