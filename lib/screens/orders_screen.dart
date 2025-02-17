import 'package:flutter/material.dart';
import 'recipes_screen.dart';
import 'main_log_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  OrdersScreenState createState() => OrdersScreenState();
}

class OrdersScreenState extends State<OrdersScreen> {
  int selectedIndex = 0; // Orders is the default page

  void _onItemTapped(int index) {
    if (index == selectedIndex) return; // Prevent reloading the same page

    switch (index) {
      case 0: // Orders (stay here)
        break;
      case 1: // Recipes
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RecipesScreen()),
        );
        break;
      case 2: // Log
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLogScreen()),
        );
        break;
      case 3: // Dashboard (Placeholder)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PlaceholderScreen(title: "Dashboard"),
          ),
        );
        break;
      case 4: // Profile (Placeholder)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PlaceholderScreen(title: "Profile"),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orders")),
      body: const Center(
        child: Text(
          "Your Orders Page",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
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
}

/// Placeholder screen for unimplemented pages
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