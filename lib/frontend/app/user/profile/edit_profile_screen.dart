// lib/ui/screens/profile/edit_profile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../backend/controllers/edit_profile_controller.dart';
import '../../../../backend/controllers/fetch_user_profile_info_controller.dart';
import '../../../../services/country_service.dart';

class EditProfileScreen extends StatelessWidget {
  final VoidCallback onProfileUpdated;
  const EditProfileScreen({
    Key? key,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = context
        .read<FetchUserProfileInfoController>()
        .userProfile!
        .uid;
    return ChangeNotifierProvider<EditProfileController>(
      create: (_) =>
          EditProfileController(Supabase.instance.client, userId),
      child: _EditProfileForm(onProfileUpdated: onProfileUpdated),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  final VoidCallback onProfileUpdated;
  const _EditProfileForm({
    Key? key,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final Future<List<String>> _countriesFuture;

  @override
  void initState() {
    super.initState();
    _countriesFuture = CountryService().fetchCountries();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EditProfileController>();
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.green),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.green),
        elevation: 1,
      ),
      body: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: FutureBuilder<List<String>>(
                future: _countriesFuture,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  if (snap.hasError || snap.data == null) {
                    return const Center(
                        child: Text('Error loading countries'));
                  }
                  final countries = snap.data!;

                  return Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          // Name
                          TextFormField(
                            initialValue: c.name,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              border: border,
                              focusedBorder: border.copyWith(
                                borderSide: const BorderSide(
                                    color: Colors.green),
                              ),
                            ),
                            onChanged: (v) => c.name = v,
                            validator: (v) =>
                                (v == null || v.isEmpty)
                                    ? 'Required'
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          // Country
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: c.country.isEmpty
                                ? null
                                : c.country,
                            decoration: InputDecoration(
                              labelText: 'Country',
                              border: border,
                              focusedBorder: border.copyWith(
                                borderSide: const BorderSide(
                                    color: Colors.green),
                              ),
                            ),
                            items: countries
                                .map((country) =>
                                    DropdownMenuItem(
                                      value: country,
                                      child: Text(
                                        country,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) => c.country = v!,
                            validator: (v) => (v == null ||
                                    v.isEmpty)
                                ? 'Select a country'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Birth Date
                          FormField<DateTime>(
                            initialValue: c.birthDate,
                            validator: (v) =>
                                v == null ? 'Pick a date' : null,
                            builder: (field) {
                              return InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Birth Date',
                                  border: border,
                                  errorText: field.errorText,
                                  focusedBorder: border.copyWith(
                                    borderSide:
                                        const BorderSide(
                                            color:
                                                Colors.green),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () async {
                                    final now =
                                        DateTime.now();
                                    final picked =
                                        await showDatePicker(
                                      context: context,
                                      initialDate:
                                          field.value ??
                                              now,
                                      firstDate:
                                          DateTime(1900),
                                      lastDate: now,
                                    );
                                    if (picked != null) {
                                      c.birthDate = picked;
                                      field.didChange(
                                          picked);
                                    }
                                  },
                                  child: Text(
                                    field.value == null
                                        ? 'Pick date'
                                        : '${field.value!.year}-${field.value!.month.toString().padLeft(2, '0')}-${field.value!.day.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                        fontSize: 16),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Gender
                          DropdownButtonFormField<String>(
                            value: c.gender,
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              border: border,
                              focusedBorder: border.copyWith(
                                borderSide: const BorderSide(
                                    color: Colors.green),
                              ),
                            ),
                            items: ['Male', 'Female']
                                .map((g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ))
                                .toList(),
                            onChanged: (v) => c.gender = v!,
                          ),
                          const SizedBox(height: 16),

                          // Weight
                          TextFormField(
                            initialValue:
                                c.weight.toString(),
                            decoration: InputDecoration(
                              labelText: 'Weight (kg)',
                              border: border,
                              focusedBorder: border.copyWith(
                                borderSide: const BorderSide(
                                    color: Colors.green),
                              ),
                            ),
                            keyboardType:
                                TextInputType.number,
                            onChanged: (v) =>
                                c.weight =
                                    double.tryParse(v) ??
                                        0.0,
                            validator: (v) => double
                                        .tryParse(
                                            v ?? '') ==
                                    null
                                ? 'Enter a number'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Height
                          TextFormField(
                            initialValue:
                                c.height.toString(),
                            decoration: InputDecoration(
                              labelText: 'Height (cm)',
                              border: border,
                              focusedBorder: border.copyWith(
                                borderSide: const BorderSide(
                                    color: Colors.green),
                              ),
                            ),
                            keyboardType:
                                TextInputType.number,
                            onChanged: (v) =>
                                c.height =
                                    double.tryParse(v) ??
                                        0.0,
                            validator: (v) => double
                                        .tryParse(
                                            v ?? '') ==
                                    null
                                ? 'Enter a number'
                                : null,
                          ),
                          const SizedBox(height: 32),
                          
                          ElevatedButton(
                            onPressed: c.isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      c.updateProfile().then((_) {
                                        widget.onProfileUpdated();
                                        Navigator.pop(context);
                                      });
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
                                  child: CircularProgressIndicator(color: Colors.white,strokeWidth: 2,),
                                )
                              : const Text('Save',style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
