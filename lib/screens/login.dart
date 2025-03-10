import 'package:flutter/material.dart';
import 'main_log_screen.dart';
import 'signup_type.dart'; // Import SignupWelcome screen
import '../services/auth_service.dart'; // Import AuthService
import '../utils/dialog_utils.dart'; // Import DialogUtils
import '../utils/input_validator.dart'; // Import InputValidator
import 'biz_partner_dashboard.dart'; // Import BizPartnerDashboard screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for email and password input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService(); // Authentication service instance
  bool _isLoading = false; // Track loading state

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate email input
    if (!InputValidator.validateField(
      email,
      (error) {
        if (error) {
          DialogUtils.showErrorDialog(
            context: context,
            message: 'Please enter your email',
          );
        }
      },
      'Please enter your email',
    )) {
      return;
    }

    // Validate password input
    if (!InputValidator.validateField(
      password,
      (error) {
        if (error) {
          DialogUtils.showErrorDialog(
            context: context,
            message: 'Please enter your password',
          );
        }
      },
      'Please enter your password',
    )) {
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Attempt to log in using AuthService
      final userRole = await _authService.login(email, password);

      // Check if the user account is active
      if (userRole['status'] != 'active') {
        throw Exception('Your account is not active. Please contact support.');
      }

      // Determine destination based on user type
      final destination = userRole['type'] == "user"
          ? const MainLogScreen()
          : const BizPartnerDashboard();

      // Navigate to the appropriate screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      }
    } catch (e) {
      // Show error message if login fails
      if (mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          message: 'Login failed: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Login",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Opacity(
            opacity: 0.2,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/main_bg.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Content overlay
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Welcome text
                    const Text(
                      "Welcome Back! Glad to see you, Again!",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 37.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email input field
                    TextField(
                      controller: _emailController,
                      decoration: InputValidator.buildInputDecoration(
                        hintText: "Enter your email",
                        hasError: false, // No error by default
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password input field
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputValidator.buildInputDecoration(
                        hintText: "Enter your password",
                        hasError: false, // No error by default
                      ),
                    ),
                    const SizedBox(height: 100),

                    // Login Button with loading state
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _isLoading
                            ? null // Disable button when loading
                            : _login,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Login",
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Register Now Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don’t have an account? "),
                        GestureDetector(
                          onTap: () {
                            // Navigate to SignupType screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupType()),
                            );
                          },
                          child: const Text(
                            "Register Now",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}