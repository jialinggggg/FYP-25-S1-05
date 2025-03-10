import 'package:flutter/material.dart';
import '../utils/input_validator.dart';
import '../utils/widget_utils.dart';
import 'signup_target.dart';

class SignupMed extends StatefulWidget {
  final String name;
  final String location;
  final String gender;
  final DateTime birthDate;
  final double weight;
  final double height;

  const SignupMed({
    super.key,
    required this.name,
    required this.location,
    required this.gender,
    required this.birthDate,
    required this.weight,
    required this.height,
  });

  @override
  SignupMedState createState() => SignupMedState();
}

class SignupMedState extends State<SignupMed> {
  final TextEditingController _preExistingController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();

  String? _preExistingDropdownValue;
  String? _allergiesDropdownValue;

  bool _preExistingError = false;
  bool _allergiesError = false;
  bool _preExistingInputError = false;
  bool _allergiesInputError = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Medical History",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Container(
                  width: 68,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == 2 ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            Text(
              "Help Us Understand Your Health Needs!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Pre-existing Conditions
            WidgetUtils.buildDropdown(
              label: "Do you have any pre-existing medical conditions?",
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
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _preExistingController,
                    decoration: InputValidator.buildInputDecoration(
                      hintText: "e.g., Diabetes, Hypertension",
                      hasError: _preExistingInputError,
                    ),
                    keyboardType: TextInputType.text,
                    onChanged: (value) => setState(() => _preExistingInputError = false),
                  ),
                  if (_preExistingInputError)
                    InputValidator.buildErrorMessage("Please enter your pre-existing conditions"),
                ],
              ),
            const SizedBox(height: 25),

            // Allergies
            WidgetUtils.buildDropdown(
              label: "Do you have any known allergies?",
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
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _allergiesController,
                    decoration: InputValidator.buildInputDecoration(
                      hintText: "e.g., Peanuts, Shellfish",
                      hasError: _allergiesInputError,
                    ),
                    keyboardType: TextInputType.text,
                    onChanged: (value) => setState(() => _allergiesInputError = false),
                  ),
                  if (_allergiesInputError)
                    InputValidator.buildErrorMessage("Please enter your allergies"),
                ],
              ),
            const SizedBox(height: 25),

            const Spacer(),

            // Next Button
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
                    if (!_validateInputs()) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignupTarget(
                          name: widget.name,
                          location: widget.location,
                          gender: widget.gender,
                          birthDate: widget.birthDate,
                          weight: widget.weight,
                          height: widget.height,
                          preExisting: _preExistingDropdownValue == 'Yes' ? _preExistingController.text : 'NA',
                          allergies: _allergiesDropdownValue == 'Yes' ? _allergiesController.text : 'NA',
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