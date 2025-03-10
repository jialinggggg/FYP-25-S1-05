import 'package:flutter/material.dart';
import 'main_log_screen.dart';
import 'signup_welcome.dart'; // Import SignupWelcome screen
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false; // Track loading state
  String _selectedUserType = 'User';

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate inputs using InputValidator
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
  await _authService.login(email, password);

  // Determine destination based on user type
  final destination = _selectedUserType == "User"
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
                    // Role Selection Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedUserType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "User", child: Text("User")),
                      DropdownMenuItem(value: "Business Partner", child: Text("Business Partner")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedUserType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),


                    // Email TextField
                    TextField(
                      controller: _emailController,
                      decoration: InputValidator.buildInputDecoration(
                        hintText: "Enter your email",
                        hasError: false, // No error by default
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password TextField
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputValidator.buildInputDecoration(
                        hintText: "Enter your password",
                        hasError: false, // No error by default
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Add forgot password functionality here
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Login Button with Navigation
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

                    // Register Now Link (Underlined & Linked)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don’t have an account? "),
                        GestureDetector(
                          onTap: () {
                            // Navigate to SignupWelcome screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupWelcome()),
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