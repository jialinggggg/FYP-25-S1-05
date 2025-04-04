import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_recipe.dart';
import 'edit_recipe.dart';
import '../../../../backend/supabase/recipe_service.dart';
import '../../../../backend/supabase/user_profiles_service.dart';
import '../../../../backend/supabase/business_profiles_service.dart';
import '../../../../backend/supabase/accounts_service.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  List<Map<String, dynamic>> myRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final recipeService = RecipeService(
        supabase,
        AccountService(supabase),
        UserProfilesService(supabase),
        BusinessProfilesService(supabase),
      );
      final recipes = await recipeService.getUserRecipes(user.id);
      setState(() {
        myRecipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recipes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
          );
          // Refresh recipes after returning from AddRecipeScreen
          await _loadRecipes();
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : myRecipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "You haven't added any recipes yet",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AddRecipeScreen()),
                          );
                          await _loadRecipes();
                        },
                        child: const Text("Add Your First Recipe"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRecipes,
                  child: ListView.builder(
                    itemCount: myRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = myRecipes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: recipe['image'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    recipe['image'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.fastfood, size: 40),
                                  ),
                                )
                              : const Icon(Icons.fastfood, size: 40),
                          title: Text(recipe['name'] ?? 'Untitled Recipe'),
                          subtitle: Text(
                              "${recipe['calories'] ?? '?'} kcal • ${recipe['ready_in_minutes'] ?? '?'} min"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditRecipeScreen(
                                  recipeId: recipe['id'].toString(),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}