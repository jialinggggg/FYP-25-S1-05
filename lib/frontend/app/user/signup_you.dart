import 'package:flutter/material.dart';
import '../../../backend/utils/input_validator.dart';
import '../../../../utils/date_picker.dart';
import '../../../../utils/dialog_utils.dart';
import 'signup_med.dart';
import '../../../backend/utils/build_error_msg.dart';

// Stateful widget for user signup page
class SignupYou extends StatefulWidget {
  final String name;
  final String location;

  const SignupYou({
    super.key,
    required this.name,
    required this.location,
  });

  @override
  SignupYouState createState() => SignupYouState();
}

class SignupYouState extends State<SignupYou> {
  // User input controllers
  String? _selectedGender;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  DateTime? _selectedDate;

  // Validation error states
  bool _genderError = false;
  bool _dateError = false;
  bool _heightError = false;
  bool _weightError = false;

  // Opens the date picker dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await DatePicker.selectDate(context);
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.toLocal()}".split(' ')[0];
        _dateError = false;
      });
    }
  }

  // Validates all input fields
  bool _validateInputs() {
    bool isValid = true;

    // Validate gender selection
    isValid &= InputValidator.validateField(
      _selectedGender,
      (error) => setState(() => _genderError = error),
      "Please select your gender",
    );

    // Validate birthdate input
    isValid &= InputValidator.validateField(
      _selectedDate?.toString(),
      (error) => setState(() => _dateError = error),
      "Please enter your birthdate",
    );

    // Validate height input
    isValid &= InputValidator.validateNumericField(
      _heightController.text,
      (error) => setState(() => _heightError = error),
      50,
      300,
      "Height must be between 50 cm and 300 cm",
    );

    // Validate weight input
    isValid &= InputValidator.validateNumericField(
      _weightController.text,
      (error) => setState(() => _weightError = error),
      20,
      500,
      "Weight must be between 20 kg and 500 kg",
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
                "You",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator (step 2 of 5)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Container(
                  width: 68,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == 1 ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Section title
            Text(
              "Tell Us About You!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Gender Selection Buttons
            Text(
              "How do you identify?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Male Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedGender == "Male" ? Colors.blue : const Color.fromARGB(255, 162, 191, 223),
                    padding: EdgeInsets.symmetric(horizontal: 65, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedGender = 'Male';
                      _genderError = false;
                    });
                  },
                  child: Text(
                    "Male",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                // Female Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedGender == "Female" ? Colors.pink : const Color.fromARGB(255, 253, 199, 199),
                    padding: EdgeInsets.symmetric(horizontal: 65, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedGender = 'Female';
                      _genderError = false;
                    });
                  },
                  child: Text(
                    "Female",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            if (_genderError)
              BuildErrorMsg.buildErrorMessage("Please select your gender"),
            const SizedBox(height: 25),

            // Birthdate input field with calendar icon
            Text(
              "How young are you?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Birthdate Input Field
                Expanded(
                  child: TextField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      hintText: "Select your birthdate",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                ),
                // Calendar Icon Button
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            if (_dateError)
              BuildErrorMsg.buildErrorMessage("Please enter your birthdate"),
            const SizedBox(height: 25),

            // Height Field
            Text(
              "How tall are you? (in cm)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _heightController,
              decoration: InputDecoration(
                      hintText: "Enter your height",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => setState(() => _heightError = false),
            ),
            if (_heightError)
              BuildErrorMsg.buildErrorMessage("Please enter a valid height (50-300 cm)"),
            const SizedBox(height: 25),

            // Weight Field
            Text(
              "What's your current weight? (in kg)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _weightController,
              decoration: InputDecoration(
                      hintText: "Enter your weight",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => setState(() => _weightError = false),
            ),
            if (_weightError)
              BuildErrorMsg.buildErrorMessage("Please enter a valid weight (20-500 kg)"),
            const SizedBox(height: 25),

            const Spacer(),

            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                // Next Button
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
                    if (!InputValidator.isAbove18(_selectedDate!)) {
                      DialogUtils.showErrorDialog(
                        context: context,
                        message: 'You must be above 18 to sign up',
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignupMed(
                          name: widget.name,
                          location: widget.location,
                          gender: _selectedGender!,
                          birthDate: _selectedDate!,
                          weight: double.parse(_weightController.text),
                          height: double.parse(_heightController.text),
                        ),
                      ),
                    );
                  },
                  child: Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
