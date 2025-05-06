import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nutri_app/backend/signup/input_validator.dart';

class EditAccountController extends ChangeNotifier {
  final SupabaseClient _supabase;
  final String userId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _email = '';
  String get email => _email;
  set email(String v) {
    _email = v;
    notifyListeners();
  }

  String _password = '';
  set password(String v) {
    _password = v;
    _passwordCriteria = InputValidator.validatePassword(v);
    notifyListeners();
  }

  Map<String, bool> _passwordCriteria = {
    'hasMinLength': false,
    'hasUppercase': false,
    'hasNumber': false,
    'hasSymbol': false,
  };
  Map<String, bool> get passwordCriteria => _passwordCriteria;

  EditAccountController(this._supabase, this.userId) {
    _loadCurrentEmail();
  }

  Future<void> _loadCurrentEmail() async {
    _setLoading(true);
    final user = _supabase.auth.currentUser;
    _email = user?.email ?? '';
    _setLoading(false);
  }

  Future<void> updateAccount() async {
    _setLoading(true);
    try {
      // 1) update Supabase Auth
      await _supabase.auth.updateUser(
        UserAttributes(
          email: _email,
          // only send password if they've entered one
          password: _password.isEmpty ? null : _password,
        ),
      );
      // 2) update your accounts table
      await _supabase
          .from('accounts')
          .update({'email': _email})
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update account: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
