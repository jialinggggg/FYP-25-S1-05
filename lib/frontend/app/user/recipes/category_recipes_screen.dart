import 'package:flutter/material.dart';
import 'recipe_detail_screen.dart';
import '../../../../services/spoonacular_api_service.dart';
import '../../../../backend/supabase/recipe_service.dart';

class CategoryRecipesScreen extends StatefulWidget {
  final String category;
  final String title;
  final SpoonacularApiService? apiService;
  final RecipeService? recipeService;
  final bool isFromDatabase;

  const CategoryRecipesScreen({
    super.key,
    required this.category,
    required this.title,
    this.apiService,
    this.recipeService,
    this.isFromDatabase = false,
  });

  @override
  State<CategoryRecipesScreen> createState() => _CategoryRecipesScreenState();
}

class _CategoryRecipesScreenState extends State<CategoryRecipesScreen> {
  List<Map<String, dynamic>> recipes = [];
  bool isLoading = true;
  bool hasError = false;
  Map<String, List<Map<String, dynamic>>> categorizedRecipes = {};
  Map<String, int> categoryOffsets = {};

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    
    try {
      if (widget.isFromDatabase) {
        final type = widget.category == "community" 
            ? "user" 
            : widget.category == "business-partner"
                ? "business"
                : "nutritionist";
        
        recipes = await widget.recipeService!.getRecipesByType(type);
      } else if (widget.category == "breakfast" || widget.category == "snack") {
        categorizedRecipes = {
          "Smoothies": await _fetchRecipesByTag("smoothie", 0),
          "Oatmeal": await _fetchRecipesByTag("oatmeal", 0),
          "Pancakes": await _fetchRecipesByTag("pancake", 0),
          "Toast": await _fetchRecipesByTag("toast", 0),
        };
      } else if (widget.category == "lunch" || widget.category == "dinner") {
        categorizedRecipes = {
          "Salads": await _fetchRecipesByTag("salad", 0),
          "Soups": await _fetchRecipesByTag("soup", 0),
          "Rice Dishes": await _fetchRecipesByTag("rice", 0),
          "Noodles": await _fetchRecipesByTag("noodles", 0),
          "Meat": await _fetchRecipesByTag("meat", 0),
        };
      } else if (widget.category.contains("kcal")) {
        final range = widget.category.replaceAll(" kcal", "").split("-");
        final minCal = int.tryParse(range[0]) ?? 0;
        final maxCal = range.length > 1 ? int.tryParse(range[1]) ?? 1000 : 1000;
        
        categorizedRecipes = {
          "Breakfast": await _fetchRecipesByCalories("breakfast", minCal, maxCal, 0),
          "Lunch": await _fetchRecipesByCalories("lunch", minCal, maxCal, 0),
          "Dinner": await _fetchRecipesByCalories("dinner", minCal, maxCal, 0),
          "Snacks": await _fetchRecipesByCalories("snack", minCal, maxCal, 0),
        };
      } else {
        recipes = await _fetchRecipesByTag(widget.category, 0);
      }
      
      categorizedRecipes.forEach((key, value) {
        categoryOffsets[key] = 5;
      });
    } catch (e) {
      if (mounted) {
        setState(() => hasError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading recipes: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecipesByTag(String tag, int offset) async {
    final results = await widget.apiService!.fetchRandomRecipes(
      tags: tag, 
      number: 5,
    );
    return results.where((recipe) => recipe.isNotEmpty).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchRecipesByCalories(
      String tag, int minCal, int maxCal, int offset) async {
    final results = await widget.apiService!.fetchRandomRecipes(
      tags: tag,
      minCalories: minCal,
      maxCalories: maxCal,
      number: 5,
    );
    return results.where((recipe) => recipe.isNotEmpty).toList();
  }

  Future<void> _loadMoreRecipes(String category) async {
    try {
      final currentOffset = categoryOffsets[category] ?? 0;
      List<Map<String, dynamic>> newRecipes = [];
      
      if (widget.isFromDatabase) {
        final type = widget.category == "community" 
            ? "user" 
            : widget.category == "business-partner"
                ? "business"
                : "nutritionist";
        newRecipes = await widget.recipeService!.getRecipesByType(type, offset: currentOffset);
      } else if (widget.category == "breakfast" || widget.category == "snack" || 
          widget.category == "lunch" || widget.category == "dinner") {
        newRecipes = await _fetchRecipesByTag(category.toLowerCase(), currentOffset);
      } else if (widget.category.contains("kcal")) {
        final range = widget.category.replaceAll(" kcal", "").split("-");
        final minCal = int.tryParse(range[0]) ?? 0;
        final maxCal = range.length > 1 ? int.tryParse(range[1]) ?? 1000 : 1000;
        newRecipes = await _fetchRecipesByCalories(category.toLowerCase(), minCal, maxCal, currentOffset);
      }
      
      setState(() {
        if (widget.isFromDatabase) {
          recipes = [...recipes, ...newRecipes];
        } else {
          categorizedRecipes[category] = [...categorizedRecipes[category]!, ...newRecipes];
        }
        categoryOffsets[category] = currentOffset + 5;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading more recipes: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              "Failed to load recipes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _fetchRecipes,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (categorizedRecipes.isEmpty && recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "No recipes found for ${widget.title}",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Try Again", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRecipes,
      color: Colors.green,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.isFromDatabase) {
      return _buildRecipeList(recipes);
    }
    
    if (categorizedRecipes.isEmpty) {
      return _buildRecipeList(recipes);
    }
    
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        for (var entry in categorizedRecipes.entries)
          if (entry.value.isNotEmpty) ...[
            _buildCategoryHeader(entry.key),
            _buildHorizontalRecipeList(entry.key, entry.value),
          ],
      ],
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildHorizontalRecipeList(String category, List<Map<String, dynamic>> recipes) {
    final isMealCategory = widget.category == "breakfast" || 
                         widget.category == "lunch" || 
                         widget.category == "dinner" || 
                         widget.category == "snack";

    return SizedBox(
      height: isMealCategory ? 220 : 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recipes.length + (widget.isFromDatabase ? 0 : 1),
        itemBuilder: (context, index) {
          if (index < recipes.length) {
            return _buildRecipeCard(recipes[index]);
          } else {
            return _buildMoreButton(category);
          }
        },
      ),
    );
  }

  Widget _buildMoreButton(String category) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () => _loadMoreRecipes(category),
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: const Center(
            child: Text(
              "More",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeList(List<Map<String, dynamic>> recipes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildRecipeCard(recipe),
        );
      },
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final isFromDatabase = widget.isFromDatabase;
    final imageUrl = isFromDatabase 
        ? recipe["image"] ?? "https://via.placeholder.com/150"
        : recipe["image"] ?? "https://via.placeholder.com/150";
    
    final title = isFromDatabase 
        ? recipe["name"] ?? "No Title"
        : recipe["title"] ?? "No Title";
    
    final calories = isFromDatabase
        ? recipe["calories"]?.toString() ?? "0"
        : recipe["calories"]?.toString() ?? "0";

    final isMealCategory = widget.category == "breakfast" || 
                         widget.category == "lunch" || 
                         widget.category == "dinner" || 
                         widget.category == "snack";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              recipeId: recipe["id"].toString(),
              isFromDatabase: isFromDatabase,
              recipeService: isFromDatabase ? widget.recipeService : null,
              apiService: isFromDatabase ? null : widget.apiService,
            ),
          ),
        );
      },
      child: Container(
        width: isMealCategory ? 180 : 150,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: isMealCategory ? 140 : 120,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMealCategory ? 16 : 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          "$calories kcal",
                          style: TextStyle(
                            fontSize: isMealCategory ? 14 : 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}