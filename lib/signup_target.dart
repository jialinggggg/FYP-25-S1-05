import 'package:flutter/material.dart';
import 'signup_details.dart';

class SignupTarget extends StatelessWidget {
  const SignupTarget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header "Target" text
            Center(
              child: Text(
                "Target",
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
                    color: index == 4 ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Left-aligned text sections
            Text(
              "Let's Set Your Targets!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

             Text(
              "Set your desired weight and daily calorie intake to personalize your wellness plan.",
              style: TextStyle(fontSize: 16, color: const Color.fromARGB(255, 99, 97, 97)),
            ),
            const SizedBox(height: 30),

            // Desired Weight Row
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Desired Weight",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 80),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    // Decrease weight logic
                  },
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: () {
                    // Increase weight logic
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Daily Calories Intake Row
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Daily Calories Intake",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 40),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    // Decrease calories logic
                  },
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: () {
                    // Increase calories logic
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
                    // Navigate to the SignupYou2 screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupDetails()),
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
