import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../backend/controllers/fetch_user_profile_info_controller.dart';
import 'edit_profile_screen.dart';
import 'edit_goals_screen.dart';
import 'edit_med.dart';
import 'edit_account_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<FetchUserProfileInfoController>().loadProfileData(userId);
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Not set";
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Widget _buildConditionList(List<String> conditions) {
    if (conditions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Text(
          "• Not specified",
          style: TextStyle(color: Colors.grey[600], fontSize: 15),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: conditions
          .map((c) => Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                child: Text("• $c", style: const TextStyle(fontSize: 15, height: 1.4)),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<FetchUserProfileInfoController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            );
          }
          // Data loaded
          final profile = controller.userProfile!;
          final account = controller.account!;
          final goals = controller.userGoals!;
          final medical = controller.medicalInfo!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // — Account Details —
                _buildSection(
                  context,
                  title: "Account Details",
                  icon: Icons.account_circle_outlined,
                  iconColor: Colors.green,
                  onEdit: () => _navigateToEditAccount(context, controller),
                  children: [
                    const SizedBox(height: 12),
                    _buildInfoRow("Email", account.email),
                  ],
                ),
                const SizedBox(height: 20),

                // — Personal Information —
                _buildSection(
                  context,
                  title: "Personal Information",
                  icon: Icons.person_outline,
                  iconColor: Colors.green,
                  onEdit: () => _navigateToEditProfile(context, controller),
                  children: [
                    const SizedBox(height: 12),
                    _buildInfoRow("Name", profile.name),
                    _buildDivider(),
                    _buildInfoRow("Location", profile.country),
                    _buildDivider(),
                    _buildInfoRow("Birth Date", _formatDate(profile.birthDate)),
                    _buildDivider(),
                    _buildInfoRow("Gender", profile.gender),
                    _buildDivider(),
                    _buildInfoRow("Start Weight", "${profile.weight} kg"),
                    _buildDivider(),
                    _buildInfoRow("Height", "${profile.height} cm"),
                  ],
                ),
                const SizedBox(height: 20),

                // — Health Goals —
                _buildSection(
                  context,
                  title: "Health Goals",
                  icon: Icons.flag_outlined,
                  iconColor: Colors.green,
                  onEdit: () => _navigateToEditGoals(context, controller),
                  children: [
                    const SizedBox(height: 12),
                    _buildGoalItem(Icons.linear_scale, "Goal", goals.goal),
                    _buildGoalItem(Icons.directions_run, "Activity Level", goals.activity),
                    _buildGoalItem(Icons.monitor_weight, "Target Weight", "${goals.targetWeight} kg"),
                    _buildGoalItem(Icons.calendar_today, "Target Date", _formatDate(goals.targetDate)),
                    _buildGoalItem(Icons.local_fire_department, "Daily Calories", "${goals.dailyCalories} kcal"),
                    _buildGoalItem(Icons.water_drop, "Fats", "${goals.fats} g"),
                    _buildGoalItem(Icons.fitness_center, "Protein", "${goals.protein} g"),
                    _buildGoalItem(Icons.grain, "Carbs", "${goals.carbs} g"),
                  ],
                ),
                const SizedBox(height: 20),

                // — Medical History —
                _buildSection(
                  context,
                  title: "Medical History",
                  icon: Icons.medical_services_outlined,
                  iconColor: Colors.green,
                  onEdit: () => _navigateToEditMedical(context, controller),
                  children: [
                    const SizedBox(height: 12),
                    const Text("Pre-existing Conditions", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    _buildConditionList(medical.preExisting),
                    const SizedBox(height: 16),
                    const Text("Allergies", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    _buildConditionList(medical.allergies),
                  ],
                ),
                const SizedBox(height: 30),

                // — Logout —
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleLogout(context, controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Log Out", style: TextStyle(color: colors.onPrimary)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 22, color: iconColor ?? theme.primaryColor),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text("Edit"),
            ),
          ]),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 15, color: Colors.black54))),
        Expanded(
          flex: 3,
          child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }

  Widget _buildDivider() => Divider(height: 1, thickness: 0.5, color: Colors.grey[300]);

  Widget _buildGoalItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: Colors.black54))),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  void _navigateToEditAccount(BuildContext context, FetchUserProfileInfoController c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditAccountScreen(onAccountUpdated: () => _refreshProfile(c),),
      ),
    );
  }


  void _navigateToEditProfile(BuildContext context, FetchUserProfileInfoController c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(onProfileUpdated: () => _refreshProfile(c)),
      ),
    );
  }

  void _navigateToEditGoals(BuildContext context, FetchUserProfileInfoController c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditGoalsScreen(onUpdate: () => _refreshProfile(c)),
      ),
    );
  }

  void _navigateToEditMedical(BuildContext context, FetchUserProfileInfoController c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditMedicalHistScreen(onUpdate: () => _refreshProfile(c)),
      ),
    );
  }

  void _refreshProfile(FetchUserProfileInfoController c) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) c.loadProfileData(userId);
  }

  Future<void> _handleLogout(BuildContext context, FetchUserProfileInfoController c) async {
    try {
      await c.logout();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 4,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      onTap: (i) {
        if (i == 4) return;
        Navigator.pushReplacementNamed(
          context,
          ['/orders', '/main_recipes', '/log', '/dashboard', '/profile'][i],
        );
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Orders"),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Recipes"),
        BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Journal"),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
