import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../backend/signup/nutri_signup_state.dart';

class SignupNutritionistScreen extends StatefulWidget {
  const SignupNutritionistScreen({Key? key}) : super(key: key);

  @override
  _SignupNutritionistScreenState createState() =>
      _SignupNutritionistScreenState();
}

class _SignupNutritionistScreenState extends State<SignupNutritionistScreen> {
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
      if (files.isNotEmpty) {
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
        ? state.issuanceDate ?? now
        : (state.expirationDate ?? now);
    final firstDate = isIssuance
        ? DateTime(1900)
        : (state.issuanceDate ?? DateTime(1900));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime(2100),
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

    String _formatDate(DateTime? dt) =>
        dt != null ? dt.toLocal().toIso8601String().split('T').first : 'Select';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Center(
                child: Text(
                  "Nutritionist Sign Up",
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

              Text(
                "Tell us about your credentials",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Full Name
              _buildTextField(
                controller: _fullNameController,
                label: "Full Name",
                hint: "Enter full name",
                errorText: _fullNameError,
              ),

              // Organization (optional)
              _buildTextField(
                controller: _organizationController,
                label: "Company / Organization (optional)",
                hint: "Enter organization",
              ),

              // License Number
              _buildTextField(
                controller: _licenseNumberController,
                label: "License No. / Registration ID",
                hint: "Enter license number",
                errorText: _licenseNumberError,
              ),

              // Issuing Body
              _buildTextField(
                controller: _issuingBodyController,
                label: "Issuing Body",
                hint: "e.g. State Board, Dietetic Assoc.",
                errorText: _issuingBodyError,
              ),

              // Issuance Date
              const SizedBox(height: 20),
              Text("Issuance Date",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _selectDate(isIssuance: true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_formatDate(state.issuanceDate)),
                ),
              ),
              if (_issuanceDateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(_issuanceDateError!,
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),

              // Expiration Date
              const SizedBox(height: 20),
              Text("Expiration Date",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _selectDate(isIssuance: false),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_formatDate(state.expirationDate)),
                ),
              ),
              if (_expirationDateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(_expirationDateError!,
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),

              // Upload scans
              const SizedBox(height: 30),
              Text("Upload License Scans",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickScans,
                icon: Icon(Icons.attach_file),
                label: Text("Choose Files"),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
                  child: Text(_scansError!,
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),

              const SizedBox(height: 40),

              // Navigation Buttons
              Row(
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40)),
                    ),
                    child:
                        Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
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
