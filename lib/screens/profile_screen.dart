import 'package:flutter/material.dart';
import 'orders_screen.dart';
import 'recipes_screen.dart';
import 'main_log_screen.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  /// User Information
  String name = "Jackson";
  String email = "Jackson123@gmail.com";
  String location = "Singapore";

  /// User Goals
  String goal = "Lose weight";
  String targetWeight = "50 kg";
  String dailyCalories = "1,478 kcal";
  String weeklyCalories = "10,346 kcal";
  String monthlyCalories = "44,340 kcal";

  /// User Allergies
  List<String> allergies = ["Peanuts", "Shellfish", "Soy", "Dairy", "Prawn", "Crab"];

  /// Function to Show Edit Modal
  void _showEditModal(String section) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        switch (section) {
          case "My Profile":
            return _editProfileModal();
          case "My Goals":
            return _editGoalsModal();
          case "My Food Allergies":
            return _editAllergiesModal();
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  /// Edit Profile Modal
  Widget _editProfileModal() {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController emailController = TextEditingController(text: email);
    TextEditingController locationController = TextEditingController(text: location);

    return _buildModal(
      title: "Edit Profile",
      children: [
        _buildTextField(controller: nameController, label: "Name"),
        _buildTextField(controller: emailController, label: "Email"),
        _buildTextField(controller: locationController, label: "Location"),
      ],
      onSave: () {
        setState(() {
          name = nameController.text;
          email = emailController.text;
          location = locationController.text;
        });
        Navigator.pop(context);
      },
    );
  }

  /// Edit Goals Modal
  Widget _editGoalsModal() {
    TextEditingController goalController = TextEditingController(text: goal);
    TextEditingController targetWeightController = TextEditingController(text: targetWeight);
    TextEditingController dailyCaloriesController = TextEditingController(text: dailyCalories);
    TextEditingController weeklyCaloriesController = TextEditingController(text: weeklyCalories);
    TextEditingController monthlyCaloriesController = TextEditingController(text: monthlyCalories);

    return _buildModal(
      title: "Edit Goals",
      children: [
        _buildTextField(controller: goalController, label: "Goal"),
        _buildTextField(controller: targetWeightController, label: "Target Weight"),
        _buildTextField(controller: dailyCaloriesController, label: "Daily Calories Intake"),
        _buildTextField(controller: weeklyCaloriesController, label: "Weekly Calories Intake"),
        _buildTextField(controller: monthlyCaloriesController, label: "Monthly Calories Intake"),
      ],
      onSave: () {
        setState(() {
          goal = goalController.text;
          targetWeight = targetWeightController.text;
          dailyCalories = dailyCaloriesController.text;
          weeklyCalories = weeklyCaloriesController.text;
          monthlyCalories = monthlyCaloriesController.text;
        });
        Navigator.pop(context);
      },
    );
  }

  /// Edit Allergies Modal
  Widget _editAllergiesModal() {
    TextEditingController allergiesController = TextEditingController(text: allergies.join(", "));

    return _buildModal(
      title: "Edit Allergies",
      children: [
        _buildTextField(controller: allergiesController, label: "Allergies (comma separated)"),
      ],
      onSave: () {
        setState(() {
          allergies = allergiesController.text.split(',').map((e) => e.trim()).toList();
        });
        Navigator.pop(context);
      },
    );
  }

  /// Reusable Modal Builder
  Widget _buildModal({required String title, required List<Widget> children, required VoidCallback onSave}) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...children,
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Save", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable Text Field
  Widget _buildTextField({required TextEditingController controller, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ///Profile Section
                _buildSection(
                  title: "My Profile",
                  onEdit: () => _showEditModal("My Profile"),
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/profile.png'),
                    ),
                    const SizedBox(height: 16),
                    ProfileInfoRow(label: "Name", value: name),
                    ProfileInfoRow(label: "Email", value: email),
                    ProfileInfoRow(label: "Location", value: location),
                  ],
                ),
                const SizedBox(height: 16),

                /// Goals Section
                _buildSection(
                  title: "My Goals",
                  onEdit: () => _showEditModal("My Goals"),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Ensure left alignment
                        children: [
                          Text("• Goal: $goal"),
                          Text("• Target Weight: $targetWeight"),
                          Text("• Daily Calories Intake: $dailyCalories"),
                          Text("• Weekly Calories Intake: $weeklyCalories"),
                          Text("• Monthly Calories Intake: $monthlyCalories"),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                /// Allergies Section
                _buildSection(
                  title: "My Food Allergies",
                  onEdit: () => _showEditModal("My Food Allergies"),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Ensure left alignment
                        children: allergies.map((allergy) => Text("• $allergy")).toList(),
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
                        MaterialPageRoute(builder: (context) => const LoginScreen()), // ✅ Navigate to LoginScreen
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

      /// 🔹 Bottom Navigation Bar (Same as Main Log Screen)
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
                child: const Text("Edit", style: TextStyle(fontSize: 16, color: Colors.blue)),
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

/// 🔹 Reusable Profile Info Row Widget
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