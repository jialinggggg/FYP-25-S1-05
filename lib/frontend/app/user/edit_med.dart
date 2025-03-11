import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../utils/widget_utils.dart';
import '../../../backend/utils/input_validator.dart';
import '../../../../utils/dialog_utils.dart';
import '../../../backend/supabase/user_medical_service.dart'; // Ensure this import is correct

class EditMedicalHistoryScreen extends StatefulWidget {
  final VoidCallback onUpdate;

  const EditMedicalHistoryScreen({super.key, required this.onUpdate});

  @override
  EditMedicalHistoryScreenState createState() => EditMedicalHistoryScreenState();
}

class EditMedicalHistoryScreenState extends State<EditMedicalHistoryScreen> {
  final UserMedicalService _userMedicalService = UserMedicalService(Supabase.instance.client); // Initialize UserMedicalService

  final TextEditingController _preExistingController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();

  String? _preExistingDropdownValue;
  String? _allergiesDropdownValue;

  bool _preExistingError = false;
  bool _allergiesError = false;
  bool _preExistingInputError = false;
  bool _allergiesInputError = false;

  @override
  void initState() {
    super.initState();
    _fetchMedicalHistoryData();
  }

  Future<void> _fetchMedicalHistoryData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Use UserMedicalService to fetch medical history
      final medicalHistory = await _userMedicalService.fetchMedical(userId);
      if (!mounted) return;

      // Add null checks for medicalHistory
      if (medicalHistory != null) {
        setState(() {
          // Handle pre-existing conditions
          final preExisting = medicalHistory['pre_existing'];
          if (preExisting == 'NA' || preExisting?.isEmpty == true) {
            _preExistingDropdownValue = 'No';
            _preExistingController.text = '';
          } else {
            _preExistingDropdownValue = 'Yes';
            _preExistingController.text = preExisting ?? "";
          }

          // Handle allergies
          final allergies = medicalHistory['allergies'];
          if (allergies == 'NA' || allergies?.isEmpty == true) {
            _allergiesDropdownValue = 'No';
            _allergiesController.text = '';
          } else {
            _allergiesDropdownValue = 'Yes';
            _allergiesController.text = allergies ?? "";
          }
        });
      } else {
        // Handle the case where medicalHistory is null
        setState(() {
          _preExistingDropdownValue = 'No';
          _preExistingController.text = '';
          _allergiesDropdownValue = 'No';
          _allergiesController.text = '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      DialogUtils.showErrorDialog(
        context: context,
        message: 'Error fetching medical history: $e',
      );
    }
  }

  bool _validateInputs() {
    bool isValid = true;

    isValid &= InputValidator.validateField(
      _preExistingDropdownValue,
      (error) => setState(() => _preExistingError = error),
      "Please select an option",
    );

    if (_preExistingDropdownValue == 'Yes') {
      isValid &= InputValidator.validateField(
        _preExistingController.text,
        (error) => setState(() => _preExistingInputError = error),
        "Please enter your pre-existing conditions",
      );
    }

    isValid &= InputValidator.validateField(
      _allergiesDropdownValue,
      (error) => setState(() => _allergiesError = error),
      "Please select an option",
    );

    if (_allergiesDropdownValue == 'Yes') {
      isValid &= InputValidator.validateField(
        _allergiesController.text,
        (error) => setState(() => _allergiesInputError = error),
        "Please enter your allergies",
      );
    }

    return isValid;
  }

  Future<void> _updateMedicalHistory() async {
    if (!_validateInputs()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _userMedicalService.updateMedical(
        uid: userId,
        preExisting: _preExistingDropdownValue == 'Yes' ? _preExistingController.text : 'NA',
        allergies: _allergiesDropdownValue == 'Yes' ? _allergiesController.text : 'NA',
      );

      if (!mounted) return;

      DialogUtils.showSuccessDialog(
        context: context,
        message: 'Medical history updated successfully.',
        onOkPressed: () {
          Navigator.pop(context); // Close the dialog
          widget.onUpdate(); // Notify the parent screen to refresh
          Navigator.pop(context); // Navigate back to the previous screen
        },
      );
    } catch (e) {
      if (!mounted) return;
      DialogUtils.showErrorDialog(
        context: context,
        message: 'Error updating medical history: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Medical History'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pre-existing Conditions Dropdown
            WidgetUtils.buildDropdown(
              label: "Pre-existing conditions:",
              value: _preExistingDropdownValue,
              items: const ['No', 'Yes'],
              onChanged: (String? newValue) {
                setState(() {
                  _preExistingDropdownValue = newValue;
                  _preExistingError = false;
                });
              },
              hasError: _preExistingError,
              errorMessage: "Please select an option",
            ),
            const SizedBox(height: 10),

            if (_preExistingDropdownValue == 'Yes')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Please list your pre-existing conditions (separate with ',' if more than one):",
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _preExistingController,
                    decoration: InputDecoration(
                      hintText: "e.g., Diabetes, Hypertension",
                      errorText: _preExistingInputError ? "Please enter your pre-existing conditions" : null,
                    ),
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      setState(() {
                        _preExistingInputError = false;
                      });
                    },
                  ),
                ],
              ),
            const SizedBox(height: 25),

            // Allergies Dropdown
            WidgetUtils.buildDropdown(
              label: "Known Allergies:",
              value: _allergiesDropdownValue,
              items: const ['No', 'Yes'],
              onChanged: (String? newValue) {
                setState(() {
                  _allergiesDropdownValue = newValue;
                  _allergiesError = false;
                });
              },
              hasError: _allergiesError,
              errorMessage: "Please select an option",
            ),
            const SizedBox(height: 10),

            if (_allergiesDropdownValue == 'Yes')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Please list your allergies (separate with ',' if more than one):",
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _allergiesController,
                    decoration: InputDecoration(
                      hintText: "e.g., Peanuts, Shellfish",
                      errorText: _allergiesInputError ? "Please enter your allergies" : null,
                    ),
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      setState(() {
                        _allergiesInputError = false;
                      });
                    },
                  ),
                ],
              ),
            const SizedBox(height: 25),

            const Spacer(),

            // Save Button at the Bottom
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateMedicalHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}