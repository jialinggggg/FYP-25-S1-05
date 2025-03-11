import 'dart:io';
import 'package:flutter/material.dart';
import 'add_recipe.dart';
import 'biz_profile_screen.dart';
import 'biz_products_screen.dart';


class BizPartnerDashboard extends StatefulWidget {
  const BizPartnerDashboard({super.key});

  @override
  BizPartnerDashboardState createState() => BizPartnerDashboardState();
}

class BizPartnerDashboardState extends State<BizPartnerDashboard> {
  List<Map<String, dynamic>> recipes = [];
  List<Map<String, dynamic>> filteredRecipes = [];
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0; // ✅ Default to "Recipes" tab

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterRecipes);
  }

  /// **🔎 Filter Recipes Based on Search Input**
  void _filterRecipes() {
    setState(() {
      String query = _searchController.text.toLowerCase();
      filteredRecipes = recipes.where((recipe) {
        return recipe["name"].toLowerCase().contains(query);
      }).toList();
    });
  }

  /// **➕ Navigate to Add Recipe Screen & Receive New Recipe**
  void _navigateToAddRecipe() async {
    final newRecipe = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
    );

    if (newRecipe != null) {
      setState(() {
        recipes.add(newRecipe);
        filteredRecipes = List.from(recipes); // ✅ Update filtered list
      });
    }
  }

  /// **🔄 Bottom Navigation Logic**
  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });

      switch (index) {
        case 0:
          break; // Stay on Recipes screen
        case 1:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BizProductsScreen()),
          );
          break;
        case 2:

          break;
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BizProfileScreen()),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// 🔹 **AppBar with Add Recipe Button**
      appBar: AppBar(
        title: const Text(
          "My Recipes",
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
            onPressed: _navigateToAddRecipe, // ✅ Navigate to Add Recipe
          ),
        ],
      ),

      /// 📜 **Search Bar & Recipe List**
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔍 **Search Bar**
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search My Recipes",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 10),

            /// 📜 **My Recipes List**
            const Text(
              "Your Added Recipes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            recipes.isEmpty
                ? const Center(
              child: Text(
                "No added recipes yet!",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: filteredRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = filteredRecipes[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: SizedBox(
                        width: 50,
                        height: 50,
                        child: recipe["image"] != null && File(recipe["image"]).existsSync()
                            ? Image.file(File(recipe["image"]), fit: BoxFit.cover)
                            : Image.asset("assets/default_image.png", fit: BoxFit.cover), // ✅ Default image
                      ),
                      title: Text(
                        recipe["name"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${recipe["calories"]} kcal • ${recipe["time"]} min",
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.green),
                      onTap: () {
                        // Navigate to Recipe Detail (Future Feature)
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      /// ✅ **Bottom Navigation Bar (Updated for Business Partner)**
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Recipes"),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: "Products"),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}