import 'package:flutter/material.dart';
import 'main_log_screen.dart';
import 'orders_screen.dart';
import 'recipes_screen.dart';
import 'favourites_screen.dart';
import 'profile_screen.dart';
import 'dashboard_screen.dart';
import 'add_recipe.dart';

class MyRecipesScreen extends StatefulWidget {
  static List<Map<String, dynamic>> staticMyRecipes = [];
  final List<Map<String, dynamic>> myRecipes; // Only User-Added Recipes

  const MyRecipesScreen({super.key, required this.myRecipes});

  @override
  MyRecipesScreenState createState() => MyRecipesScreenState();
}

class MyRecipesScreenState extends State<MyRecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredRecipes = [];

  int _selectedTab = 2; // Default to "My Recipes"
  int _selectedIndex = 1; // Default index for "Recipes" tab

  @override
  void initState() {
    super.initState();
    if (MyRecipesScreen.staticMyRecipes.isEmpty) {
      MyRecipesScreen.staticMyRecipes = List.from(widget.myRecipes);
    }
    // Load from static list instead of widget.myRecipes
    filteredRecipes = List.from(MyRecipesScreen.staticMyRecipes);
  }

  /// **Search Functionality**
  void _filterRecipes(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredRecipes = List.from(widget.myRecipes);
      } else {
        filteredRecipes = widget.myRecipes
            .where((recipe) =>
            recipe["name"].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  /// **Category Buttons (Discover, Favourites, My Recipes)**
  Widget _buildCategoryButton(String title, int index) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTab = index;
        });

        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RecipesScreen()),
          );
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FavouritesScreen(
                favouriteRecipes: [],
                onFavourite: (recipe) {},
              ),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedTab == index ? Colors.green : Colors.white,
        foregroundColor: _selectedTab == index ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.green),
        ),
      ),
      child: Text(title, style: const TextStyle(fontSize: 14)),
    );
  }

  /// **Bottom Navigation Bar Logic**
  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });

      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OrdersScreen()),
          );
          break;
        case 1:
          break; // Stay on Recipes screen
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MainLogScreen()),
          );
          break;
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainReportDashboard ()),
          );
          break;
        case 4:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("My Recipes", style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔎 **Search Bar** (Positioned Above Buttons)
            TextField(
              controller: _searchController,
              onChanged: _filterRecipes,
              decoration: InputDecoration(
                hintText: "Search My Recipes",
                prefixIcon: const Icon(Icons.search),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 10),

            /// **Three Buttons (Discover, Favourites, My Recipes)**
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoryButton("Discover", 0),
                  _buildCategoryButton("Favourites", 1),
                  _buildCategoryButton("My Recipes", 2),
                ],
              ),
            ),
            const SizedBox(height: 10),

            /// **My Recipes List**
            const Text(
              "Your Added Recipes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            MyRecipesScreen.staticMyRecipes.isEmpty
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
                      leading: Image.asset(recipe["image"],
                          width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(recipe["name"],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(recipe["description"],
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.green),
                      onTap: () {
                        // Navigate to Recipe Detail
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: () async {
          final newRecipe = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
          );

          if (newRecipe != null) {
            setState(() {
              MyRecipesScreen.staticMyRecipes.add(newRecipe);
              filteredRecipes = List.from(MyRecipesScreen.staticMyRecipes);
            });
          }
        },
      ),

      ///  **Bottom Navigation Bar**
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: "Orders"),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant), label: "Recipes"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Log"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
