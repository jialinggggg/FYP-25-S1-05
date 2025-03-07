import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/country_service.dart';
import '../utils/input_validator.dart';
import '../utils/dialog_utils.dart';
import 'signup_you.dart';

class SignupWelcome extends StatefulWidget {
  const SignupWelcome({super.key});

  @override
  SignupWelcomeState createState() => SignupWelcomeState();
}

class SignupWelcomeState extends State<SignupWelcome> {
  // User input controllers
  final CountryService _countryService = CountryService();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedCountry;
  List<String> countries = [];

  // Validation error states
  bool _isLoading = true;
  bool _nameError = false;
  bool _countryError = false;

  @override
  void initState() {
    super.initState();
    _fetchCountries(); // Load country list
    _nameController.addListener(() {
      if (_nameController.text.isNotEmpty) {
        setState(() => _nameError = false);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Fetch list of countries from service
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
        setState(() => _isLoading = false);
        DialogUtils.showErrorDialog(
          context: context,
          message: 'Error fetching countries: $e',
        );
      }
    }
  }

  // Validate user inputs
  bool _validateInputs() {
    bool isValid = true;

    isValid &= InputValidator.validateField(
      _nameController.text,
      (error) => setState(() => _nameError = error),
      "Please enter your name",
    );

    isValid &= InputValidator.validateField(
      _selectedCountry,
      (error) => setState(() => _countryError = error),
      "Please select your country",
    );

    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            Center(
              child: Text(
                "Welcome",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator (step 1 of 6)
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

            // Section title
            Text(
              "Let’s get to know you!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Name Field
            Text(
              "What should we call you?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputValidator.buildInputDecoration(
                hintText: "Enter your preferred name",
                hasError: _nameError,
              ),
            ),
            if (_nameError)
              InputValidator.buildErrorMessage("Please enter your name"),
            const SizedBox(height: 30),

            // Country Selection Dropdown
            Text(
              "Where are you from?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator()) // Show loading spinner
                : Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownSearch<String>(
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
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
                          _countryError = false;
                        });
                      },
                      selectedItem: _selectedCountry,
                    ),
                  ),
            if (_countryError)
              InputValidator.buildErrorMessage("Please select your country"),
            const SizedBox(height: 30),

            const Spacer(), // Pushes button to bottom

            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 135, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  onPressed: () {
                    if (!_validateInputs()) return; // Stop if inputs are invalid
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
