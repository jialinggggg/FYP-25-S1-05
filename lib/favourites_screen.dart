import 'package:flutter/material.dart';
import 'recipe_detail.dart';
import 'recipes_screen.dart';

class FavouritesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favouriteRecipes;
  final Function(Map<String, dynamic>) onFavourite;

  const FavouritesScreen({super.key, required this.favouriteRecipes, required this.onFavourite});

  @override
  FavouritesScreenState createState() => FavouritesScreenState();
}

class FavouritesScreenState extends State<FavouritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredFavourites = [];

  final int _selectedTab = 1; // ✅ Make final since it doesn't change
  int _selectedIndex = 1; // Bottom Navigation Index (Recipes Page)

  @override
  void initState() {
    super.initState();
    filteredFavourites = List.from(widget.favouriteRecipes);
  }

  /// 🔎 **Search Functionality**
  void _filterFavourites(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredFavourites = List.from(widget.favouriteRecipes);
      } else {
        filteredFavourites = widget.favouriteRecipes
            .where((recipe) =>
            recipe["name"].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  /// **Build Category Buttons (Discover, Favourites, My Recipes)**
  Widget _buildCategoryButton(String title, int index) {
    return ElevatedButton(
      onPressed: () {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RecipesScreen()),
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

  /// **Navigation Logic for Bottom Navigation Bar**
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RecipesScreen()),
        );
        break;
      case 1:
      // Stay on Favourites Screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Favourites",
          style: TextStyle(
              color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔎 Search Bar
              TextField(
                controller: _searchController,
                onChanged: _filterFavourites,
                decoration: InputDecoration(
                  hintText: "Search for favourites",
                  prefixIcon: const Icon(Icons.search),
                  border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 10),

              /// 🔘 **Three Buttons (Discover, Favourites, My Recipes)**
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

              /// 📜 **Favourite Recipes List**
              const Text(
                "Your Favourite Recipes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              filteredFavourites.isEmpty
                  ? const Center(
                child: Text(
                  "No favourite recipes yet!",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredFavourites.length,
                itemBuilder: (context, index) {
                  return _buildFramedRecipe(filteredFavourites[index]);
                },
              ),
            ],
          ),
        ),
      ),

      /// **Bottom Navigation Bar**
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
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

  /// ✅ **Framed Recipe Widget with Click Navigation**
  Widget _buildFramedRecipe(Map<String, dynamic> recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              recipe: recipe,
              onFavourite: widget.onFavourite,
              isFavourite: widget.favouriteRecipes.contains(recipe),
            ),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(recipe["image"],
                  width: 180, height: 140, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(recipe["name"],
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            Text(recipe["description"],
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}