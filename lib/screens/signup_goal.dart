import 'package:flutter/material.dart';
import 'signup_target.dart';
import '../utils/input_validator.dart';

class SignupGoal extends StatefulWidget {

  final String name;
  final String location;
  final String gender;
  final DateTime birthDate;
  final double weight;
  final double height;
  final String weightUnit;
  final String heightUnit;
  final String preExisting;
  final String allergies;

  const SignupGoal({
    super.key, 
    required this.name, 
    required this.location,
    required this.gender,
    required this.birthDate,
    required this.weight,
    required this.height,
    required this.weightUnit,
    required this.heightUnit,
    required this.preExisting,
    required this.allergies,
    });

  @override
  SignupGoalState createState() => SignupGoalState();
}

class SignupGoalState extends State<SignupGoal> {
  String? _selectedGoal; // To store the selected goal

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header "Goal" text
            Center(
              child: Text(
                "Goal",
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
                    color: index == 3 ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Left-aligned text sections
            Text(
              "Define your goals!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Medical conditions label
            Text(
              "What's your primary health objective?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 4 buttons under health objective
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedGoal == "Lose Weight"
                      ? const Color.fromARGB(255, 104, 103, 103) // Highlight the selected button
                      : const Color.fromARGB(255, 183, 186, 191),
                    padding: EdgeInsets.symmetric(horizontal: 140, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // Handle "Lose Weight" selection
                    setState(() {
                      _selectedGoal = "Lose Weight";
                    }); 
                  },
                  child: Text(
                    "Lose Weight",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedGoal == "Gain Weight"
                      ? const Color.fromARGB(255, 104, 103, 103) // Highlight the selected button
                      : const Color.fromARGB(255, 183, 186, 191),
                    padding: EdgeInsets.symmetric(horizontal: 140, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // Handle "Gain Weight" selection
                    setState(() {
                      _selectedGoal = "Gain Weight";
                    });
                  },
                  child: Text(
                    "Gain Weight",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedGoal == "Maintain Weight"
                      ? const Color.fromARGB(255, 104, 103, 103) // Highlight the selected button
                      :const Color.fromARGB(255, 183, 186, 191),
                    padding: EdgeInsets.symmetric(horizontal: 125, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // Handle "Maintain Weight" selection
                    setState(() {
                      _selectedGoal = "Maintain Weight";
                    });
                  },
                  child: Text(
                    "Maintain Weight",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedGoal == "Gain Muscle"
                      ? const Color.fromARGB(255, 104, 103, 103) // Highlight the selected button
                      : const Color.fromARGB(255, 183, 186, 191),
                    padding: EdgeInsets.symmetric(horizontal: 140, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // Handle "Gain Muscle" selection
                    setState(() {
                      _selectedGoal = "Gain Muscle";
                    });
                  },
                  child: Text(
                    "Gain Muscle",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
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
                    // Check if a goal is selected
                    if (InputValidator.isFieldEmpty(_selectedGoal, context, 'select', 'goal')) {
                      return;
                    }

                    // Navigate to the SignupYou2 screen
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
                          weightUnit: widget.weightUnit,
                          heightUnit: widget.heightUnit,
                          preExisting: widget.preExisting,
                          allergies: widget.allergies,
                          goal: _selectedGoal!,
                        )),
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
