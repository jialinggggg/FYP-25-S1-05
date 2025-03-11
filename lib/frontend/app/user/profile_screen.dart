import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'orders_screen.dart';
import 'recipes_screen.dart';
import 'main_log_screen.dart';
import '../shared/login.dart';
import 'dashboard_screen.dart';
import 'edit_profile.dart';
import 'edit_goals.dart';
import 'edit_med.dart';
import '../../../backend/supabase/accounts_service.dart'; // Import the AccountService
import '../../../backend/supabase/user_profiles_service.dart'; // Import the ProfileService
import '../../../backend/supabase/user_medical_service.dart'; // Import the MedicalService
import '../../../backend/supabase/user_goals_service.dart'; // Import the GoalService


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Initialize services
  late final AccountService _accountService;
  late final UserProfilesService _profileService;
  late final UserMedicalService _medicalService;
  late final UserGoalsService _goalsService;


  /// User Information
  String name = "";
  String email = "";
  String location = "";
  DateTime? birthDate;
  String gender = "";
  double startWeight = 0.0;
  double height = 0.0;

  /// User Goals
  double desiredWeight = 0;
  int dailyCalories = 0;
  double fats = 0.0;
  double protein = 0;
  double carbs = 0;

  /// User Medical History
  String preExistingConditions = "";
  String allergies = "";

  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    // Initialize services
    _accountService = AccountService(_supabase);
    _profileService = UserProfilesService(_supabase);
    _medicalService = UserMedicalService(_supabase);
    _goalsService = UserGoalsService(_supabase);


    // Fetch user data
    _fetchUserData();
  }

  /// Fetch User Data from Supabase
  Future<void> _fetchUserData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Fetch profile data
      final profileData = await _profileService.fetchProfile(userId);
      final goalsData = await _goalsService.fetchGoals(userId);
      final medicalHistory = await _medicalService.fetchMedical(userId);
      final accountData = await _accountService.fetchAccount(userId);

      setState(() {
        // Profile Data
        name = profileData?['name'] ?? "";
        email = accountData?['email'] ?? ""; // Fetch email from accounts table
        location = profileData?['country'] ?? "";
        birthDate = DateTime.tryParse(profileData?['birth_date'] ?? "");
        gender = profileData?['gender'] ?? "";
        startWeight = double.tryParse(profileData?['weight']?.toString() ?? '0.0') ?? 0.0;
        height = double.tryParse(profileData?['height']?.toString() ?? '0.0') ?? 0.0;

        // Goals Data
        desiredWeight = double.tryParse(goalsData?['weight']?.toString() ?? '0.0') ?? 0.0;
        dailyCalories = goalsData?['daily_calories'] ?? 0;
        fats = double.tryParse(goalsData?['fats']?.toString() ?? '0.0') ?? 0.0;
        protein = double.tryParse(goalsData?['protein']?.toString() ?? '0.0') ?? 0.0;
        carbs = double.tryParse(goalsData?['carbs']?.toString() ?? '0.0') ?? 0.0;

        // Medical History
        preExistingConditions = medicalHistory?['pre_existing'] ?? "";
        allergies = medicalHistory?['allergies'] ?? "";

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: $e')),
        );
      }
    }
  }

  /// Helper method to format DateTime as a string
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      /// Profile Section
                      _buildSection(
                        title: "My Profile",
                        onEdit: () {
                          // Navigate to the edit profile screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditProfileScreen(onProfileUpdated: _fetchUserData,)),
                          );
                        },
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage('assets/profile.png'),
                          ),
                          const SizedBox(height: 16),
                          ProfileInfoRow(label: "Name", value: name),
                          ProfileInfoRow(label: "Email", value: email),
                          ProfileInfoRow(label: "Location", value: location),
                          ProfileInfoRow(
                            label: "Birth Date",
                            value: birthDate != null ? _formatDate(birthDate!) : "Not set",
                          ),
                          ProfileInfoRow(label: "Gender", value: gender),
                          ProfileInfoRow(label: "Start Weight", value: "$startWeight kg"),
                          ProfileInfoRow(label: "Height", value: "$height cm"),
                        ],
                      ),
                      const SizedBox(height: 16),

                      /// Goals Section
                      _buildSection(
                        title: "My Goals",
                        onEdit: () {
                          // Navigate to the edit goals screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditGoalsScreen(onUpdate: _fetchUserData,)),
                          );
                        },
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• Desired Weight: $desiredWeight kg"),
                                Text("• Daily Calories Intake: $dailyCalories kcal"),
                                Text("• Fats: $fats g"),
                                Text("• Protein: $protein g"),
                                Text("• Carbs: $carbs g"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      /// Medical History Section
                      _buildSection(
                        title: "My Medical History",
                        onEdit: () {
                          // Navigate to the edit medical history screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditMedicalHistoryScreen(onUpdate: _fetchUserData,)),
                          );
                        },
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• Pre-existing Conditions: $preExistingConditions"),
                                const SizedBox(height: 8),
                                Text("• Allergies: $allergies"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      /// Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Logout",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),

      /// Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: 4,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen()));
          } else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const RecipesScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MainLogScreen()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MainReportDashboard()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Recipes"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Log"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  /// Reusable Section Builder
  Widget _buildSection({required String title, required VoidCallback onEdit, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: onEdit,
                child: const Text(
                  "Edit",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// Reusable Profile Info Row Widget
class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}