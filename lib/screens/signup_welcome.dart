// lib/screens/signup_welcome.dart
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart'; // Import the package
import '../services/country_service.dart'; // Import the CountryService
import '../utils/input_validator.dart'; // Import the InputValidator
import 'signup_you.dart'; // Import the next page

class SignupWelcome extends StatefulWidget {
  const SignupWelcome({super.key});

  @override
  SignupNameState createState() => SignupNameState();
}

class SignupNameState extends State<SignupWelcome> {
  String? _selectedCountry;
  List<String> countries = [];
  final _nameController = TextEditingController(); // Controller for the name field
  bool _isLoading = true; // Track loading state for countries
  final CountryService _countryService = CountryService(); // Create an instance of CountryService

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  // Fetch country data using CountryService
  Future<void> _fetchCountries() async {
    try {
      final countryNames = await _countryService.fetchCountries();
      if (mounted) {
        setState(() {
          countries = countryNames;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching countries: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome text
            Center(
              child: Text(
                "Welcome",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                6,
                (index) => Container(
                  width: 55,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == 0 ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Left-aligned text sections
            Text(
              "Let’s get to know you!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Preferred name label
            Text(
              "What should we call you?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Text field for name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your preferred name",
              ),
            ),
            const SizedBox(height: 30),

            // Location label
            Text(
              "Where are you from?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // DropdownSearch for selecting country
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey), // Adds border around the dropdown
                borderRadius: BorderRadius.circular(8), // Optional: rounds the corners
              ),
              child: _isLoading
                  ? Center(child: CircularProgressIndicator()) // Show loading indicator while data is being fetched
                  : DropdownSearch<String>(
                      popupProps: PopupProps.menu(
                        showSearchBox: true, // Enable search functionality
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: "Search for a country",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      items: countries,
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          hintText: "Select your country",
                          border: InputBorder.none,
                        ),
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCountry = newValue;
                        });
                      },
                      selectedItem: _selectedCountry,
                    ),
            ),
            const SizedBox(height: 30),

            const Spacer(),

            // Back and Next buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 30),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                // Next button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 135, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  onPressed: () {
                    // Validate inputs using InputValidator
                    if (InputValidator.isFieldEmpty(_nameController.text, context, 'name')) {
                      return;
                    }
                    if (InputValidator.isFieldEmpty(_selectedCountry, context, 'country')) {
                      return;
                    }

                    // Navigate to the SignupYou screen with the collected data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignupYou(
                          name: _nameController.text,
                          location: _selectedCountry!,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    "Next",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}