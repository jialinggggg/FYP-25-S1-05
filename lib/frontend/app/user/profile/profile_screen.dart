import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../backend/state/user_profile_state.dart';
import 'edit_profile.dart';
import 'edit_goals.dart';
import 'edit_med.dart';

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
          context.read<UserProfileState>().loadProfileData(userId);
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
    return const Padding(
      padding: EdgeInsets.only(left: 8.0),
      child: Text("• Not Applicable", style: TextStyle(color: Colors.grey)),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: conditions
        .map((condition) => Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text("• $condition", style: const TextStyle(fontSize: 16)),
            ))
        .toList(),
  );
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
      body: Consumer<UserProfileState>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// Profile Section
                _buildSection(
                  title: "My Profile",
                  onEdit: () {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            onProfileUpdated: () {
                              final userId = Supabase.instance.client.auth.currentUser?.id;
                              if (userId != null && mounted) {
                                controller.loadProfileData(userId);
                              }
                            },
                          ),
                        ),
                      );
                    }
                  },
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/profile.png'),
                    ),
                    const SizedBox(height: 16),
                    ProfileInfoRow(label: "Name", value: controller.name),
                    ProfileInfoRow(label: "Email", value: controller.email),
                    ProfileInfoRow(label: "Location", value: controller.location),
                    ProfileInfoRow(
                      label: "Birth Date",
                      value: _formatDate(controller.birthDate),
                    ),
                    ProfileInfoRow(label: "Gender", value: controller.gender),
                    ProfileInfoRow(label: "Start Weight", value: "${controller.startWeight} kg"),
                    ProfileInfoRow(label: "Height", value: "${controller.height} cm"),
                  ],
                ),
                const SizedBox(height: 16),

                /// Goals Section
                _buildSection(
                  title: "My Goals",
                  onEdit: () {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditGoalsScreen(
                            onUpdate: () {
                              final userId = Supabase.instance.client.auth.currentUser?.id;
                              if (userId != null && mounted) {
                                controller.loadProfileData(userId);
                              }
                            },
                          ),
                        ),
                      );
                    }
                  },
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("• Goal: ${controller.goal}"),
                          Text("• Activity Level: ${controller.activity}"),
                          Text("• Target Weight: ${controller.targetWeight} kg"),
                          if (controller.targetDate != null)
                            Text("• Target Date: ${_formatDate(controller.targetDate)}"),
                          Text("• Daily Calories: ${controller.dailyCalories} kcal"),
                          Text("• Fats: ${controller.fats} g"),
                          Text("• Protein: ${controller.protein} g"),
                          Text("• Carbs: ${controller.carbs} g"),
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
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditMedicalHistoryScreen(
                            onUpdate: () {
                              final userId = Supabase.instance.client.auth.currentUser?.id;
                              if (userId != null && mounted) {
                                controller.loadProfileData(userId);
                              }
                            },
                          ),
                        ),
                      );
                    }
                  },
                  children: [
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Pre-existing Conditions:", 
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildConditionList(controller.preExistingConditions),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Allergies:", 
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildConditionList(controller.allergies),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                /// Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await controller.logout();
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false, // Remove all previous routes
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logout failed: $e')),
                          );
                        }
                      }
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
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: 4,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context,'/orders');
          } else if (index == 1) {
            Navigator.pushNamed(context,'/recipes');
          } else if (index == 2) {
            Navigator.pushNamed(context,'/log');
          } else if (index == 3) {
            Navigator.pushNamed(context,'/dashboard');
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

class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}