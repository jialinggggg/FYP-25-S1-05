import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../backend/state/signup_state.dart';
import '../../../../backend/utils/input_validator.dart';
import '../../../../backend/services/input_validation_service.dart';
import '../../../../backend/services/signup_service.dart';
import '../../../../utils/dialog_utils.dart';

class SignupDetail extends StatefulWidget {
  const SignupDetail({super.key});

  @override
  SignupDetailState createState() => SignupDetailState();
}

class SignupDetailState extends State<SignupDetail> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final InputValidationService _validationService = InputValidationService();
  bool _isLoading = false;
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validatePassword(String password) {
    final validation = InputValidator.validatePassword(password);
    setState(() {
      _hasMinLength = validation['hasMinLength']!;
      _hasUppercase = validation['hasUppercase']!;
      _hasNumber = validation['hasNumber']!;
      _hasSymbol = validation['hasSymbol']!;
    });
  }

  Future<void> _showEmailExistsDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, 
                    size: 56, 
                    color: Colors.orange[800]),
                const SizedBox(height: 16),
                Text(
                  "Email Already Registered",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "The email address you entered is already associated with an existing account.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Back"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Sign In"),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final signupState = context.watch<SignupState>();
    final signupUseCase = context.read<SignupService>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Create Account",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator (step 7 of 7)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                7,
                (index) => Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == 6 ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            Text(
              "Create Your Account!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Email Field
            Text(
              "Email Address",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
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
                signupState.setEmail(value);
                setState(() => _emailError = null);
              },
            ),
            if (_emailError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _emailError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),

            // Password Field
            Text(
              "Password",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
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
                signupState.setPassword(value);
                setState(() => _passwordError = null);
              },
            ),
            if (_passwordError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _passwordError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
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

            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
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
                        onPressed: () async {
                          final emailError = _validationService.validateAccountDetails(
                            signupState.email,
                            signupState.password,
                          );
                          
                          if (emailError != null) {
                            setState(() {
                              _emailError = !InputValidator.isValidEmail(signupState.email) 
                                  ? 'Please enter a valid email' : null;
                              _passwordError = 'Password does not meet requirements';
                            });
                            return;
                          }

                          setState(() => _isLoading = true);
                          try {
                            await signupUseCase.execute(
                              email: signupState.email,
                              password: signupState.password,
                              profile: signupState.profile,
                              medicalInfo: signupState.medicalInfo,
                              goals: signupState.goals,
                            );

                            context.read<SignupState>().clearAll();

                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/signup_result',
                              (route) => false, // Remove all previous routes
                            );
                          } catch (e) {
                            if (e.toString().contains('already registered')) {
                              await _showEmailExistsDialog();
                            } else {
                              DialogUtils.showErrorDialog(
                                context: context,
                                message: 'Registration failed: $e',
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
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