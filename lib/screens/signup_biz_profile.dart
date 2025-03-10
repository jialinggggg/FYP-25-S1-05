import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/country_service.dart';
import '../utils/input_validator.dart';
import '../utils/dialog_utils.dart';
import 'signup_biz_detail.dart'; // Assuming this is the next screen

class SignupBizProfile extends StatefulWidget {
  const SignupBizProfile({super.key});

  @override
  SignupBizProfileState createState() => SignupBizProfileState();
}

class SignupBizProfileState extends State<SignupBizProfile> {
  // User input controllers
  final CountryService _countryService = CountryService();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessRegNoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _servicesDescriptionController = TextEditingController();
  String? _selectedCountry;
  String? _selectedServiceType; // Added for service type dropdown
  List<String> countries = [];

  // Service type options
  final List<String> serviceTypes = [
    "Dietitians & Nutritionists",
    "Food & Meal Providers",
  ];

  // Validation error states
  bool _isLoading = true;
  bool _businessNameError = false;
  bool _businessRegNoError = false;
  bool _serviceTypeError = false;
  bool _countryError = false;
  bool _addressError = false;
  bool _servicesDescriptionError = false;

  @override
  void initState() {
    super.initState();
    _fetchCountries(); // Load country list
    _businessNameController.addListener(() {
      if (_businessNameController.text.isNotEmpty) {
        setState(() => _businessNameError = false);
      }
    });
    _businessRegNoController.addListener(() {
      if (_businessRegNoController.text.isNotEmpty) {
        setState(() => _businessRegNoError = false);
      }
    });
    _addressController.addListener(() {
      if (_addressController.text.isNotEmpty) {
        setState(() => _addressError = false);
      }
    });
    _servicesDescriptionController.addListener(() {
      if (_servicesDescriptionController.text.isNotEmpty) {
        setState(() => _servicesDescriptionError = false);
      }
    });
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessRegNoController.dispose();
    _addressController.dispose();
    _servicesDescriptionController.dispose();
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
      _businessNameController.text,
      (error) => setState(() => _businessNameError = error),
      "Please enter your business name",
    );

    isValid &= InputValidator.validateField(
      _businessRegNoController.text,
      (error) => setState(() => _businessRegNoError = error),
      "Please enter your business registration number",
    );

    isValid &= InputValidator.validateField(
      _selectedServiceType,
      (error) => setState(() => _serviceTypeError = error),
      "Please select the type of services provided",
    );

    isValid &= InputValidator.validateField(
      _selectedCountry,
      (error) => setState(() => _countryError = error),
      "Please select your country",
    );

    isValid &= InputValidator.validateField(
      _addressController.text,
      (error) => setState(() => _addressError = error),
      "Please enter your business address",
    );

    isValid &= InputValidator.validateField(
      _servicesDescriptionController.text,
      (error) => setState(() => _servicesDescriptionError = error),
      "Please provide a brief description of your services",
    );

    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Title
                Center(
                  child: Text(
                    "Business Registration",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                // Progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    2,
                    (index) => Container(
                      width: 179,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index == 0 ? Colors.green : Colors.black,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Section title
                Text(
                  "Tell us about your business!",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Business Name Field
                Text(
                  "Business Name",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _businessNameController,
                  decoration: InputValidator.buildInputDecoration(
                    hintText: "Enter your business name",
                    hasError: _businessNameError,
                  ),
                ),
                if (_businessNameError)
                  InputValidator.buildErrorMessage("Please enter your business name"),
                const SizedBox(height: 20),

                // Business Registration No. Field
                Text(
                  "Business Registration No.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _businessRegNoController,
                  decoration: InputValidator.buildInputDecoration(
                    hintText: "Enter your business registration number",
                    hasError: _businessRegNoError,
                  ),
                ),
                if (_businessRegNoError)
                  InputValidator.buildErrorMessage("Please enter your business registration number"),
                const SizedBox(height: 20),

                // Country Selection Dropdown
                Text(
                  "Country",
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
                const SizedBox(height: 20),

                // Business Address Field
                Text(
                  "Business Address",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressController,
                  decoration: InputValidator.buildInputDecoration(
                    hintText: "Enter your business address",
                    hasError: _addressError,
                  ),
                ),
                if (_addressError)
                  InputValidator.buildErrorMessage("Please enter your business address"),
                const SizedBox(height: 20),

                // Type of Services Provided Dropdown
                Text(
                  "Type of Services Provided",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedServiceType,
                    items: serviceTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedServiceType = newValue;
                        _serviceTypeError = false;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Select the type of services provided",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    isExpanded: true, // Ensures the dropdown takes full width
                  ),
                ),
                if (_serviceTypeError)
                  InputValidator.buildErrorMessage("Please select the type of services provided"),
                const SizedBox(height: 20),

                // Brief Description of Services Field
                Text(
                  "Brief Description of Services",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _servicesDescriptionController,
                  maxLines: 3, // Allow multiple lines for description
                  decoration: InputValidator.buildInputDecoration(
                    hintText: "Provide a brief description of your services",
                    hasError: _servicesDescriptionError,
                  ),
                ),
                if (_servicesDescriptionError)
                  InputValidator.buildErrorMessage("Please provide a brief description of your services"),
                const SizedBox(height: 100), // Extra space for scrolling
              ],
            ),
          ),

          // Fixed Buttons at the Bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white, // Background color for the button area
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, size: 20),
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
                          builder: (context) => SignupBizDetail(
                            name: _businessNameController.text,
                            registration: _businessRegNoController.text,
                            country: _selectedCountry!,
                            address: _addressController.text,
                            type: _selectedServiceType!,
                            description: _servicesDescriptionController.text,
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
            ),
          ),
        ],
      ),
    );
  }
}