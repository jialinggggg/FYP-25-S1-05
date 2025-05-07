import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../backend/controllers/fetch_biz_profile_controller.dart';
import '../../../../backend/controllers/edit_biz_profile_controller.dart';

class EditBizProfileScreen extends StatelessWidget {
  final VoidCallback onUpdated;
  const EditBizProfileScreen({super.key, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final fetchCtrl = context.read<FetchBusinessProfileInfoController>();
    final prof      = fetchCtrl.businessProfile!;
    final uid       = fetchCtrl.account!.uid;

    return ChangeNotifierProvider(
      create: (_) => EditBusinessProfileController(
        Supabase.instance.client,
        prof,
        uid,
      ),
      child: _EditBizProfileForm(onUpdated: onUpdated),
    );
  }
}

class _EditBizProfileForm extends StatefulWidget {
  final VoidCallback onUpdated;
  const _EditBizProfileForm({required this.onUpdated});

  @override
  State<_EditBizProfileForm> createState() => _EditBizProfileFormState();
}

class _EditBizProfileFormState extends State<_EditBizProfileForm> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickDocs() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf','jpg','png'],
    );
    if (res != null && res.files.isNotEmpty) {
      final files = res.paths.whereType<String>().map((p) => File(p)).toList();
      if (files.isNotEmpty && mounted) {
        context.read<EditBusinessProfileController>().addNewDocs(files);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c      = context.watch<EditBusinessProfileController>();
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Business Profile', style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.green),
        elevation: 1,
      ),
      body: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Business Name
                    TextFormField(
                      initialValue: c.businessName,
                      decoration: InputDecoration(
                        labelText: 'Business Name',
                        border: border,
                        focusedBorder: border.copyWith(
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                      ),
                      onChanged: (v) => c.businessName = v,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Registration No.
                    TextFormField(
                      initialValue: c.registrationNo,
                      decoration: InputDecoration(
                        labelText: 'Registration No.',
                        border: border,
                        focusedBorder: border.copyWith(
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                      ),
                      onChanged: (v) => c.registrationNo = v,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Country
                    TextFormField(
                      initialValue: c.country,
                      decoration: InputDecoration(
                        labelText: 'Country',
                        border: border,
                        focusedBorder: border.copyWith(
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                      ),
                      onChanged: (v) => c.country = v,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      initialValue: c.address,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: border,
                        focusedBorder: border.copyWith(
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                      ),
                      onChanged: (v) => c.address = v,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      initialValue: c.description,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: border,
                        focusedBorder: border.copyWith(
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                      ),
                      maxLines: 3,
                      onChanged: (v) => c.description = v,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Website (optional)
                    TextFormField(
                      initialValue: c.website,
                      decoration: InputDecoration(
                        labelText: 'Website (optional)',
                        border: border,
                        focusedBorder: border.copyWith(
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                      ),
                      onChanged: (v) => c.website = v,
                    ),
                    const SizedBox(height: 24),

                    // Document uploads (optional)
                    OutlinedButton(
                      onPressed: _pickDocs,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Add Registration Docs', style: TextStyle(color: Colors.green)),
                    ),
                    const SizedBox(height: 12),

                    // Existing docs
                    if (c.existingDocUrls.isNotEmpty) ...[
                      const Text('Existing Docs:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...List.generate(c.existingDocUrls.length, (i) {
                        final name = c.existingDocUrls[i].split('/').last;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(name)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => c.removeExistingDoc(i),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    // New docs
                    if (c.newDocs.isNotEmpty) ...[
                      const Text('New Docs:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...List.generate(c.newDocs.length, (i) {
                        final name = c.newDocs[i].path.split('/').last;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(name)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => c.removeNewDoc(i),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    // Save
                    ElevatedButton(
                      onPressed: c.isLoading
                          ? null
                          : () async {
                            if (!_formKey.currentState!.validate()) return;
                            // await the update so we can check `mounted` safely
                            await c.updateProfile();
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
