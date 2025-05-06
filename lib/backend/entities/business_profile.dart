// lib/backend/entities/business_profile.dart

class BusinessProfile {
  final String businessName;
  final String registrationNo;
  final String country;
  final String address;
  final String description;            // ← new
  final String contactName;
  final String contactRole;
  final String contactEmail;
  final String website;
  final List<String> registrationDocUrls; // ← list of URLs

  BusinessProfile({
    required this.businessName,
    required this.registrationNo,
    required this.country,
    required this.address,
    required this.description,         // ← new
    required this.contactName,
    required this.contactRole,
    required this.contactEmail,
    required this.website,
    required this.registrationDocUrls,
  });

  Map<String, dynamic> toMap() => {
    'name': businessName,
    'registration_no': registrationNo,
    'country': country,
    'address': address,
    'description': description,       // ← new
    'contact_name': contactName,
    'contact_role': contactRole,
    'contact_email': contactEmail,
    'website': website,
    'registration_doc_urls': registrationDocUrls,
  };
}
