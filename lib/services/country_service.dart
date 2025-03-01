// lib/services/country_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class CountryService {
  // Fetch country data from the REST API
  Future<List<String>> fetchCountries() async {
    try {
      final response = await http.get(Uri.parse('https://restcountries.com/v3.1/all'));

      if (response.statusCode == 200) {
        final List<dynamic> countryList = json.decode(response.body);
        List<String> countryNames = [];
        for (var country in countryList) {
          if (country['name'] != null && country['name']['common'] != null) {
            countryNames.add(country['name']['common']);
          }
        }
        countryNames.sort(); // Sort countries in ascending order
        return countryNames;
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (e) {
      throw Exception('Error fetching countries: $e');
    }
  }
}