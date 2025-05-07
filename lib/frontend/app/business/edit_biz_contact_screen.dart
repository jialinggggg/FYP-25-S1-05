import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../backend/controllers/fetch_biz_profile_controller.dart';
import '../../../../backend/controllers/edit_biz_contact_controller.dart';

class EditBizContactScreen extends StatelessWidget {
  final VoidCallback onUpdated;
  const EditBizContactScreen({super.key, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final fetchCtrl = context.read<FetchBusinessProfileInfoController>();
    final prof      = fetchCtrl.businessProfile!;
    final uid       = fetchCtrl.account!.uid;

    return ChangeNotifierProvider(
      create: (_) => EditBusinessContactController(
        Supabase.instance.client,
        uid,
        contactName: prof.contactName,
        contactRole: prof.contactRole,
        contactEmail: prof.contactEmail,
      ),
      child: _EditBizContactForm(onUpdated: onUpdated),
    );
  }
}

class _EditBizContactForm extends StatefulWidget {
  final VoidCallback onUpdated;
  const _EditBizContactForm({required this.onUpdated});

  @override
  State<_EditBizContactForm> createState() => _EditBizContactFormState();
}

class _EditBizContactFormState extends State<_EditBizContactForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final c      = context.watch<EditBusinessContactController>();
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Contact', style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.green),
        elevation: 1,
      ),
      body: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Contact Person Name
                    TextFormField(
                      initialValue: c.contactName,
                      decoration: InputDecoration(
                        labelText: 'Contact Person Name',
                        border: border,
                        focusedBorder: border.copyWith(
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                      ),
                      onChanged: (v) => c.contactName = v,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Role
                    TextFormField(
                      initialValue: c.contactRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        border: border,
                        focusedBorder: border.copyWith(
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                      ),
                      onChanged: (v) => c.contactRole = v,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      initialValue: c.contactEmail,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: border,
                        focusedBorder: border.copyWith(
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                      ),
                      onChanged: (v) => c.contactEmail = v,
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: c.isLoading
                          ? null
                          : () async {
                            if (!_formKey.currentState!.validate()) return;
                            // await the update so we can check `mounted` safely
                            await c.updateContact();
                            widget.onUpdated();
                            if (context.mounted){
                            Navigator.of(context).pop();
                            }
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: c.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
