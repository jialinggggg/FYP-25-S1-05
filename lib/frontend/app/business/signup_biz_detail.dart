import 'package:flutter/material.dart';
import '../../../backend/utils/input_validator.dart';
import '../shared/signup_result.dart'; // Import the next page
import '../../../../services/profile_service.dart'; // Import the ProfileService
import '../../../backend/supabase/business_profile.dart'; // Import the BusinessProfilesService
import '../../../backend/supabase/auth_user_service.dart'; // Import the AuthUsersService
import '../../../backend/supabase/accounts_service.dart'; // Import the AccountService
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import '../../../backend/utils/build_error_msg.dart';

class SignupBizDetail extends StatefulWidget {
  final String name;
  final String registration;
  final String country;
  final String address;
  final String type;
  final String description;

  // Constructor to initialize business details
  const SignupBizDetail({
    super.key,
    required this.name,
    required this.registration,
    required this.country,
    required this.address,
    required this.type,
    required this.description,
  });

  @override
  SignupBizDetailState createState() => SignupBizDetailState();
}

class SignupBizDetailState extends State<SignupBizDetail> {
  // Controllers for email and password input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; // Track loading state
  final ProfileService _profileService = ProfileService(); // Instance of ProfileService
  final SupabaseClient _supabase = Supabase.instance.client; // Initialize Supabase client

  // Validation error states
  bool _emailError = false;
  bool _passwordError = false;
  bool _emailExistsError = false;

  // Password validation rules
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  // Function to validate password
  void _validatePassword(String password) {
    final validationResult = InputValidator.validatePassword(password); // Access static method
    setState(() {
      _hasMinLength = validationResult['hasMinLength'] ?? false;
      _hasUppercase = validationResult['hasUppercase'] ?? false;
      _hasNumber = validationResult['hasNumber'] ?? false;
      _hasSymbol = validationResult['hasSymbol'] ?? false;
    });
  }

  // Function to create business account
  Future<void> _createBusinessAccount() async {
    setState(() {
      _emailError = false;
      _passwordError = false;
      _emailExistsError = false;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate email
    if (email.isEmpty || !InputValidator.isValidEmail(email)) { // Access static method
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
      if (!emailExists) {
        setState(() {
          _emailExistsError = true;
        });
        return;
      }

      final authService = AuthUsersService(_supabase);
      final accountService = AccountService(_supabase);
      final businessProfileService = BusinessProfilesService(_supabase);

      // Step 1: Sign up the user using AuthUsersService
      final uid = await authService.signUp(email: email, password: password);

      // Step 2: Insert into accounts table using AccountService
      await accountService.insertAccount(
        uid: uid,
        email: email,
        type: "business", // Default type
        status: "pending", // Default status
      );

      // Step 3: Insert into business_profiles table
      await businessProfileService.insertBizProfile(
        uid: uid,
        name: widget.name,
        registration: widget.registration,
        country: widget.country,
        address: widget.address,
        type: widget.type,
        description: widget.description,
      );

      // Navigate to the success page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignupResult(type: "business")),
        );
      }
    } catch (e) {
      // Show error message
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
            // Header "Create Business Account" text
            Center(
              child: Text(
                "Create Business Account",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                2,
                (index) => Container(
                  width: 179,
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
              "Create Your Business Account!",
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
                      hintText: "Enter your email",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
              onChanged: (value) {
                setState(() {
                  _emailError = false;
                  _emailExistsError = false;
                });
              },
            ),
            if (_emailError) // Show error message if email is invalid
              BuildErrorMsg.buildErrorMessage("Please enter a valid email address"),
            if (_emailExistsError) // Show error message if email already exists
              BuildErrorMsg.buildErrorMessage("This email is already registered"),
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
                      hintText: "Create a strong password",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
              BuildErrorMsg.buildErrorMessage("Please enter a valid password"),
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
                        onPressed: _createBusinessAccount,
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