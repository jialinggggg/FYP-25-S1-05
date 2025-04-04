import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../backend/state/signup_state.dart';

class SignupGoal extends StatefulWidget {
  const SignupGoal({super.key});

  @override
  SignupGoalState createState() => SignupGoalState();
}

class SignupGoalState extends State<SignupGoal> {
  String? _goalError;

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
                "Goals",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator (step 4 of 7)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                7,
                (index) => Container(
                  width: 40,
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

            Text(
              "Define Your Goals!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            Text(
              "What's your primary health objective?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_goalError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _goalError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 15),

            // Goal Buttons
            Column(
              children: [
                _buildGoalButton(
                  context: context,
                  title: "Lose Weight",
                  isSelected: signupState.goal == "Lose Weight",
                  onPressed: () {
                    signupState.setGoal("Lose Weight");
                    setState(() => _goalError = null);
                  },
                ),
                const SizedBox(height: 10),
                _buildGoalButton(
                  context: context,
                  title: "Gain Weight",
                  isSelected: signupState.goal == "Gain Weight",
                  onPressed: () {
                    signupState.setGoal("Gain Weight");
                    setState(() => _goalError = null);
                  },
                ),
                const SizedBox(height: 10),
                _buildGoalButton(
                  context: context,
                  title: "Maintain Weight",
                  isSelected: signupState.goal == "Maintain Weight",
                  onPressed: () {
                    signupState.setGoal("Maintain Weight");
                    setState(() => _goalError = null);
                  },
                ),
                const SizedBox(height: 10),
                _buildGoalButton(
                  context: context,
                  title: "Gain Muscle",
                  isSelected: signupState.goal == "Gain Muscle",
                  onPressed: () {
                    signupState.setGoal("Gain Muscle");
                    setState(() => _goalError = null);
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
                    if (signupState.goal.isEmpty) {
                      setState(() => _goalError = 'Please select your goal');
                    } else {
                      Navigator.pushNamed(context, '/signup_activity');
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

  Widget _buildGoalButton({
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
        ),
      ),
    );
  }
}