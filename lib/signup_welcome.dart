import 'package:flutter/material.dart';
import 'signup_you.dart'; // Make sure to import this correctly
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  // Fetch country data from the REST API
  Future<void> _fetchCountries() async {
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

        // Check if the widget is still mounted before updating the state
        if (mounted) {
          setState(() {
            countries = countryNames;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (e) {
      // Check if the widget is still mounted before showing the error
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

            // Dropdown for selecting country with a box around it
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey), // Adds border around the dropdown
                borderRadius: BorderRadius.circular(8), // Optional: rounds the corners
              ),
              child: _isLoading
                  ? Center(child: CircularProgressIndicator()) // Show loading indicator while data is being fetched
                  : DropdownButton<String>(
                      value: _selectedCountry,
                      hint: Text("Select your country"),
                      isExpanded: true, // Ensures the dropdown expands to fill the width of the container
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCountry = newValue;
                        });
                      },
                      items: countries.map<DropdownMenuItem<String>>((String country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(country),
                          ),
                        );
                      }).toList(),
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
                    // Validate inputs
                    if (_nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter your name')),
                      );
                      return;
                    }
                    if (_selectedCountry == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select your country')),
                      );
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