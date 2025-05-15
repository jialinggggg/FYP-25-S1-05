import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../backend/signup/biz_signup_state.dart';
import '../../../backend/signup/input_validator.dart';

class SignupBizContactScreen extends StatefulWidget {
  const SignupBizContactScreen({super.key});

  @override
  SignupBizContactScreenState createState() => SignupBizContactScreenState();
}

class SignupBizContactScreenState extends State<SignupBizContactScreen> {
  final _contactNameController  = TextEditingController();
  final _contactRoleController  = TextEditingController();
  final _contactEmailController = TextEditingController();

  String? _contactNameError;
  String? _contactRoleError;
  String? _contactEmailError;

  @override
  void initState() {
    super.initState();
    _contactNameController.addListener(() {
      if (_contactNameController.text.isNotEmpty) {
        setState(() => _contactNameError = null);
      }
      context.read<BusinessSignupState>().setContactName(_contactNameController.text);
    });
    _contactRoleController.addListener(() {
      if (_contactRoleController.text.isNotEmpty) {
        setState(() => _contactRoleError = null);
      }
      context.read<BusinessSignupState>().setContactRole(_contactRoleController.text);
    });
    _contactEmailController.addListener(() {
      if (InputValidator.isValidEmail(_contactEmailController.text)) {
        setState(() => _contactEmailError = null);
      }
      context.read<BusinessSignupState>().setContactEmail(_contactEmailController.text);
    });
  }

  void _validateAndNext() {
    setState(() {
      _contactNameError  = _contactNameController.text.isEmpty  ? 'Please enter contact name'  : null;
      _contactRoleError  = _contactRoleController.text.isEmpty  ? 'Please enter contact role'  : null;
      _contactEmailError = !InputValidator.isValidEmail(_contactEmailController.text)
                              ? 'Please enter a valid email'
                              : null;
    });

    if ([_contactNameError, _contactRoleError, _contactEmailError].every((e) => e == null)) {
      Navigator.pushNamed(context, '/biz_signup_detail');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Business Contact",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Container(
                  width: 116,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == 1 ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
              ),
              const SizedBox(height: 30),

              Text(
                "Who should we contact?",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _contactNameController,
                label: "Contact Person Name",
                hint: "Enter name",
                errorText: _contactNameError,
              ),
              _buildTextField(
                controller: _contactRoleController,
                label: "Contact Person Role",
                hint: "Enter role",
                errorText: _contactRoleError,
              ),
              _buildTextField(
                controller: _contactEmailController,
                label: "Contact Email",
                hint: "Enter email",
                keyboardType: TextInputType.emailAddress,
                errorText: _contactEmailError,
              ),
              const SizedBox(height: 100), // space above bottom navigation
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: _validateAndNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 135, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              child: Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(errorText, style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
