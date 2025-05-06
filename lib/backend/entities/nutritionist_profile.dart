// lib/backend/entities/nutritionist_profile.dart
class NutritionistProfile {
  final String fullName;
  final String? organization;
  final String licenseNumber;
  final String issuingBody;
  final DateTime issuanceDate;
  final DateTime expirationDate;
  final List<String> licenseScanUrls;

  NutritionistProfile({
    required this.fullName,
    this.organization,
    required this.licenseNumber,
    required this.issuingBody,
    required this.issuanceDate,
    required this.expirationDate,
    required this.licenseScanUrls,
  });

  Map<String, dynamic> toMap() => {
    'full_name': fullName,
    'organization': organization,
    'license_number': licenseNumber,
    'issuing_body': issuingBody,
    'issuance_date': issuanceDate.toIso8601String().split('T').first,
    'expiration_date': expirationDate.toIso8601String().split('T').first,
    'license_scan_urls': licenseScanUrls,
  };
}
