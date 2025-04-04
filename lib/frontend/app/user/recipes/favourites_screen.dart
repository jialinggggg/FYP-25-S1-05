import 'package:flutter/material.dart';
import 'recipe_detail_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  List<Map<String, dynamic>> favouriteRecipes = [
    {
      "id": "1",
      "name": "Avocado Toast",
      "image": "https://images.unsplash.com/photo-1515442261605-65987783cb6a",
      "calories": 320,
      "time": 10,
      "difficulty": "Easy",
      "description": "A healthy and delicious breakfast option",
    },
    {
      "id": "2",
      "name": "Vegetable Stir Fry",
      "image": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c",
      "calories": 280,
      "time": 15,
      "difficulty": "Medium",
      "description": "Quick and nutritious vegetable dish",
    },
  ];

  void _removeFromFavourites(String id) {
    setState(() {
      favouriteRecipes.removeWhere((recipe) => recipe["id"] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Removed from favourites")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: favouriteRecipes.isEmpty
          ? const Center(
              child: Text(
                "No favourite recipes yet",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: favouriteRecipes.length,
              itemBuilder: (context, index) {
                final recipe = favouriteRecipes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        recipe["image"],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(recipe["name"]),
                    subtitle: Text("${recipe["calories"]} kcal • ${recipe["time"]} min"),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => _removeFromFavourites(recipe["id"]),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailScreen(
                            recipeId: recipe["id"],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}