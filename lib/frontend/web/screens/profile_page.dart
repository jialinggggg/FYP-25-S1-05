import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../backend/supabase/accounts_service.dart';
import '../../../backend/supabase/user_profiles_service.dart';
import '../../../backend/supabase/user_medical_service.dart';
import '../../../backend/supabase/user_goals_service.dart';
import '../../../backend/supabase/business_profile.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  final bool isBusiness;

  const ProfilePage({super.key, required this.uid, required this.isBusiness});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final AccountService _accountService = AccountService(Supabase.instance.client);
  final UserProfilesService _userProfilesService = UserProfilesService(Supabase.instance.client);
  final UserMedicalService _userMedicalService = UserMedicalService(Supabase.instance.client);
  final UserGoalsService _userGoalsService = UserGoalsService(Supabase.instance.client);
  final BusinessProfilesService _businessProfilesService = BusinessProfilesService(Supabase.instance.client);

  Map<String, dynamic>? accountDetails;
  Map<String, dynamic>? profileDetails;
  Map<String, dynamic>? medicalDetails;
  Map<String, dynamic>? goalsDetails;
  Map<String, dynamic>? businessDetails;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch account details
      accountDetails = await _accountService.fetchAccount(widget.uid);

      if (widget.isBusiness) {
        // Fetch business profile details
        businessDetails = await _businessProfilesService.fetchBizProfile(widget.uid);
      } else {
        // Fetch user profile, medical, and goals details
        profileDetails = await _userProfilesService.fetchProfile(widget.uid);
        medicalDetails = await _userMedicalService.fetchMedical(widget.uid);
        goalsDetails = await _userGoalsService.fetchGoals(widget.uid);
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isBusiness ? 'Business Profile' : 'User Profile'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isBusiness) _buildBusinessProfile() else _buildUserProfile(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name: ${profileDetails?["name"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Email: ${accountDetails?["email"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Country: ${profileDetails?["country"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Birth Date: ${profileDetails?["birth_date"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Gender: ${profileDetails?["gender"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Weight: ${profileDetails?["weight"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Height: ${profileDetails?["height"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Pre-existing Conditions: ${medicalDetails?["pre_existing"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Allergies: ${medicalDetails?["allergies"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Daily Calories Goal: ${goalsDetails?["daily_calories"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Protein Goal: ${goalsDetails?["protein"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Carbs Goal: ${goalsDetails?["carbs"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Fats Goal: ${goalsDetails?["fats"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildBusinessProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Business Name: ${businessDetails?["name"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Email: ${accountDetails?["email"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Registration No: ${businessDetails?["registration_no"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Country: ${businessDetails?["country"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Address: ${businessDetails?["address"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Type: ${businessDetails?["type"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
        Text('Description: ${businessDetails?["description"] ?? "N/A"}', style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}