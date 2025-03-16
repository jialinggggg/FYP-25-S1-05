// lib/services/country_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class CountryService {
  // List of prioritized endpoints (primary + backups)
  static const List<String> _endpoints = [
    'https://restcountries.com/v3.1/all',
    'https://restcountries.com/v3.1.1/all',
    'https://countriesnow.space/api/v0.1/countries/info?returns=name',
    'https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/countries.json'
  ];

  Future<List<String>> fetchCountries() async {
    final List<String> countryNames = [];
    Exception? lastError;

    // Try each endpoint in order
    for (final endpoint in _endpoints) {
      try {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> countryList = _parseResponse(endpoint, response.body);
          
          for (var country in countryList) {
            final name = _extractCountryName(endpoint, country);
            if (name != null) countryNames.add(name);
          }
          
          countryNames.sort();
          return countryNames;
        }
      } catch (e) {
        lastError = Exception('Failed endpoint $endpoint: $e');
        // Continue to next endpoint on error
      }
    }

    throw lastError ?? Exception('All endpoints failed');
  }

  List<dynamic> _parseResponse(String endpoint, String body) {
    try {
      final jsonData = json.decode(body);
      
      // Handle different response formats
      switch (endpoint) {
        case String s when s.contains('countriesnow.space'):
          return jsonData['data'] as List<dynamic>;
        case String s when s.contains('raw.githubusercontent.com'):
          return jsonData as List<dynamic>;
        default: // restcountries.com format
          return jsonData as List<dynamic>;
      }
    } catch (e) {
      throw Exception('Failed to parse response from $endpoint: $e');
    }
  }

  String? _extractCountryName(String endpoint, dynamic countryData) {
    try {
      if (endpoint.contains('countriesnow.space')) {
        return countryData['name'] as String?;
      }
      if (endpoint.contains('raw.githubusercontent.com')) {
        return countryData['name'] as String?;
      }
      // Default restcountries.com format
      return countryData['name']['common'] as String?;
    } catch (e) {
      return null;
    }
  }
}