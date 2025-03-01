import 'package:flutter/material.dart';
import 'signup_med.dart';

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

class SignupYouState extends State<SignupYou>{
  String? _selectedGender; // To store the selected gender
  final _ageController = TextEditingController(); // Controller for the age field
  final _weightController = TextEditingController(); // Controller for the age field
  final _heightController = TextEditingController(); // Controller for the age field

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
                    setState((){
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

            // age label
            Text(
              "How young are you?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Text field
            TextField(
              controller: _ageController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your age",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 25),

            // height label
            Text(
              "How tall are you?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Text field
            TextField(
              controller: _heightController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your height (cm)",
              ),
              keyboardType: TextInputType.number,
            ),
             const SizedBox(height: 25),

            // height label
            Text(
              "What's your current weight?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Text field
            TextField(
              controller: _weightController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your weight",
              ),
              keyboardType: TextInputType.number,
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
                    if (_selectedGender == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select your gender')),
                      );
                      return;
                    }
                    if (_ageController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter your age')),
                      );
                      return;
                    }
                    if (_heightController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter your height')),
                      );
                      return;
                    }
                    if (_weightController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter your weight')),
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
                          age: int.parse(_ageController.text),
                          height: double.parse(_heightController.text),
                          weight: double.parse(_weightController.text),
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
