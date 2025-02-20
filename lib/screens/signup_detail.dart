import 'package:flutter/material.dart';
import 'signup_success.dart'; // Import the next page
import '../services/auth_service.dart'; // Import the AuthService

class SignUpDetail extends StatefulWidget {
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
  final String goal;
  final double desiredWeight;
  final int dailyCalories;
  final double protein;
  final double carbs;
  final double fats;

  const SignUpDetail({
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
    required this.goal,
    required this.desiredWeight,
    required this.dailyCalories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  @override
  SignUpDetailState createState() => SignUpDetailState();
}

class SignUpDetailState extends State<SignUpDetail> {
  final _emailController = TextEditingController(); // Controller for email
  final _passwordController = TextEditingController(); // Controller for password
  bool _isLoading = false; // Track loading state
  final AuthService _authService = AuthService(); // Instance of AuthService

  Future<void> _createAccount() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await _authService.createAccount(
        email: email,
        password: password,
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
        goal: widget.goal,
        desiredWeight: widget.desiredWeight,
        dailyCalories: widget.dailyCalories,
        protein: widget.protein,
        carbs: widget.carbs,
        fats: widget.fats,
      );

      // Navigate to the success page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignupSuccess()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            // Header "Create Account" text
            Center(
              child: Text(
                "Create Account",
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
                    color: index == 5 ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Left-aligned text sections
            Text(
              "Create Your Account!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Email label
            Text(
              "Email Address",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Email text field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your email address",
              ),
            ),
            const SizedBox(height: 25),

            // Password label
            Text(
              "Password",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Password text field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Create a strong password",
              ),
              obscureText: true,
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
                // Sign Up button
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        onPressed: _createAccount,
                        child: Text(
                          "Sign Up",
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