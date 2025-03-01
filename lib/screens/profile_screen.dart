import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'login.dart';
import 'orders_screen.dart';
import 'recipes_screen.dart';
import 'main_log_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

/// Placeholder Screens for Missing Pages
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          "$title Page Coming Soon...",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class ProfileScreenState extends State<ProfileScreen> {
  /// Navigation Index
  int _selectedIndex = 4; // Profile is the current page

  /// Navigation Logic
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Orders
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrdersScreen())
        );
        break;
      case 1: // Recipes
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RecipesScreen())
        );
        break;
      case 2: // Log
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainLogScreen())
        );
        break;
      case 3: // Dashboard (Placeholder)
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen())
        );
        break;
      case 4: // Profile (stay here)
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: TextStyle(color: Colors.green[800], fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // Add Edit functionality
            },
            child: const Text("Edit", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/profile_image.png'),
                  ),
                  const SizedBox(height: 10),
                  const Text("Jackson", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text("Jackson123@gmail.com", style: TextStyle(color: Colors.grey)),
                  const Text("Singapore", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // My Goals Section
            _buildSection("My Goals", [
              "• Goal: Lose weight",
              "• Target weight: 50 kg",
              "• Daily Calories Intake: 1,478 kcal",
              "• Weekly Calories Intake: 10,346 kcal",
              "• Monthly Calories Intake: 44,340 kcal",
            ]),

            const SizedBox(height: 20),

            // My Food Allergies Section
            _buildSection("My Food Allergies", [
              "• Peanuts",
              "• Shellfish",
              "• Dairy",
              "• Prawns",
              "• Crab",
            ]),

            const SizedBox(height: 20),

            // Logout Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: const Text("Log Out", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_rounded), label: "Recipes"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.list_bullet_below_rectangle,), label: "Logs"),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    // Add edit functionality here
                  },
                  child: const Text("Edit", style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
            for (var item in items) Text(item, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}