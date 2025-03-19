import 'package:flutter/material.dart';
import 'package:nutri_app/frontend/app/user/dashboard_screen.dart';
import 'main_log_screen.dart';
import 'add_recipe.dart';
import 'recipe_detail.dart';
import 'orders_screen.dart';
import "favourites_screen.dart";
import 'my_recipes.dart';
import 'profile_screen.dart';
import '../../../services/spoonacular_api_service.dart'; // Import the Spoonacular API service

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  RecipesScreenState createState() => RecipesScreenState();
}

class RecipesScreenState extends State<RecipesScreen> {
  int _selectedTab = 0; // 0: Discover, 1: Favourites, 2: My Recipes
  List<Map<String, dynamic>> favouriteRecipes = []; // Stores Favourite Recipes
  List<Map<String, dynamic>> myRecipes = []; // Stores Only User-Added Recipes

  // Spoonacular API Service
  final SpoonacularApiService _apiService = SpoonacularApiService();

  // Lists to store fetched recipes
  List<Map<String, dynamic>> recommendedRecipes = [];
  List<Map<String, dynamic>> breakfastRecipes = [];
  List<Map<String, dynamic>> lunchRecipes = [];
  List<Map<String, dynamic>> dinnerRecipes = [];
  List<Map<String, dynamic>> snacksRecipes = [];

  // Loading state
  bool _isLoading = true;

  // Fetch random recipes from Spoonacular
  Future<void> _fetchRecipes() async {
    try {
      // Fetch random recipes for each category
      recommendedRecipes = await _apiService.fetchRandomRecipes(number: 5);
      breakfastRecipes = await _apiService.fetchRandomRecipes(tags: 'breakfast', number: 5);
      lunchRecipes = await _apiService.fetchRandomRecipes(tags: 'lunch', number: 5);
      dinnerRecipes = await _apiService.fetchRandomRecipes(tags: 'dinner', number: 5);
      snacksRecipes = await _apiService.fetchRandomRecipes(tags: 'snack', number: 5);

      // Update the UI
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching recipes: $e"),
          duration: const Duration(seconds: 2),
        ),
      );
      }
    }
  }

  // Load more recipes for a specific category
  Future<void> _loadMoreRecipes(String category) async {
    try {
      List<Map<String, dynamic>> newRecipes = await _apiService.fetchRandomRecipes(
        tags: category.toLowerCase(),
        number: 5,
      );

      setState(() {
        if (category == 'Breakfast') {
          breakfastRecipes.addAll(newRecipes);
        } else if (category == 'Lunch') {
          lunchRecipes.addAll(newRecipes);
        } else if (category == 'Dinner') {
          dinnerRecipes.addAll(newRecipes);
        } else if (category == 'Snacks') {
          snacksRecipes.addAll(newRecipes);
        }
      });
    } catch (e) {
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading more recipes: $e"),
            duration: const Duration(seconds: 2),
          ),
        );
    }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchRecipes(); // Fetch recipes when the screen loads
  }

  void _addToFavourites(Map<String, dynamic> recipe) {
    setState(() {
      if (favouriteRecipes.contains(recipe)) {
        favouriteRecipes.remove(recipe); // Remove if already in favourites
      } else {
        favouriteRecipes.add(recipe); // Add if not in favourites
      }
    });
  }

  void _navigateToAddRecipe() async {
    final newRecipe = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
    );

    if (newRecipe != null) {
      setState(() {
        myRecipes.add(newRecipe); // Store Only New User-Added Recipes
      });
    }
  }

  /// Search Controller
  final TextEditingController _searchController = TextEditingController();

  /// Navigation Index
  int _selectedIndex = 1; // Recipes is the current page

  void _onItemTapped(int index) {
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
        // Stay on Recipes screen
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainLogScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainReportDashboard()),
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

  Widget _buildCategoryButton(String title, int index) {
    return ElevatedButton(
      onPressed: () {
        if (index == 1) { // Favourites Button
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FavouritesScreen(
                favouriteRecipes: favouriteRecipes,
                onFavourite: _addToFavourites,
              ),
            ),
          );
        } else if (index == 2) { // My Recipes Button
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyRecipesScreen(
                myRecipes: myRecipes,
              ),
            ),
          );
        } else {
          setState(() {
            _selectedTab = index;
          });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Recipes",
          style: TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.black),
            onPressed: _navigateToAddRecipe,
          ),
        ],
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
                decoration: InputDecoration(
                  hintText: "Search for recipes",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 10),

              /// 🔘 **Three Buttons for Discover, Favourites, and My Recipes**
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

              /// 📜 Recommended Section (Scrollable to the Left)
              const Text(
                "Recommended",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recommendedRecipes.length,
                        itemBuilder: (context, index) {
                          return _buildFramedRecipe(recommendedRecipes[index]);
                        },
                      ),
              ),

              /// Meal Sections
              _buildMealSection("Breakfast", breakfastRecipes),
              _buildMealSection("Lunch", lunchRecipes),
              _buildMealSection("Dinner", dinnerRecipes),
              _buildMealSection("Snacks", snacksRecipes),
            ],
          ),
        ),
      ),

      /// Bottom Navigation Bar
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

  /// Builds Sections for Breakfast, Lunch, Dinner, Snacks
  Widget _buildMealSection(String category, List<Map<String, dynamic>> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          category,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: 180,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recipes.length + 1, // +1 for the "More" button
                  itemBuilder: (context, index) {
                    if (index == recipes.length) {
                      return GestureDetector(
                        onTap: () => _loadMoreRecipes(category),
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              "More",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }
                    return _buildFramedRecipe(recipes[index]);
                  },
                ),
        ),
      ],
    );
  }

Widget _buildFramedRecipe(Map<String, dynamic> recipe) {
  return GestureDetector(
    onTap: () async {
      // Perform the mapping asynchronously
      final mappedRecipe = await _mapRecipeData(recipe);

      // Navigate to the recipe detail screen
      if (mounted){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              recipe: mappedRecipe, // Pass the mapped recipe
              onFavourite: _addToFavourites,
              isFavourite: favouriteRecipes.contains(recipe),
            ),
          ),
        );
     }
    },
    child: Container(
      width: 150,
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
            child: Image.network(
              recipe["image"] ?? "https://via.placeholder.com/150",
              width: 150,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recipe["title"] ?? "No Title",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

/// Helper method to map recipe data asynchronously
Future<Map<String, dynamic>> _mapRecipeData(Map<String, dynamic> recipe) async {
  return {
    "image": recipe["image"] ?? "https://via.placeholder.com/150",
    "name": recipe["title"] ?? "No Title",
    "calories": recipe["nutrition"]?["nutrients"]?.firstWhere(
      (nutrient) => nutrient["name"] == "Calories",
      orElse: () => {"amount": 0},
    )["amount"]?.round() ?? 0,
    "time": recipe["readyInMinutes"] ?? 0,
    "description": recipe["summary"] ?? "No description available.",
    "ingredients": recipe["extendedIngredients"]
        ?.map<String>((ingredient) => ingredient["original"].toString())
        .toList() ?? ["No ingredients available."],
    "instructions": recipe["analyzedInstructions"]?.isNotEmpty == true
        ? recipe["analyzedInstructions"][0]["steps"]
            ?.map<String>((step) => step["step"].toString())
            .toList() ?? ["No instructions available."]
        : ["No instructions available."],
  };
}
}