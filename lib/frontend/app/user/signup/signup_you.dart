import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../backend/state/signup_state.dart';
import '../../../../backend/services/input_validation_service.dart';
import '../../../../backend/utils/input_validator.dart';
import '../../../../utils/date_picker.dart';

class SignupYou extends StatefulWidget {
  const SignupYou({super.key});

  @override
  SignupYouState createState() => SignupYouState();
}

class SignupYouState extends State<SignupYou> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final InputValidationService _validationService = InputValidationService();
  String? _genderError;
  String? _birthDateError;
  String? _weightError;
  String? _heightError;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _handleBirthDateSelection(BuildContext context) async {
    final date = await DatePicker.selectDate(context);
    if (date != null) {
      final now = DateTime.now();
      final age = now.year - date.year - ((now.month > date.month || (now.month == date.month && now.day >= date.day)) ? 0 : 1);
      
      if (age < 18) {
        _showAgeWarningDialog(context);
      } else {
        final signupState = context.read<SignupState>();
        signupState.setBirthDate(date);
        setState(() => _birthDateError = null);
      }
    }
  }

  void _showAgeWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Age Restriction"),
        content: Text("You must be at least 18 years old to use this app."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
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
                "You",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator (step 2 of 7)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                7,
                (index) => Container(
                  width: 40,
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
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Male Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: signupState.gender == "Male" ? Colors.blue : Color.fromARGB(255, 162, 191, 223),
                    padding: EdgeInsets.symmetric(horizontal: 65, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    signupState.setGender('Male');
                    setState(() => _genderError = null);
                  },
                  child: Text(
                    "Male",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                // Female Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: signupState.gender == "Female" ? Colors.pink : Color.fromARGB(255, 253, 199, 199),
                    padding: EdgeInsets.symmetric(horizontal: 65, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    signupState.setGender('Female');
                    setState(() => _genderError = null);
                  },
                  child: Text(
                    "Female",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            if (_genderError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _genderError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),

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
                    controller: TextEditingController(
                      text: signupState.birthDate == null 
                          ? '' 
                          : "${signupState.birthDate!.toLocal()}".split(' ')[0],
                    ),
                    decoration: InputDecoration(
                      hintText: "Select your birthdate",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    readOnly: true,
                    onTap: () => _handleBirthDateSelection(context),
                  ),
                ),
                // Calendar Icon Button
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _handleBirthDateSelection(context),
                ),
              ],
            ),
            if (_birthDateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _birthDateError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),

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
              onChanged: (value) {
                final height = double.tryParse(value) ?? 0;
                signupState.setHeight(height);
                if (value.isNotEmpty) setState(() => _heightError = null);
              },
            ),
            if (_heightError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _heightError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),

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
              onChanged: (value) {
                final weight = double.tryParse(value) ?? 0;
                signupState.setWeight(weight);
                if (value.isNotEmpty) setState(() => _weightError = null);
              },
            ),
            if (_weightError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _weightError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),

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
                    final error = _validationService.validatePersonalDetails(
                      gender: signupState.gender,
                      birthDate: signupState.birthDate,
                      weight: _weightController.text,
                      height: _heightController.text,
                    );

                    if (error != null) {
                      setState(() {
                        _genderError = signupState.gender.isEmpty ? 'Please select your gender' : null;
                        _birthDateError = signupState.birthDate == null ? 'Please enter your birthdate' : null;
                        _weightError = !InputValidator.validateNumericField(_weightController.text, 20, 500) 
                            ? 'Please enter a valid weight (20-500 kg)' : null;
                        _heightError = !InputValidator.validateNumericField(_heightController.text, 50, 300)
                            ? 'Please enter a valid height (50-300 cm)' : null;
                      });
                    } else {
                      Navigator.pushNamed(context, '/signup_med');
                    }
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