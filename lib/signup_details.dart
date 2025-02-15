import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_success.dart'; // Import the next page

class SignupDetails extends StatefulWidget {
  final String name;
  final String location;
  final String gender;
  final int age;
  final double weight;
  final double height;
  final String preExisting;
  final String allergies;
  final String goal;
  final double desiredWeight;
  final int dailyCalories;
  final double protein;
  final double carbs;
  final double fats;

  const SignupDetails({
    super.key,
    required this.name,
    required this.location,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
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
  SignupDetailsState createState() => SignupDetailsState();
}

class SignupDetailsState extends State<SignupDetails> {
  final _emailController = TextEditingController(); // Controller for email
  final _passwordController = TextEditingController(); // Controller for password
  bool _isLoading = false; // Track loading state

  // Function to check if email exists in Supabase Auth
  Future<bool> _isEmailAvailable(String email) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('email', email);

      return response.isEmpty; // If empty, email is available
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking email availability: $e')),
        );
      }
      return false;
    }
  }

  // Function to validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Function to create a user account and insert data into the database
  Future<void> _createAccount() async {
    setState(() {
    _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate email format
    if (!_isValidEmail(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid email address.')),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Check if email is available
    final isAvailable = await _isEmailAvailable(email);
    if (!isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email is already in use. Please try to login.')),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Create user account with Supabase Auth
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('User not created');
      }

      // Insert profile data
      await Supabase.instance.client.from('profiles').insert({
        'user_id': user.id,
        'name': widget.name,
        'location': widget.location,
        'gender': widget.gender,
        'age': widget.age,
        'weight': widget.weight,
        'height': widget.height,
      });

      // Insert medical history data
      await Supabase.instance.client.from('medical_history').insert({
        'user_id': user.id,
        'pre_existing': widget.preExisting,
        'allergies': widget.allergies,
      });

      // Insert user goals data
      await Supabase.instance.client.from('user_goals').insert({
        'user_id': user.id,
        'goal': widget.goal,
        'desired_weight': widget.desiredWeight,
        'daily_calories': widget.dailyCalories,
        'protein': widget.protein,
        'carbs': widget.carbs,
        'fats': widget.fats,
      });

      // Navigate to the login success page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignupSuccess()),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to create account: $error')),
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