import 'package:flutter/material.dart';
import 'signup_goal.dart';

class SignupMed extends StatefulWidget {
  final String name;
  final String location;
  final String gender;
  final int age;
  final double weight;
  final double height;

  const SignupMed({
    super.key, 
    required this.name, 
    required this.location,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    });

  @override
  SignupMedState createState() => SignupMedState();
}

class SignupMedState extends State<SignupMed> {
  final _preExistingController = TextEditingController(); // Controller for the pre-existing conditions field
  final _allergiesController = TextEditingController(); // Controller for the allergies field

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header "Medical" text
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
                6,
                (index) => Container(
                  width: 55,
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

            // Left-aligned text sections
            Text(
              "Help Us Understand Your Health Needs!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // medical conditions label
            Text(
              "Do you have any pre-existing medical conditions?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Text field
            TextField(
              controller: _preExistingController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "If yes, Please list them:",
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 25),

            // allergies label
            Text(
              "Do you have any known allergies?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Text field
            TextField(
              controller: _allergiesController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "If yes, Please list them:",
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 25),

            
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
                    /// Navigate to the SignupYou2 screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignupGoal(
                          name: widget.name,
                          location: widget.location,
                          gender: widget.gender,
                          age: widget.age,
                          weight: widget.weight,
                          height: widget.height,
                          preExisting: _preExistingController.text,
                          allergies: _allergiesController.text,
                        )
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
