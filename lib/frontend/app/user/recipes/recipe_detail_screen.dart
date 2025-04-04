import 'package:flutter/material.dart';
import 'report_recipe_screen.dart';
import '../../../../services/spoonacular_api_service.dart';
import '../../../../backend/supabase/recipe_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  final bool isFromDatabase;
  final RecipeService? recipeService;
  final SpoonacularApiService? apiService;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.isFromDatabase = false,
    this.recipeService,
    this.apiService,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<Map<String, dynamic>> _recipeFuture;
  bool _isFavourite = false;
  List<Map<String, dynamic>> _comments = [];
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _recipeFuture = _loadRecipeDetails();
    _loadCommentsAndRatings();
  }

  Future<Map<String, dynamic>> _loadRecipeDetails() async {
    if (widget.isFromDatabase && widget.recipeService != null) {
      return await widget.recipeService!.getRecipe(widget.recipeId);
    } else if (widget.apiService != null) {
      return await widget.apiService!.fetchRecipeDetails(widget.recipeId);
    }
    return {};
  }

  Future<void> _loadCommentsAndRatings() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    
    final mockComments = [
      {'user': 'User1', 'comment': 'This recipe is amazing!', 'rating': 5},
      {'user': 'User2', 'comment': 'Easy to make and delicious', 'rating': 4},
    ];
    
    setState(() {
      _comments = mockComments;
      _averageRating = _calculateAverageRating(mockComments);
    });
  }

  double _calculateAverageRating(List<Map<String, dynamic>> comments) {
    if (comments.isEmpty) return 0.0;
    return comments.fold(0.0, (sum, comment) => sum + (comment['rating'] as num)) / comments.length;
  }

  void _toggleFavourite() {
    setState(() => _isFavourite = !_isFavourite);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavourite ? 'Added to favourites!' : 'Removed from favourites!'),
        ),
      );
    }
  }

  void _navigateToReportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportRecipeScreen(recipeId: widget.recipeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.report, color: Colors.red),
            onPressed: _navigateToReportScreen,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _recipeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Failed to load recipe details'));
          }
          
          final recipe = snapshot.data!;
          return _buildRecipeContent(recipe);
        },
      ),
    );
  }

  Widget _buildRecipeContent(Map<String, dynamic> recipe) {
    widget.isFromDatabase;
    
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRecipeImage(recipe),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(recipe),
                    const SizedBox(height: 16),
                    _buildNutritionInfoSection(recipe),
                    const SizedBox(height: 24),
                    _buildTimeSection(recipe),
                    const SizedBox(height: 24),
                    _buildIngredientsSection(recipe),
                    const SizedBox(height: 24),
                    _buildInstructionsSection(recipe),
                    const SizedBox(height: 24),
                    _buildReviewsSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildFloatingActionButton(),
      ],
    );
  }

  Widget _buildRecipeImage(Map<String, dynamic> recipe) {
    final imageUrl = widget.isFromDatabase
        ? recipe["image"] ?? "https://via.placeholder.com/150"
        : recipe["image"] ?? "https://via.placeholder.com/150";

    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.fastfood, size: 50, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(Map<String, dynamic> recipe) {
    final title = widget.isFromDatabase 
        ? recipe["name"] ?? "No Title"
        : recipe["title"] ?? recipe["name"] ?? "No Title";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (recipe["diets"] != null && (recipe["diets"] as List).isNotEmpty)
          _buildDietTags(recipe["diets"] as List),
      ],
    );
  }

  Widget _buildDietTags(List<dynamic> diets) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: diets.map<Widget>((diet) {
        return Chip(
          label: Text(
            diet.toString(),
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: Colors.green[50],
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  Widget _buildNutritionInfoSection(Map<String, dynamic> recipe) {
    final calories = widget.isFromDatabase
        ? recipe["calories"]?.toString() ?? "0"
        : recipe["calories"]?.toString() ?? "0";
    
    final protein = widget.isFromDatabase
        ? recipe["protein"]?.toStringAsFixed(1) ?? "0.0"
        : recipe["protein"]?.toStringAsFixed(1) ?? "0.0";
    
    final carbs = widget.isFromDatabase
        ? recipe["carbs"]?.toStringAsFixed(1) ?? "0.0"
        : recipe["carbs"]?.toStringAsFixed(1) ?? "0.0";
    
    final fats = widget.isFromDatabase
        ? recipe["fats"]?.toStringAsFixed(1) ?? "0.0"
        : recipe["fats"]?.toStringAsFixed(1) ?? "0.0";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NutritionInfoItem(label: 'Calories', value: '$calories kcal'),
        _NutritionInfoItem(label: 'Protein', value: '$protein g'),
        _NutritionInfoItem(label: 'Carbs', value: '$carbs g'),
        _NutritionInfoItem(label: 'Fats', value: '$fats g'),
      ],
    );
  }

  Widget _buildTimeSection(Map<String, dynamic> recipe) {
    final time = widget.isFromDatabase
        ? recipe["time"]?.toString() ?? "0"
        : recipe["time"]?.toString() ?? "0";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _InfoCard(icon: Icons.timer, text: '$time min'),
      ],
    );
  }

  Widget _buildIngredientsSection(Map<String, dynamic> recipe) {
  if (widget.isFromDatabase) {
    try {
      // Extract the ingredients list from the "items" field
      final ingredientsData = recipe["ingredients"] ?? {};
      final items = ingredientsData["items"] as List? ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Ingredients'),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text("No ingredients available.")
          else
            ...items.map((ingredient) {
              // Skip empty ingredients
              if ((ingredient['name'] == null || ingredient['name'] == '') &&
                  (ingredient['amount'] == null || ingredient['amount'] == '')) {
                return const SizedBox.shrink();
              }

              // Format as "amount unit name" (e.g. "100g pork")
              final amount = ingredient['amount']?.toString() ?? '';
              final unit = ingredient['unit']?.toString() ?? '';
              final name = ingredient['name']?.toString() ?? '';
              
              String ingredientText = '$amount$unit $name'.trim();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  "• $ingredientText",
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }).where((widget) => widget != const SizedBox.shrink()),
        ],
      );
    } catch (e) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Ingredients'),
          const SizedBox(height: 12),
          Text("Error displaying ingredients: ${e.toString()}"),
        ],
      );
    }
  } else {
    // Handle API recipes (original implementation)
    List<dynamic> ingredients = recipe["extendedIngredients"] ?? 
                              recipe["ingredients"] ?? 
                              ["No ingredients available"];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Ingredients'),
        const SizedBox(height: 12),
        if (ingredients.isEmpty)
          const Text("No ingredients available.")
        else
          ...ingredients.map((ingredient) {
            String ingredientText;
            
            if (ingredient is Map<String, dynamic>) {
              ingredientText = ingredient["original"]?.toString() ?? 
                            ingredient["name"]?.toString() ?? 
                            ingredient.toString();
            } else {
              ingredientText = ingredient.toString();
            }
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "• $ingredientText",
                style: const TextStyle(fontSize: 16),
              ),
            );
          }),
      ],
    );
  }
}


  Widget _buildInstructionsSection(Map<String, dynamic> recipe) {
    List<dynamic> instructions = [];
    
    if (widget.isFromDatabase) {
      instructions = recipe["instructions"] is Map
          ? (recipe["instructions"] as Map).values.toList()
          : recipe["instructions"] is List
              ? recipe["instructions"]
              : ["No instructions available"];
    } else {
      instructions = recipe["analyzedInstructions"]?[0]["steps"] ?? 
                   recipe["instructions"] ?? 
                   ["No instructions available"];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Instructions'),
        const SizedBox(height: 12),
        if (instructions.isEmpty)
          const Text("No instructions available.")
        else if (instructions.first is Map)
          ...instructions.map((step) => _buildInstructionStep(step))
        else
          ...instructions.map((instruction) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text("• $instruction"),
          )),
        
        if (recipe["sourceName"]?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Source:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe["sourceName"]!,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInstructionStep(Map<String, dynamic> step) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Step ${step["number"] ?? ""}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(step["step"] ?? step.toString()),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Community Reviews'),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 30),
            const SizedBox(width: 10),
            Text(
              _averageRating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 5),
            Text(
              '(${_comments.length} reviews)',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_comments.isEmpty)
          const Text("No reviews yet. Be the first to review!")
        else
          ..._comments.map((comment) => _CommentCard(comment: comment)),
        const SizedBox(height: 16),
        _buildReviewInputField(),
      ],
    );
  }

  Widget _buildReviewInputField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Add your review...',
        suffixIcon: IconButton(
          icon: const Icon(Icons.send),
          onPressed: () {},
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: ElevatedButton(
        onPressed: _toggleFavourite,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFavourite ? Colors.red : Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          _isFavourite ? 'Remove from Favourites' : 'Add to Favourites',
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }
}

class _NutritionInfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _NutritionInfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoCard({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final Map<String, dynamic> comment;

  const _CommentCard({
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  comment['user'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Row(
                  children: List.generate(5, (index) => Icon(
                    Icons.star,
                    size: 16,
                    color: index < comment['rating'] ? Colors.amber : Colors.grey,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment['comment']),
          ],
        ),
      ),
    );
  }
}