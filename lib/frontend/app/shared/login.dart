// lib/ui/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../backend/controllers/login_controller.dart';
import '../../../../backend/entities/account.dart';
import '../../../utils/dialog_utils.dart';
import '../../../utils/input_validator.dart';
import '../user/meal/main_log_screen.dart';
import '../business/biz_partner_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final LoginController _controller;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = LoginController(Supabase.instance.client);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      Account account = await _controller.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      if (account.status != 'active') {
        throw Exception('Your account is not active. Please contact support.');
      }

      final destination = account.type == 'user'
          ? const MainLogScreen()
          : const BizPartnerDashboard();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
      }
    } catch (e) {
      DialogUtils.showErrorDialog(
        context: context,
        message: 'Login failed: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // match signup look
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "EATWELL",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email field
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: InputDecoration(
                          hintText: "Enter your email",
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => InputValidator.validateField(
                          v?.trim() ?? '',
                          (_) {},
                          'Please enter your email',
                        )
                            ? null
                            : 'Please enter your email',
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: InputDecoration(
                          hintText: "Enter your password",
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        obscureText: true,
                        validator: (v) => InputValidator.validateField(
                          v?.trim() ?? '',
                          (_) {},
                          'Please enter your password',
                        )
                            ? null
                            : 'Please enter your password',
                      ),
                      const SizedBox(height: 40),

                      // Login button
                      SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don’t have an account? "),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/signup_type'),
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
