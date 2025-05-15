// lib/backend/signup/biz_signup_state.dart

import 'dart:io';
import 'package:flutter/foundation.dart';

class BusinessSignupState extends ChangeNotifier {
  String _businessName          = '';
  String _registrationNo        = '';
  String _businessCountry       = '';
  String _businessAddress       = '';
  String _businessDescription   = '';      // ← new
  String _contactName           = '';
  String _contactRole           = '';
  String _contactEmail          = '';
  String _website               = '';
  List<File> _registrationDocs  = [];      // ← list of files

  // Getters
  String get businessName         => _businessName;
  String get registrationNo       => _registrationNo;
  String get businessCountry      => _businessCountry;
  String get businessAddress      => _businessAddress;
  String get businessDescription  => _businessDescription;
  String get contactName          => _contactName;
  String get contactRole          => _contactRole;
  String get contactEmail         => _contactEmail;
  String get website              => _website;
  List<File> get registrationDocs => _registrationDocs;

  // Setters / updaters
  void setBusinessName(String v)        { _businessName = v; notifyListeners(); }
  void setRegistrationNo(String v)      { _registrationNo = v; notifyListeners(); }
  void setBusinessCountry(String v)     { _businessCountry = v; notifyListeners(); }
  void setBusinessAddress(String v)     { _businessAddress = v; notifyListeners(); }
  void setBusinessDescription(String v) { _businessDescription = v; notifyListeners(); } // ← new
  void setContactName(String v)         { _contactName = v; notifyListeners(); }
  void setContactRole(String v)         { _contactRole = v; notifyListeners(); }
  void setContactEmail(String v)        { _contactEmail = v; notifyListeners(); }
  void setWebsite(String v)             { _website = v; notifyListeners(); }
  void setRegistrationDocs(List<File> f){ _registrationDocs = f; notifyListeners(); } // ← new

  /// Reset everything
  void reset() {
    _businessName         = '';
    _registrationNo       = '';
    _businessCountry      = '';
    _businessAddress      = '';
    _businessDescription  = '';
    _contactName          = '';
    _contactRole          = '';
    _contactEmail         = '';
    _website              = '';
    _registrationDocs     = [];
    notifyListeners();
  }
}
