// lib/screens/signup_detail.dart
import 'package:flutter/material.dart';
import 'signup_success.dart'; // Import the next page
import '../services/profile_service.dart'; // Import the ProfileService
import '../utils/input_validator.dart'; // Import the InputValidator

class SignUpDetail extends StatefulWidget {
  final String name;
  final String location;
  final String gender;
  final DateTime birthDate;
  final double weight;
  final double height;
  final String preExisting;
  final String allergies;
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
    required this.preExisting,
    required this.allergies,
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
  final ProfileService _profileService = ProfileService(); // Instance of ProfileService

  bool _emailError = false; // Track if email field has an error
  bool _passwordError = false; // Track if password field has an error
  bool _emailExistsError = false; // Track if email exists error

  // Password validation rules
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  // Function to validate password
  void _validatePassword(String password) {
    final validationResult = ProfileService.validatePassword(password);
    setState(() {
      _hasMinLength = validationResult['hasMinLength']!;
      _hasUppercase = validationResult['hasUppercase']!;
      _hasNumber = validationResult['hasNumber']!;
      _hasSymbol = validationResult['hasSymbol']!;
    });
  }

  // Function to create account
  Future<void> _createAccount() async {
    setState(() {
      _emailError = false;
      _passwordError = false;
      _emailExistsError = false;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate email
    if (email.isEmpty || !ProfileService.isValidEmail(email)) {
      setState(() {
        _emailError = true;
      });
      return;
    }

    // Validate password
    if (password.isEmpty || !(_hasMinLength && _hasUppercase && _hasNumber && _hasSymbol)) {
      setState(() {
        _passwordError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if email exists
      final emailExists = await _profileService.isEmailAvailable(email);
      if (emailExists) {
        setState(() {
          _emailExistsError = true;
        });
        return;
      }

      // Create account
      await _profileService.createAccount(
        email: email,
        password: password,
        name: widget.name,
        location: widget.location,
        gender: widget.gender,
        birthDate: widget.birthDate,
        weight: widget.weight,
        height: widget.height,
        preExisting: widget.preExisting,
        allergies: widget.allergies,
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
      // Delete account if creation fails
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
              decoration: InputValidator.buildInputDecoration(
                hintText: "Enter your email address",
                hasError: _emailError || _emailExistsError,
              ),
              onChanged: (value) {
                setState(() {
                  _emailError = false;
                  _emailExistsError = false;
                });
              },
            ),
            if (_emailError) // Show error message if email is invalid
              InputValidator.buildErrorMessage("Please enter a valid email address"),
            if (_emailExistsError) // Show error message if email already exists
              InputValidator.buildErrorMessage("This email is already registered"),
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
              decoration: InputValidator.buildInputDecoration(
                hintText: "Create a strong password",
                hasError: _passwordError,
              ),
              obscureText: true,
              onChanged: (value) {
                _validatePassword(value);
                setState(() {
                  _passwordError = false;
                });
              },
            ),
            if (_passwordError) // Show error message if password is invalid
              InputValidator.buildErrorMessage("Please enter a valid password"),
            const SizedBox(height: 10),

            // Password guidelines
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your password must:",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                _buildPasswordGuideline("Be at least 8 characters", _hasMinLength),
                _buildPasswordGuideline("Include at least one uppercase letter", _hasUppercase),
                _buildPasswordGuideline("Include at least one number", _hasNumber),
                _buildPasswordGuideline("Include at least one symbol", _hasSymbol),
              ],
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

  // Helper function to build password guidelines
  Widget _buildPasswordGuideline(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          Icons.circle,
          size: 8,
          color: isValid ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isValid ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}