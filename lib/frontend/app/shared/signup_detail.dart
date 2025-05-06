// lib/ui/signup/signup_details.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../backend/controllers/user_signup_controller.dart';
import '../../../backend/controllers/biz_signup_controller.dart';
import '../../../backend/controllers/nutritionist_signup_controller.dart';
import '../../../backend/entities/business_profile.dart';
import '../../../backend/entities/nutritionist_profile.dart';
import '../../../backend/signup/signup_state.dart';
import '../../../backend/signup/biz_signup_state.dart';
import '../../../backend/signup/nutri_signup_state.dart';
import '../../../backend/signup/input_validation_service.dart';
import '../../../backend/signup/input_validator.dart';
import '../../../utils/dialog_utils.dart';

class SignupDetail extends StatefulWidget {
  final String type;

  const SignupDetail({super.key, required this.type});

  @override
  SignupDetailState createState() => SignupDetailState();
}

class SignupDetailState extends State<SignupDetail> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _validationService  = InputValidationService();

  bool _isLoading    = false;
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber    = false;
  bool _hasSymbol    = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validatePassword(String password) {
    final v = InputValidator.validatePassword(password);
    setState(() {
      _hasMinLength = v['hasMinLength']!;
      _hasUppercase = v['hasUppercase']!;
      _hasNumber    = v['hasNumber']!;
      _hasSymbol    = v['hasSymbol']!;
    });
  }

  Future<void> _showEmailExistsDialog() async {
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: Colors.orange[800]),
              const SizedBox(height: 16),
              Text(
                "Email Already Registered",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "The email address you entered is already associated with an existing account.",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Back"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text("Sign In"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordGuideline(String text, bool valid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: valid ? Colors.green : Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 14, color: valid ? Colors.green : Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure valid signup type
    assert(
      widget.type == 'user' || widget.type == 'business' || widget.type == 'nutritionist',
      'SignupDetail must receive a valid type',
    );

    // Watch states and controllers
    final signupState     = context.watch<SignupState>();
    final bizState        = context.watch<BusinessSignupState>();
    final nutriState      = context.watch<NutritionistSignupState>();
    final userController  = context.read<SignupController>();
    final bizController   = context.read<BizSignupController>();
    final nutriController = context.read<NutritionistSignupController>();

    // Validation flags
    final isEmailValid    = InputValidator.isValidEmail(signupState.email);
    final pwdChecks       = InputValidator.validatePassword(signupState.password);
    final isPasswordValid = pwdChecks.values.every((v) => v);
    final hasNutriDates   = nutriState.issuanceDate != null && nutriState.expirationDate != null;
    final canSubmit       = !_isLoading
      && isEmailValid
      && isPasswordValid
      && (widget.type != 'nutritionist' || hasNutriDates);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Center(
              child: Text(
                "Create Your Account!",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator (step 7 of 7)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (i) => Container(
                width: 40, height: 5, margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == 6 ? Colors.green : Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
            ),
            const SizedBox(height: 30),

            // Email field
            Text("Email Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "Enter your email",
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (_) {
                signupState.setEmail(_emailController.text);
                setState(() => _emailError = null);
              },
            ),
            if (_emailError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(_emailError!, style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 20),

            // Password field & guidelines
            Text("Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: "Create a strong password",
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              obscureText: true,
              onChanged: (v) {
                signupState.setPassword(v);
                _validatePassword(v);
                setState(() => _passwordError = null);
              },
            ),
            if (_passwordError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(_passwordError!, style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 10),
            _buildPasswordGuideline("Be at least 8 characters", _hasMinLength),
            _buildPasswordGuideline("Include at least one uppercase letter", _hasUppercase),
            _buildPasswordGuideline("Include at least one number", _hasNumber),
            _buildPasswordGuideline("Include at least one symbol", _hasSymbol),
            const SizedBox(height: 25),

            const Spacer(),

            // Inline hint for missing nutritionist dates
            if (widget.type == 'nutritionist' && !hasNutriDates)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Please complete your license issuance & expiration dates.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            // Action buttons
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
                      onPressed: canSubmit
                        ? () async {
                            setState(() => _isLoading = true);
                            try {
                              switch (widget.type) {
                                case 'user':
                                  await userController.execute(
                                    email: signupState.email,
                                    password: signupState.password,
                                    profile: signupState.profile,
                                    medicalInfo: signupState.medicalInfo,
                                    goals: signupState.goals,
                                  );
                                  // Navigate to user-specific result
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/user_signup_detail',
                                    (route) => false,
                                  );
                                  break;

                                case 'business':
                                  final bp = BusinessProfile(
                                    businessName:        bizState.businessName,
                                    registrationNo:      bizState.registrationNo,
                                    country:             bizState.businessCountry,
                                    address:             bizState.businessAddress,
                                    description:         bizState.businessDescription,
                                    contactName:         bizState.contactName,
                                    contactRole:         bizState.contactRole,
                                    contactEmail:        bizState.contactEmail,
                                    website:             bizState.website,
                                    registrationDocUrls: [],
                                  );
                                  await bizController.execute(
                                    email: signupState.email,
                                    password: signupState.password,
                                    profile: bp,
                                    registrationDocuments: bizState.registrationDocs,
                                  );
                                  // Navigate to business/nutritionist result
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/biz_signup_result',
                                    (route) => true,
                                  );
                                  break;

                                case 'nutritionist':
                                  final np = NutritionistProfile(
                                    fullName:       nutriState.fullName,
                                    organization:   nutriState.organization.isEmpty
                                        ? null
                                        : nutriState.organization,
                                    licenseNumber:  nutriState.licenseNumber,
                                    issuingBody:    nutriState.issuingBody,
                                    issuanceDate:   nutriState.issuanceDate!,
                                    expirationDate: nutriState.expirationDate!,
                                    licenseScanUrls: [],
                                  );
                                  await nutriController.execute(
                                    email: signupState.email,
                                    password: signupState.password,
                                    profile: np,
                                    licenseScans: nutriState.licenseScans,
                                  );
                                  // Navigate to business/nutritionist result
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/biz_signup_result',
                                    (route) => true,
                                  );
                                  break;

                                default:
                                  throw StateError('Unknown signup type: ${widget.type}');
                              }
                            } catch (e) {
                              if (!mounted) return;
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
                          }
                        : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      ),
                      child: const Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
