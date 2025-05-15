// lib/ui/screens/account/edit_account_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../backend/signup/input_validator.dart';
import '../../../../backend/controllers/edit_account_controller.dart';

class EditAccountScreen extends StatelessWidget {
  final VoidCallback onAccountUpdated;
  const EditAccountScreen({super.key, required this.onAccountUpdated});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser!;
    return ChangeNotifierProvider(
      create: (_) => EditAccountController(supabase, user.id),
      child: _EditAccountForm(onAccountUpdated: onAccountUpdated),
    );
  }
}

class _EditAccountForm extends StatefulWidget {
  final VoidCallback onAccountUpdated;
  const _EditAccountForm({required this.onAccountUpdated});

  @override
  State<_EditAccountForm> createState() => _EditAccountFormState();
}

class _EditAccountFormState extends State<_EditAccountForm> {
  final _formKey = GlobalKey<FormState>();

  String _criteriaText(String key) {
    switch (key) {
      case 'hasMinLength':
        return 'Be at least 8 characters';
      case 'hasUppercase':
        return 'Include an uppercase letter';
      case 'hasNumber':
        return 'Include a number';
      case 'hasSymbol':
        return 'Include a symbol (e.g. !@#\$)';
      default:
        return key;
    }
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

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EditAccountController>();
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account', style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.green),
        elevation: 1,
      ),
      body: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // — Email —
                      TextFormField(
                        initialValue: c.email,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: border,
                          focusedBorder: border.copyWith(
                              borderSide: const BorderSide(color: Colors.green)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => c.email = v,
                        validator: (v) =>
                            (v == null || !InputValidator.isValidEmail(v))
                                ? 'Enter a valid email'
                                : null,
                      ),
                      const SizedBox(height: 16),

                      // — New Password —
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          border: border,
                          focusedBorder: border.copyWith(
                              borderSide: const BorderSide(color: Colors.green)),
                        ),
                        obscureText: true,
                        onChanged: (v) => c.password = v,
                      ),
                      const SizedBox(height: 16),

                      // — Password Guidelines —
                      Text('Your password must:',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 8),
                      ...c.passwordCriteria.entries.map(
                        (e) => _buildPasswordGuideline(
                          _criteriaText(e.key),
                          e.value,
                        ),
                      ),

                      const Spacer(),

                      // — Save Button —
                      ElevatedButton(
                        onPressed: c.isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  try {
                                    await c.updateAccount();
                                    widget.onAccountUpdated();
                                    if (context.mounted) Navigator.pop(context);
                                  } catch (e) {
                                    if (context.mounted){
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: c.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save',
                                style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
