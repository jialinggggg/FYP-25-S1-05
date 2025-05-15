import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../backend/controllers/fetch_nutri_profile_controller.dart';
import '../../../../backend/controllers/edit_nutri_profile_controller.dart';

class EditNutritionistProfileScreen extends StatelessWidget {
  final VoidCallback onProfileUpdated;

  const EditNutritionistProfileScreen({
    super.key,
    required this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final fetchCtrl = context.read<FetchNutritionistProfileInfoController>();
    final profile  = fetchCtrl.nutritionistProfile!;
    final uid      = fetchCtrl.account!.uid;

    return ChangeNotifierProvider(
      create: (_) => EditNutritionistProfileController(
        Supabase.instance.client,
        profile,
        uid,
      ),
      child: _EditNutritionistProfileForm(onProfileUpdated: onProfileUpdated),
    );
  }
}

class _EditNutritionistProfileForm extends StatefulWidget {
  final VoidCallback onProfileUpdated;

  const _EditNutritionistProfileForm({
    required this.onProfileUpdated,
  });

  @override
  State<_EditNutritionistProfileForm> createState() =>
      _EditNutritionistProfileFormState();
}

class _EditNutritionistProfileFormState
    extends State<_EditNutritionistProfileForm> {
  final _formKey = GlobalKey<FormState>();
  String? _docsError;

  Future<void> _pickScans() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final files = result.paths
          .where((p) => p != null)
          .map((p) => File(p!))
          .toList();
      if (files.isNotEmpty && mounted) {
        context.read<EditNutritionistProfileController>().addNewScans(files);
      }
    }
  }

  Future<void> _selectDate({required bool isIssuance}) async {
    final c   = context.read<EditNutritionistProfileController>();
    final now = DateTime.now();
    final initial = isIssuance
        ? c.issuanceDate
        : c.expirationDate;
    final first = isIssuance ? DateTime(1900) : c.issuanceDate;
    final last  = isIssuance ? now : DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      if (isIssuance) {
        c.issuanceDate = picked;
      } else {
        c.expirationDate = picked;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final c      = context.watch<EditNutritionistProfileController>();
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Credentials',
            style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.green),
        elevation: 1,
      ),
      body: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Full Name
                      TextFormField(
                        initialValue: c.fullName,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: border,
                          focusedBorder: border.copyWith(
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                        ),
                        onChanged: (v) => c.fullName = v,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Organization (optional)
                      TextFormField(
                        initialValue: c.organization,
                        decoration: InputDecoration(
                          labelText: 'Organization (optional)',
                          border: border,
                          focusedBorder: border.copyWith(
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                        ),
                        onChanged: (v) => c.organization = v,
                      ),
                      const SizedBox(height: 16),

                      // License Number
                      TextFormField(
                        initialValue: c.licenseNumber,
                        decoration: InputDecoration(
                          labelText: 'License No. / Reg. ID',
                          border: border,
                          focusedBorder: border.copyWith(
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                        ),
                        onChanged: (v) => c.licenseNumber = v,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Issuing Body
                      TextFormField(
                        initialValue: c.issuingBody,
                        decoration: InputDecoration(
                          labelText: 'Issuing Body',
                          border: border,
                          focusedBorder: border.copyWith(
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                        ),
                        onChanged: (v) => c.issuingBody = v,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Issuance Date
                      FormField<DateTime>(
                        initialValue: c.issuanceDate,
                        validator: (v) => v == null ? 'Select a date' : null,
                        builder: (field) {
                          return InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Issuance Date',
                              border: border,
                              errorText: field.errorText,
                              focusedBorder: border.copyWith(
                                borderSide:
                                    const BorderSide(color: Colors.green),
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _selectDate(isIssuance: true),
                              child: Text(
                                field.value == null
                                    ? 'Pick date'
                                    : '${field.value!.year}-${field.value!.month.toString().padLeft(2, '0')}-${field.value!.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Expiration Date
                      FormField<DateTime>(
                        initialValue: c.expirationDate,
                        validator: (v) => v == null ? 'Select a date' : null,
                        builder: (field) {
                          return InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Expiration Date',
                              border: border,
                              errorText: field.errorText,
                              focusedBorder: border.copyWith(
                                borderSide:
                                    const BorderSide(color: Colors.green),
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _selectDate(isIssuance: false),
                              child: Text(
                                field.value == null
                                    ? 'Pick date'
                                    : '${field.value!.year}-${field.value!.month.toString().padLeft(2, '0')}-${field.value!.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Add more files button
                      OutlinedButton(
                        onPressed: _pickScans,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Add License Scans',
                            style: TextStyle(color: Colors.green)),
                      ),
                      const SizedBox(height: 12),

                      // Existing documents
                      if (c.existingScanUrls.isNotEmpty) ...[
                        const Text('Existing Documents:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...List.generate(c.existingScanUrls.length, (i) {
                          final name = c.existingScanUrls[i].split('/').last;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(name)),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => c.removeExistingScan(i),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 12),
                      ],

                      // Newly picked documents
                      if (c.newLicenseScans.isNotEmpty) ...[
                        const Text('New Documents:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...List.generate(c.newLicenseScans.length, (i) {
                          final name =
                              c.newLicenseScans[i].path.split('/').last;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(name)),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => c.removeNewScan(i),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 12),
                      ],

                      // Document‐required error
                      if (_docsError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _docsError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ),

                      // Save button
                      ElevatedButton(
                        onPressed: c.isLoading
                            ? null
                            : () {
                                final valid = _formKey.currentState!.validate();
                                final hasDoc = c.existingScanUrls.isNotEmpty ||
                                    c.newLicenseScans.isNotEmpty;
                                setState(() {
                                  _docsError = hasDoc
                                      ? null
                                      : 'Please upload at least one document';
                                });

                                if (valid && hasDoc) {
                                  c.updateProfile().then((_) {
                                    widget.onProfileUpdated();
                                    if (context.mounted){
                                      Navigator.pop(context);
                                    }
                                  });
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
                                    color: Colors.white, strokeWidth: 2),
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
