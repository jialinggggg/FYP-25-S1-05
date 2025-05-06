import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../../services/country_service.dart';
import '../../../../backend/signup/signup_state.dart';
import '../../../../backend/signup/input_validation_service.dart';
import '../../../../utils/dialog_utils.dart';

class SignupWelcome extends StatefulWidget {
  const SignupWelcome({super.key});

  @override
  SignupWelcomeState createState() => SignupWelcomeState();
}

class SignupWelcomeState extends State<SignupWelcome> {
  final CountryService _countryService = CountryService();
  final TextEditingController _nameController = TextEditingController();
  final InputValidationService _validationService = InputValidationService();
  List<String> countries = [];
  bool _isLoading = true;
  String? _nameError;
  String? _countryError;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
    _nameController.addListener(() {
      if (_nameController.text.isNotEmpty) {
        setState(() => _nameError = null);
      }
      context.read<SignupState>().setName(_nameController.text);
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final signupState = context.watch<SignupState>();

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

            // Progress indicator (step 1 of 7)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                7,
                (index) => Container(
                  width: 40,
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
              "Let's get to know you!",
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
              decoration: InputDecoration(
                hintText: "Enter your name",
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (_nameError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _nameError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),

            // Country Selection Dropdown
            Text(
              "Where are you from?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
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
                        if (newValue != null) {
                          signupState.setCountry(newValue);
                          setState(() => _countryError = null);
                        }
                      },
                      selectedItem: signupState.country.isEmpty ? null : signupState.country,
                    ),
                  ),
            if (_countryError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _countryError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 30),

            const Spacer(),

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
                    final error = _validationService.validateBasicInfo(
                      signupState.name,
                      signupState.country,
                    );
                    
                    if (error != null) {
                      setState(() {
                        _nameError = signupState.name.isEmpty ? 'Please enter your name' : null;
                        _countryError = signupState.country.isEmpty ? 'Please select your country' : null;
                      });
                    } else {
                      Navigator.pushNamed(context, '/signup_you');
                    }
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