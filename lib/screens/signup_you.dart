// lib/screens/signup_you.dart
import 'package:flutter/material.dart';
import '../utils/input_validator.dart'; // Import the InputValidator
import '../utils/date_picker.dart'; // Import the DatePicker
import 'signup_med.dart'; // Import the next page

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
  String? _selectedGender; // To store the selected gender
  final _dateController = TextEditingController(); // Controller for the age field
  final _weightController = TextEditingController(); // Controller for the weight field
  final _heightController = TextEditingController(); // Controller for the height field
  String _heightUnit = 'cm'; // Default height unit
  String _weightUnit = 'kg'; // Default weight unit
  DateTime? _selectedDate; // To store the selected birth date

  Future<void> _selectDate(BuildContext context) async {
  final DateTime? picked = await DatePicker.selectDate(context);
  if (picked != null && picked != _selectedDate) {
    setState(() {
      _selectedDate = picked; // Update the state with the selected date
      _dateController.text = "${picked.toLocal()}".split(' ')[0]; // Format the date
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header "You" text
            Center(
              child: Text(
                "You",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                6,
                (index) => Container(
                  width: 55,
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

            // Left-aligned text sections
            Text(
              "Tell Us About You!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            Text(
              "How do you identify?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Gender button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Male Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedGender == "Male"
                        ? Colors.blue // Highlight if selected
                        : const Color.fromARGB(255, 162, 191, 223),
                    padding: EdgeInsets.symmetric(horizontal: 65, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedGender = 'Male';
                    });
                  },
                  child: Text(
                    "Male",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                // Female button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedGender == "Female"
                        ? Colors.pink // Highlight if selected
                        : const Color.fromARGB(255, 253, 199, 199),
                    padding: EdgeInsets.symmetric(horizontal: 65, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedGender = 'Female';
                    });
                  },
                  child: Text(
                    "Female",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // birthdate label
            Text(
              "How young are you?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // birthdate text field with date picker
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter your Birthdate",
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: true, // Make the field read-only
                    onTap: () => _selectDate(context), // Show date picker on tap
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context), // Show date picker on button press
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Height label
            Text(
              "How tall are you?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Height text field with unit dropdown
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter your height",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _heightUnit,
                  items: ['cm', 'feet'].map((String unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _heightUnit = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Weight label
            Text(
              "What's your current weight?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Weight text field with unit dropdown
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter your weight",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _weightUnit,
                  items: ['kg', 'lbs'].map((String unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _weightUnit = newValue!;
                    });
                  },
                ),
              ],
            ),

            const Spacer(),

            // Back and Next buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 30),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                // Next button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 135, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  onPressed: () {
                    // Validate inputs
                    if (InputValidator.isFieldEmpty(_selectedGender, context, 'select', 'gender')) {
                      return;
                    }
                    if (InputValidator.isFieldEmpty(_selectedDate.toString(), context, 'enter', 'height')) {
                      return;
                    }
                    if (!InputValidator.isAbove18(_selectedDate!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('You must be above 18 to sign up')),
                      );
                      return;
                    }
                    if (InputValidator.isFieldEmpty(_heightController.text, context, 'enter', 'height')) {
                      return;
                    }
                    if (InputValidator.isFieldEmpty(_weightController.text, context, 'enter', 'weight')) {
                      return;
                    }

                    // Parse height and weight
                    final height = double.tryParse(_heightController.text) ?? 0;
                    final weight = double.tryParse(_weightController.text) ?? 0;

                    // Validate height and weight
                    if (!InputValidator.isValidHeight(height, _heightUnit)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a valid height')),
                      );
                      return;
                    }
                    if (!InputValidator.isValidWeight(weight, _weightUnit)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a valid weight')),
                      );
                      return;
                    }

                    // Navigate to the SignupMed screen with the collected data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignupMed(
                          name: widget.name,
                          location: widget.location,
                          gender: _selectedGender!,
                          birthDate: _selectedDate!,
                          height: height,
                          weight: weight,
                          weightUnit: _weightUnit,
                          heightUnit: _heightUnit,
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