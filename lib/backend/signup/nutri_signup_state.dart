import 'dart:io';
import 'package:flutter/foundation.dart';

class NutritionistSignupState extends ChangeNotifier {
  String _fullName = '';
  String _organization = '';
  String _licenseNumber = '';
  String _issuingBody = '';
  DateTime? _issuanceDate;
  DateTime? _expirationDate;
  List<File> _licenseScans = [];

  // --- Getters ---
  String get fullName        => _fullName;
  String get organization    => _organization;
  String get licenseNumber   => _licenseNumber;
  String get issuingBody     => _issuingBody;
  DateTime? get issuanceDate => _issuanceDate;
  DateTime? get expirationDate => _expirationDate;
  List<File> get licenseScans => _licenseScans;

  // --- Setters ---
  void setFullName(String v) {
    _fullName = v;
    notifyListeners();
  }

  void setOrganization(String v) {
    _organization = v;
    notifyListeners();
  }

  void setLicenseNumber(String v) {
    _licenseNumber = v;
    notifyListeners();
  }

  void setIssuingBody(String v) {
    _issuingBody = v;
    notifyListeners();
  }

  void setIssuanceDate(DateTime d) {
    _issuanceDate = d;
    notifyListeners();
  }

  void setExpirationDate(DateTime d) {
    _expirationDate = d;
    notifyListeners();
  }

  void setLicenseScans(List<File> files) {
    _licenseScans = files;
    notifyListeners();
  }

  /// Reset all fields
  void reset() {
    _fullName = '';
    _organization = '';
    _licenseNumber = '';
    _issuingBody = '';
    _issuanceDate = null;
    _expirationDate = null;
    _licenseScans = [];
    notifyListeners();
  }
}
