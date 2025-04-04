import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../backend/state/signup_state.dart';

class SignupMed extends StatefulWidget {
  const SignupMed({super.key});

  @override
  SignupMedState createState() => SignupMedState();
}

class SignupMedState extends State<SignupMed> {
  final List<TextEditingController> _preExistingControllers = [];
  final List<TextEditingController> _allergiesControllers = [];

  @override
  void dispose() {
    for (var controller in _preExistingControllers) {
      controller.dispose();
    }
    for (var controller in _allergiesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPreExistingField() {
    setState(() {
      _preExistingControllers.add(TextEditingController());
    });
  }

  void _removePreExistingField(int index) {
    setState(() {
      _preExistingControllers.removeAt(index);
    });
  }

  void _addAllergyField() {
    setState(() {
      _allergiesControllers.add(TextEditingController());
    });
  }

  void _removeAllergyField(int index) {
    setState(() {
      _allergiesControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final signupState = context.watch<SignupState>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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

            // Progress indicator (step 3 of 7)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                7,
                (index) => Container(
                  width: 40,
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Pre-existing Conditions Section
            Text(
              "Do you have any pre-existing medical conditions?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "If yes, add medical conditions",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            // Dynamically added pre-existing conditions fields
            Column(
              children: [
                // Only show the text field when at least one is added
                if (_preExistingControllers.isNotEmpty)
                  ..._preExistingControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: "Enter medical condition",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                            IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removePreExistingField(index),
                            ),
                        ],
                      ),
                    );
                  }),
                TextButton(
                  onPressed: _addPreExistingField,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.green),
                      Text(
                        "Add Medical Condition",
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Allergies Section
            Text(
              "Do you have any known allergies?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "If yes, add allergies",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            // Dynamically added allergies fields
            Column(
              children: [
                // Only show the text field when at least one is added
                if (_allergiesControllers.isNotEmpty)
                  ..._allergiesControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: "Enter allergy",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                            IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removeAllergyField(index),
                            ),
                        ],
                      ),
                    );
                  }),
                TextButton(
                  onPressed: _addAllergyField,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.green),
                      Text(
                        "Add Allergy",
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                    // Get all non-empty values
                    final preExisting = _preExistingControllers
                        .map((c) => c.text.trim())
                        .where((text) => text.isNotEmpty)
                        .toList();
                    
                    final allergies = _allergiesControllers
                        .map((c) => c.text.trim())
                        .where((text) => text.isNotEmpty)
                        .toList();

                    // Update state
                    signupState.setPreExisting(preExisting.isNotEmpty ? preExisting.join(',') : 'NA');
                    signupState.setAllergies(allergies.isNotEmpty ? allergies.join(',') : 'NA');

                    // Proceed to next screen
                    Navigator.pushNamed(context, '/signup_goal');
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
