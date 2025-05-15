// lib/frontend/app/business/signup/signup_biz_profile.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';

import '../../../services/country_service.dart';
import '../../../backend/signup/biz_signup_state.dart';
import '../../../utils/dialog_utils.dart';

class SignupBizProfileScreen extends StatefulWidget {
  const SignupBizProfileScreen({super.key});

  @override
  SignupBizProfileScreenState createState() => SignupBizProfileScreenState();
}

class SignupBizProfileScreenState extends State<SignupBizProfileScreen> {
  final CountryService _countryService = CountryService();

  // Controllers
  final _businessNameController   = TextEditingController();
  final _registrationNoController = TextEditingController();
  final _addressController        = TextEditingController();
  final _descriptionController    = TextEditingController();
  final _websiteController        = TextEditingController();

  List<String> _countries = [];
  bool _isLoading = true;

  // Validation errors
  String? _businessNameError;
  String? _registrationNoError;
  String? _countryError;
  String? _addressError;
  String? _descriptionError;
  String? _documentsError;

  List<File> _registrationDocuments = [];

  @override
  void initState() {
    super.initState();
    _fetchCountries();

    final state = context.read<BusinessSignupState>();
    _businessNameController.addListener(() {
      if (_businessNameController.text.isNotEmpty) {
        setState(() => _businessNameError = null);
      }
      state.setBusinessName(_businessNameController.text);
    });
    _registrationNoController.addListener(() {
      if (_registrationNoController.text.isNotEmpty) {
        setState(() => _registrationNoError = null);
      }
      state.setRegistrationNo(_registrationNoController.text);
    });
    _addressController.addListener(() {
      if (_addressController.text.isNotEmpty) {
        setState(() => _addressError = null);
      }
      state.setBusinessAddress(_addressController.text);
    });
    _descriptionController.addListener(() {
      if (_descriptionController.text.isNotEmpty) {
        setState(() => _descriptionError = null);
      }
      state.setBusinessDescription(_descriptionController.text);
    });
    _websiteController.addListener(() {
      state.setWebsite(_websiteController.text);
    });
  }

  Future<void> _fetchCountries() async {
    try {
      final list = await _countryService.fetchCountries();
      if (!mounted) return;
      setState(() {
        _countries = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      DialogUtils.showErrorDialog(
        context: context,
        message: 'Error fetching countries: $e',
      );
    }
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (!mounted) return;
    if (result != null) {
      final files = result.paths
          .whereType<String>()
          .map((path) => File(path))
          .toList();
      setState(() {
        _registrationDocuments = files;
        _documentsError = null;
      });
      context.read<BusinessSignupState>().setRegistrationDocs(files);
    }
  }

  void _validateAndNext() {
    final state = context.read<BusinessSignupState>();
    setState(() {
      _businessNameError   = state.businessName.isEmpty         ? 'Please enter business name' : null;
      _registrationNoError = state.registrationNo.isEmpty       ? 'Please enter registration number' : null;
      _countryError        = state.businessCountry.isEmpty      ? 'Please select country' : null;
      _addressError        = state.businessAddress.isEmpty      ? 'Please enter address' : null;
      _descriptionError    = state.businessDescription.isEmpty  ? 'Please enter a description' : null;
      _documentsError      = _registrationDocuments.isEmpty      ? 'Please upload registration documents' : null;
    });

    if ([
      _businessNameError,
      _registrationNoError,
      _countryError,
      _addressError,
      _descriptionError,
      _documentsError
    ].every((e) => e == null)) {
      Navigator.pushNamed(context, '/signup_biz_contact');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BusinessSignupState>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Business Sign Up",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Container(
                  width: 116,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == 0 ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
              ),
              const SizedBox(height: 30),

              Text(
                "Tell us about your business",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _businessNameController,
                label: "Business Name",
                hint: "Enter business name",
                errorText: _businessNameError,
              ),
              _buildTextField(
                controller: _registrationNoController,
                label: "Registration No.",
                hint: "Enter registration number",
                errorText: _registrationNoError,
              ),
              Text("Country of Operation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
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
                              hintText: "Search country",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        items: _countries,
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            hintText: "Select country",
                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                            border: InputBorder.none,
                          ),
                        ),
                        selectedItem: state.businessCountry.isEmpty
                            ? null
                            : state.businessCountry,
                        onChanged: (val) {
                          if (val != null) {
                            state.setBusinessCountry(val);
                            setState(() => _countryError = null);
                          }
                        },
                      ),
                    ),
              if (_countryError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(_countryError!, style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _addressController,
                label: "Business Address",
                hint: "Enter address",
                errorText: _addressError,
              ),
              _buildTextField(
                controller: _descriptionController,
                label: "Business Description",
                hint: "Describe your business",
                errorText: _descriptionError,
              ),
              _buildTextField(
                controller: _websiteController,
                label: "Website / Social Media (Optional)",
                hint: "Enter URL(s)",
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),
              Text("Upload Registration Documents", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: Icon(Icons.attach_file, color: Colors.green),
                  label: Text(
                    "Choose Files",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _pickDocuments,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              for (var f in _registrationDocuments)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(f.path.split('/').last),
                ),
              if (_documentsError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(_documentsError!, style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height:10), // Spacer to avoid hiding fields under buttons
            ],
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: _validateAndNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 135, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
              ),
              child: Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(errorText, style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
