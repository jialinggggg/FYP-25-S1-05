import 'package:flutter/material.dart';
import 'main_log_screen.dart';
import 'add_recipe.dart';
import 'recipe_detail.dart';
import 'orders_screen.dart';
import "favourites_screen.dart";
import 'my_recipes.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  RecipesScreenState createState() => RecipesScreenState();
}



/// ✅ Placeholder Screens for Missing Pages
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

class RecipesScreenState extends State<RecipesScreen> {

  int _selectedTab = 0; // 0: Discover, 1: Favourites, 2: My Recipes
  List<Map<String, dynamic>> favouriteRecipes = []; // Stores Favourite Recipes
  List<Map<String, dynamic>> myRecipes = []; // ✅ Stores Only User-Added Recipes

  void _addToFavourites(Map<String, dynamic> recipe) {
    setState(() {
      if (favouriteRecipes.contains(recipe)) {
        favouriteRecipes.remove(recipe); // ✅ Remove if already in favourites
      } else {
        favouriteRecipes.add(recipe); // ✅ Add if not in favourites
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
        myRecipes.add(newRecipe); // ✅ Store Only New User-Added Recipes
      });
    }
  }



  /// List of Recipes (Categorized)
  final List<Map<String, dynamic>> allRecipes = [
    {
      "name": "Morning Toast",
      "description": "Crispy toast topped with avocado and eggs.",
      "image": "assets/morning_toast.png",
      "category": "Breakfast",
      "calories": 302,
      "time": 10,
      "ingredients": [
        "2 slices of bread (whole grain, sourdough, or multigrain)",
        "1 egg",
        "1/2 avocado",
        "Handful of spinach",
        "Salt and pepper, to taste"
      ],
      "instructions": [
        "Toast the 2 slices of bread until golden and crispy.",
        "Heat a small non-stick pan over medium heat. Crack the egg and cook to your liking (fried, scrambled, or poached). Season with salt and pepper.",
        "Mash the avocado in a bowl and season with a pinch of salt and pepper.",
        "Sauté the spinach for 1-2 minutes until wilted.",
        "Serve everything on a plate. Optionally, add chili flakes or olive oil."
      ],
    },
    {
      "name": "Beef With Broccoli",
      "description": "Savory beef and broccoli stir-fry with rice.",
      "image": "assets/beef_broccoli.png",
      "category": "Lunch",
      "calories": 450,
      "time": 20,
      "ingredients": [
        "200g beef (sliced thinly)",
        "1 cup broccoli florets",
        "1/2 cup soy sauce",
        "1 tbsp cornstarch",
        "1 tbsp olive oil",
        "1 garlic clove, minced",
        "1 tsp sesame seeds"
      ],
      "instructions": [
        "Marinate beef in soy sauce and cornstarch for 10 minutes.",
        "Heat a pan with olive oil and sauté garlic until fragrant.",
        "Stir-fry beef until browned, then add broccoli and cook for another 5 minutes.",
        "Sprinkle sesame seeds before serving.",
        "Serve hot with steamed rice."
      ],
    },
    {
      "name": "Berry Smoothie",
      "description": "A refreshing blend of mixed berries and yogurt.",
      "image": "assets/berry_smoothie.png",
      "category": "Snacks",
      "calories": 180,
      "time": 5,
      "ingredients": [
        "1/2 cup strawberries",
        "1/2 cup blueberries",
        "1/2 banana",
        "1 cup yogurt",
        "1 tbsp honey",
        "1/2 cup ice"
      ],
      "instructions": [
        "Blend all ingredients until smooth.",
        "Pour into a glass and enjoy immediately."
      ],
    },
    {
      "name": "Grilled Chicken Salad",
      "description": "Healthy grilled chicken with fresh veggies.",
      "image": "assets/grilled_chicken_salad.png",
      "category": "Dinner",
      "calories": 320,
      "time": 15,
      "ingredients": [
        "1 grilled chicken breast",
        "2 cups mixed greens",
        "1/2 avocado, sliced",
        "1/4 cup cherry tomatoes",
        "1 tbsp olive oil",
        "1 tbsp balsamic vinegar",
        "Salt and pepper"
      ],
      "instructions": [
        "Grill the chicken breast until fully cooked.",
        "Slice the chicken and place it on top of mixed greens.",
        "Add avocado and cherry tomatoes.",
        "Drizzle with olive oil and balsamic vinegar.",
        "Season with salt and pepper before serving."
      ],
    },
    {
      "name": "Pancakes",
      "description": "Fluffy pancakes with maple syrup.",
      "image": "assets/pancakes.png",
      "category": "Breakfast",
      "calories": 350,
      "time": 15,
      "ingredients": [
        "1 cup flour",
        "1 tbsp sugar",
        "1 tsp baking powder",
        "1/2 tsp baking soda",
        "1 cup milk",
        "1 egg",
        "1 tbsp melted butter",
        "Maple syrup (for serving)"
      ],
      "instructions": [
        "Mix dry ingredients in a bowl.",
        "Whisk milk, egg, and melted butter, then combine with dry ingredients.",
        "Heat a pan and pour batter to form pancakes.",
        "Cook until bubbles form, then flip and cook the other side.",
        "Serve with maple syrup."
      ],
    },
    {
      "name": "Caesar Salad",
      "description": "Crispy romaine lettuce with Caesar dressing.",
      "image": "assets/caesar_salad.png",
      "category": "Lunch",
      "calories": 250,
      "time": 10,
      "ingredients": [
        "2 cups romaine lettuce, chopped",
        "1/4 cup Parmesan cheese",
        "1/4 cup croutons",
        "3 tbsp Caesar dressing",
        "1 grilled chicken breast (optional)"
      ],
      "instructions": [
        "Chop romaine lettuce and place in a bowl.",
        "Add Parmesan cheese and croutons.",
        "Drizzle with Caesar dressing and toss.",
        "Optionally, top with sliced grilled chicken."
      ],
    },
    {
      "name": "Steak Mashed Potatoes",
      "description": "Steak with mashed potatoes.",
      "image": "assets/steak_mashed_potatoes.png",
      "category": "Dinner",
      "calories": 650,
      "time": 30,
      "ingredients": [
        "200g steak",
        "2 potatoes, peeled and boiled",
        "1/4 cup milk",
        "1 tbsp butter",
        "Salt and pepper",
        "1 tbsp olive oil"
      ],
      "instructions": [
        "Season the steak with salt and pepper.",
        "Heat olive oil in a pan and sear the steak to desired doneness.",
        "Mash the boiled potatoes with butter and milk until smooth.",
        "Serve the steak with mashed potatoes on the side."
      ],
    },
    {
      "name": "Fruit Yogurt Bowl",
      "description": "Greek yogurt topped with fresh fruits.",
      "image": "assets/fruit_yogurt_bowl.png",
      "category": "Snacks",
      "calories": 200,
      "time": 5,
      "ingredients": [
        "1 cup Greek yogurt",
        "1/2 banana, sliced",
        "1/4 cup blueberries",
        "1/4 cup strawberries, sliced",
        "1 tbsp honey",
        "1 tbsp granola"
      ],
      "instructions": [
        "Spoon Greek yogurt into a bowl.",
        "Top with banana, blueberries, and strawberries.",
        "Drizzle honey and sprinkle granola on top.",
        "Enjoy fresh!"
      ],
    },
  ];

  /// Stores the filtered recipes (Initially all recipes)
  List<Map<String, dynamic>> filteredRecipes = [];

  /// Search Controller
  final TextEditingController _searchController = TextEditingController();

  /// Navigation Index
  int _selectedIndex = 1; // Recipes is the current page

  @override
  void initState() {
    super.initState();
    filteredRecipes = List.from(allRecipes); // Initialize with all recipes
  }

  /// Search Logic
  void _filterRecipes(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredRecipes = List.from(allRecipes);
      } else {
        filteredRecipes = allRecipes
            .where((recipe) =>
            recipe["name"].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Widget _buildCategoryButton(String title, int index) {
    return ElevatedButton(
      onPressed: () {
        if (index == 1) { // ✅ Favourites Button
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FavouritesScreen(
                favouriteRecipes: favouriteRecipes,
                onFavourite: _addToFavourites,
              ),
            ),
          );
        } else if (index == 2) { // ✅ "My Recipes" Button (Only New Recipes)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyRecipesScreen(
                myRecipes: myRecipes, // ✅ Pass only user-added recipes
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

  /// Navigation Logic
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
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MainLogScreen()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaceholderScreen(title: "Dashboard")));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaceholderScreen(title: "Profile")));
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
                onChanged: _filterRecipes,
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
                height: 230,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredRecipes.length,
                  itemBuilder: (context, index) {
                    return _buildFramedRecipe(filteredRecipes[index]);
                  },
                ),
              ),



              /// Meal Sections
              _buildMealSection("Breakfast"),
              _buildMealSection("Lunch"),
              _buildMealSection("Dinner"),
              _buildMealSection("Snacks"),
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
  Widget _buildMealSection(String category) {
    List<Map<String, dynamic>> mealRecipes =
    filteredRecipes.where((recipe) => recipe["category"] == category).toList();

    if (mealRecipes.isEmpty) return const SizedBox(); // Hide empty sections

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          category,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        GridView.builder(
          shrinkWrap: true, // Prevents overflow inside Column
          physics: const NeverScrollableScrollPhysics(), // Disables inner scrolling
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 items per row
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: mealRecipes.length,
          itemBuilder: (context, index) {
            return _buildFramedRecipe(mealRecipes[index]);
          },
        ),
      ],
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
              onFavourite: _addToFavourites, // ✅ Pass the favourite function
              isFavourite: favouriteRecipes.contains(recipe),
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
              child: Image.asset(recipe["image"], width: 180, height: 140, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(recipe["name"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(recipe["description"], style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

