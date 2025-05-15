import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../backend/signup/nutri_signup_state.dart';

class SignupNutritionistScreen extends StatefulWidget {
  const SignupNutritionistScreen({super.key});

  @override
  SignupNutritionistScreenState createState() => SignupNutritionistScreenState();
}

class SignupNutritionistScreenState extends State<SignupNutritionistScreen> {
  final _fullNameController      = TextEditingController();
  final _organizationController  = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _issuingBodyController   = TextEditingController();

  String? _fullNameError;
  String? _licenseNumberError;
  String? _issuingBodyError;
  String? _issuanceDateError;
  String? _expirationDateError;
  String? _scansError;

  @override
  void initState() {
    super.initState();
    final state = context.read<NutritionistSignupState>();

    _fullNameController.addListener(() {
      if (_fullNameController.text.isNotEmpty) {
        setState(() => _fullNameError = null);
      }
      state.setFullName(_fullNameController.text);
    });
    _organizationController.addListener(() {
      state.setOrganization(_organizationController.text);
    });
    _licenseNumberController.addListener(() {
      if (_licenseNumberController.text.isNotEmpty) {
        setState(() => _licenseNumberError = null);
      }
      state.setLicenseNumber(_licenseNumberController.text);
    });
    _issuingBodyController.addListener(() {
      if (_issuingBodyController.text.isNotEmpty) {
        setState(() => _issuingBodyError = null);
      }
      state.setIssuingBody(_issuingBodyController.text);
    });
  }

  Future<void> _pickScans() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final files = result.paths
          .where((p) => p != null)
          .map((p) => File(p!))
          .toList();
      if (files.isNotEmpty && mounted) {
        context.read<NutritionistSignupState>().setLicenseScans(files);
        setState(() => _scansError = null);
      }
    }
  }

  Future<void> _selectDate({
    required bool isIssuance,
  }) async {
    final state = context.read<NutritionistSignupState>();
    final now = DateTime.now();

    final initial = isIssuance
        ? (state.issuanceDate ?? now)
        : (state.expirationDate ?? (state.issuanceDate?.add(Duration(days: 1)) ?? now.add(Duration(days: 1))));

    final firstDate = isIssuance
        ? DateTime(1900)
        : (state.issuanceDate ?? now);

    final lastDate = isIssuance ? now : DateTime(2100);

    // Ensure initial is within valid range
    final safeInitial = initial.isBefore(firstDate)
        ? firstDate
        : (initial.isAfter(lastDate) ? lastDate : initial);

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      if (isIssuance) {
        state.setIssuanceDate(picked);
        setState(() => _issuanceDateError = null);
      } else {
        state.setExpirationDate(picked);
        setState(() => _expirationDateError = null);
      }
    }
  }

  void _validateAndNext() {
    final state = context.read<NutritionistSignupState>();
    setState(() {
      _fullNameError       =
          _fullNameController.text.isEmpty ? 'Please enter full name' : null;
      _licenseNumberError  = _licenseNumberController.text.isEmpty
          ? 'Please enter license number'
          : null;
      _issuingBodyError    = _issuingBodyController.text.isEmpty
          ? 'Please enter issuing body'
          : null;
      _issuanceDateError   = state.issuanceDate == null
          ? 'Please select issuance date'
          : null;
      _expirationDateError = state.expirationDate == null
          ? 'Please select expiration date'
          : null;
      _scansError = state.licenseScans.isEmpty
          ? 'Please upload at least one scan'
          : null;
    });

    final errors = [
      _fullNameError,
      _licenseNumberError,
      _issuingBodyError,
      _issuanceDateError,
      _expirationDateError,
      _scansError,
    ];

    if (errors.every((e) => e == null)) {
      Navigator.pushNamed(context, '/nutri_signup_detail');

    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NutritionistSignupState>();

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
                  "Nutritionist Sign Up",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  2,
                  (index) => Container(
                    width: 175,
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
              Text(
                "Tell us about your credentials",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _fullNameController,
                label: "Full Name",
                hint: "Enter full name",
                errorText: _fullNameError,
              ),
              _buildTextField(
                controller: _organizationController,
                label: "Company / Organization (optional)",
                hint: "Enter organization",
              ),
              _buildTextField(
                controller: _licenseNumberController,
                label: "License No. / Registration ID",
                hint: "Enter license number",
                errorText: _licenseNumberError,
              ),
              _buildTextField(
                controller: _issuingBodyController,
                label: "Issuing Body",
                hint: "e.g. State Board, Dietetic Assoc.",
                errorText: _issuingBodyError,
              ),
              const SizedBox(height: 20),

              // Issuance Date
              Text("Issuance Date", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(
                        text: state.issuanceDate == null
                            ? ''
                            : state.issuanceDate!.toLocal().toIso8601String().split('T').first,
                      ),
                      decoration: InputDecoration(
                        hintText: "Select issuance date",
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(isIssuance: true),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(isIssuance: true),
                  ),
                ],
              ),
              if (_issuanceDateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(_issuanceDateError!, style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 20),

              // Expiration Date
              Text("Expiration Date", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(
                        text: state.expirationDate == null
                            ? ''
                            : state.expirationDate!.toLocal().toIso8601String().split('T').first,
                      ),
                      decoration: InputDecoration(
                        hintText: "Select expiration date",
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(isIssuance: false),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(isIssuance: false),
                  ),
                ],
              ),
              if (_expirationDateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(_expirationDateError!, style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 30),

              Text("Upload License Scans", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: Icon(Icons.attach_file, color: Colors.green),
                  label: Text(
                    "Choose Files",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _pickScans,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (state.licenseScans.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: state.licenseScans
                        .map((f) => Text(f.path.split('/').last))
                        .toList(),
                  ),
                ),
              if (_scansError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(_scansError!, style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 10),
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
