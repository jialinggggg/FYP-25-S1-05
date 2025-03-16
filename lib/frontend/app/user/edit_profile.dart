import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/country_service.dart';
import '../../../utils/input_validator.dart';
import '../../../../utils/date_picker.dart';
import '../../../../utils/widget_utils.dart';
import '../../../../utils/dialog_utils.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../backend/supabase/user_profiles_service.dart'; // Import UserProfilesService

class EditProfileScreen extends StatefulWidget {
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({super.key, required this.onProfileUpdated});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final CountryService _countryService = CountryService();
  final UserProfilesService _userProfilesService = UserProfilesService(Supabase.instance.client); // Initialize UserProfilesService

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDate;
  String? _selectedCountry;
  List<String> countries = [];
  bool _isLoading = true;

  bool _nameError = false;
  bool _locationError = false;
  bool _genderError = false;
  bool _birthDateError = false;
  bool _heightError = false;
  bool _weightError = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _fetchCountries();
  }

  Future<void> _fetchProfileData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Use UserProfilesService to fetch profile data
      final profileData = await _userProfilesService.fetchProfile(userId);
      if (!mounted) return;

      setState(() {
        _nameController.text = profileData?['name'] ?? "";
        _locationController.text = profileData?['country'] ?? "";
        _selectedDate = DateTime.tryParse(profileData?['birth_date'] ?? "");
        _birthDateController.text = _selectedDate != null
            ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"
            : "";
        _selectedGender = profileData?['gender'] ?? "";
        _weightController.text = profileData?['weight']?.toString() ?? "";
        _heightController.text = profileData?['height']?.toString() ?? "";
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile data: $e')),
        );
      }
    }
  }

  Future<void> _fetchCountries() async {
    try {
      final countryNames = await _countryService.fetchCountries();
      if (mounted) {
        setState(() {
          countries = countryNames;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching countries: $e')),
        );
      }
    }
  }

  bool _validateFields() {
    bool isValid = true;

    isValid &= InputValidator.validateField(
      _nameController.text,
      (error) => setState(() => _nameError = error),
      "Name cannot be empty",
    );

    isValid &= InputValidator.validateField(
      _selectedCountry ?? _locationController.text,
      (error) => setState(() => _locationError = error),
      "Location cannot be empty",
    );

    isValid &= InputValidator.validateField(
      _selectedGender,
      (error) => setState(() => _genderError = error),
      "Gender cannot be empty",
    );

    isValid &= InputValidator.validateField(
      _birthDateController.text,
      (error) => setState(() => _birthDateError = error),
      "Birthdate cannot be empty",
    );

    isValid &= InputValidator.validateNumericField(
      _heightController.text,
      (error) => setState(() => _heightError = error),
      50,
      300,
      "Height must be between 50 cm and 300 cm",
    );

    isValid &= InputValidator.validateNumericField(
      _weightController.text,
      (error) => setState(() => _weightError = error),
      20,
      500,
      "Weight must be between 20 kg and 500 kg",
    );

    return isValid;
  }

  Future<void> _updateProfile() async {
    if (!_validateFields()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _selectedDate == null) return;

    try {
      await _userProfilesService.updateProfile(
        uid: userId,
        name: _nameController.text,
        birthdate: _selectedDate!,
        country: _selectedCountry ?? _locationController.text,
        gender: _selectedGender ?? "",
        weight: double.tryParse(_weightController.text) ?? 0.0,
        height: double.tryParse(_heightController.text) ?? 0.0,
      );

      if (!mounted) return;

      DialogUtils.showSuccessDialog(
        context: context,
        message: 'Profile updated successfully.',
        onOkPressed: () {
          Navigator.pop(context); // Close the dialog
          widget.onProfileUpdated(); // Notify ProfileScreen to refresh
          Navigator.pop(context); // Return to the profile screen
        },
      );
    } catch (e) {
      if (!mounted) return;
      DialogUtils.showErrorDialog(
        context: context,
        message: 'Error updating profile: $e',
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await DatePicker.selectDate(context);
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Field
            const Text(
              "Name:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Enter your preferred name",
                errorText: _nameError ? "Name cannot be empty" : null,
              ),
            ),
            const SizedBox(height: 16),

            // Location Field
            const Text(
              "Location:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownSearch<String>(
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: "Search for a country",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      items: countries,
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          hintText: "Select your country",
                          border: InputBorder.none,
                        ),
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCountry = newValue;
                        });
                      },
                      selectedItem: _selectedCountry ?? _locationController.text,
                    ),
                  ),
            if (_locationError)
              Text(
                "Location cannot be empty",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            const SizedBox(height: 16),

            // Gender Field
            WidgetUtils.buildDropdown(
              label: "Gender:",
              value: _selectedGender,
              items: const ["Male", "Female"],
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
              },
              hasError: _genderError,
              errorMessage: "Gender cannot be empty",
            ),
            const SizedBox(height: 16),

            // Birthdate Field
            const Text(
              "Birthdate:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _birthDateController,
                    decoration: InputDecoration(
                      hintText: "Enter your Birthdate",
                      errorText: _birthDateError ? "Birthdate cannot be empty" : null,
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Height Field
            const Text(
              "Height (in cm):",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _heightController,
              decoration: InputDecoration(
                hintText: "Enter your height",
                errorText: _heightError ? "Height must be between 50 cm and 300 cm" : null,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // Weight Field
            const Text(
              "Start Weight (in kg):",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _weightController,
              decoration: InputDecoration(
                hintText: "Enter your weight",
                errorText: _weightError ? "Weight must be between 20 kg and 500 kg" : null,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 100),

            // Delete Account Link
            Center(
              child: GestureDetector(
                onTap: () {
                  // Add logic to delete account
                },
                child: const Text(
                  "Delete Account",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save Button at the Bottom
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}