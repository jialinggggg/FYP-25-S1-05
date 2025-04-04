import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../backend/state/signup_state.dart';

class SignupActivity extends StatefulWidget {
  const SignupActivity({super.key});

  @override
  SignupActivityState createState() => SignupActivityState();
}

class SignupActivityState extends State<SignupActivity> {
  String? _activityError;

  @override
  Widget build(BuildContext context) {
    final signupState = context.watch<SignupState>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Activity Level",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator (step 5 of 7)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                7,
                (index) => Container(
                  width: 40,
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

            Text(
              "Define Your Activity Level!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            Text(
              "What's your activity level?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_activityError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _activityError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 15),

            // Activity Buttons
            Column(
              children: [
                _buildActivityButton(
                  context: context,
                  title: "Sedentary (Little to no exercise)",
                  isSelected: signupState.activity == "Sedentary",
                  onPressed: () {
                    signupState.setActivity("Sedentary");
                    setState(() => _activityError = null);
                  },
                ),
                const SizedBox(height: 10),
                _buildActivityButton(
                  context: context,
                  title: "Lightly Active (Light exercise 1-3 days/week)",
                  isSelected: signupState.activity == "Lightly Active",
                  onPressed: () {
                    signupState.setActivity("Lightly Active");
                    setState(() => _activityError = null);
                  },
                ),
                const SizedBox(height: 10),
                _buildActivityButton(
                  context: context,
                  title: "Moderately Active (Moderate exercise 3-5 days/week)",
                  isSelected: signupState.activity == "Moderately Active",
                  onPressed: () {
                    signupState.setActivity("Moderately Active");
                    setState(() => _activityError = null);
                  },
                ),
                const SizedBox(height: 10),
                _buildActivityButton(
                  context: context,
                  title: "Very Active (Hard exercise 6-7 days/week)",
                  isSelected: signupState.activity == "Very Active",
                  onPressed: () {
                    signupState.setActivity("Very Active");
                    setState(() => _activityError = null);
                  },
                ),
              ],
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
                    if (signupState.activity.isEmpty) {
                      setState(() => _activityError = 'Please select your activity level');
                    } else {
                      Navigator.pushNamed(context, '/signup_target');
                    }
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

  Widget _buildActivityButton({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}