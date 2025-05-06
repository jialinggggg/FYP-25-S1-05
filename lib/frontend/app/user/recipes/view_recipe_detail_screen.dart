import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:nutri_app/backend/controllers/view_recipe_detail_controller.dart';
import 'package:nutri_app/backend/entities/recipes.dart';
import 'package:nutri_app/backend/entities/nutrition.dart';
import 'package:nutri_app/backend/entities/recipe_rating.dart';
import 'package:nutri_app/frontend/app/user/recipes/edit_recipe_screen.dart';
import 'package:nutri_app/frontend/app/user/recipes/report_recipe_screen.dart';

class ViewRecipeDetailScreen extends StatefulWidget {
  final Recipes recipe;
  
  const ViewRecipeDetailScreen({super.key, required this.recipe});

  @override
  State<ViewRecipeDetailScreen> createState() => _ViewRecipeDetailScreenState();
}

class _ViewRecipeDetailScreenState extends State<ViewRecipeDetailScreen> {
  late final SupabaseClient _supabase;
  late ViewRecipeDetailController _controller;
  late Recipes _currentRecipe;
  final TextEditingController _reviewController = TextEditingController();
  double _userRating = 0;

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe;
    _supabase = Supabase.instance.client;
    _initializeController();
  }

  void _initializeController() {
    _controller = ViewRecipeDetailController(_supabase, _currentRecipe,);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<ViewRecipeDetailController>(
        builder: (context, controller, _) {
          // 1) While loading, just show a blank Scaffold + spinner:
          if (controller.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 2) If there was an error loading, show your error UI:
          if (controller.error != null) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(controller.error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3) Otherwise loading is done and no error—render your real screen:
          return WillPopScope(
            onWillPop: () async {
              Navigator.pop(context, _currentRecipe);
              return false;
            },
            child: Scaffold(
              appBar: _buildAppBar(),
              body: Stack(
                children: [
                  _buildBody(),
                  if (!controller.isOwner)
                    Positioned(
                      left: 16, right: 16, bottom: 16,
                      child: _buildFavoriteButton(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  AppBar _buildAppBar() {
    return AppBar(
      title: Consumer<ViewRecipeDetailController>(
        builder: (context, controller, _) {
          final recipe = _currentRecipe;
          return Text(
            recipe.title,
            style: const TextStyle(fontSize: 18),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      actions: [
        Consumer<ViewRecipeDetailController>(
          builder: (context, controller, _) {
            if (!controller.isOwner) {
              return IconButton(
                icon: const Icon(Icons.report, color: Colors.red),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportRecipeScreen(recipe: _currentRecipe),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        Consumer<ViewRecipeDetailController>(
          builder: (context, controller, _) {
            if (!controller.isOwner) return SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updated = await Navigator.of(context).push<Recipes>(
                  MaterialPageRoute(
                    builder: (_) => EditRecipeScreen(recipeId: _currentRecipe.id),
                  ),
                );
                if (updated != null) {
                  setState(() {
                    _currentRecipe = updated;
                    _initializeController(); // rewire controller if needed
                  });
                }
              },
            );
          },
        )
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<ViewRecipeDetailController>(
      builder: (context, controller, _) {
        if (controller.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(controller.error!),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ],
            ),
          );
        }

        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final recipe = _currentRecipe;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRecipeImage(recipe),
              _buildRecipeHeader(recipe),
              _buildNutritionSection(recipe),
              _buildIngredientsSection(recipe),
              _buildInstructionsSection(recipe),
              _buildCommunityReviewsSection(),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecipeImage(Recipes recipe) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: recipe.image != null
          ? Image.network(
              recipe.image!,
              fit: BoxFit.cover,
            )
          : const Center(
              child: Icon(Icons.fastfood, size: 50, color: Colors.grey),
            ),
    );
  }

  Widget _buildRecipeHeader(Recipes recipe) {
    final sourceInfo = _getSourceInfo(recipe);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recipe.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sourceInfo.color.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sourceInfo.color),
                ),
                child: Text(
                  sourceInfo.text,
                  style: TextStyle(
                    color: sourceInfo.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<ViewRecipeDetailController>(
            builder: (context, controller, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatsItem(
                    icon: Icons.favorite,
                    value: controller.favoriteCount.toString(),
                    label: 'favorites',
                  ),
                  _buildStatsItem(
                    icon: Icons.people,
                    value: recipe.servings?.toString() ?? '?',
                    label: 'servings',
                  ),
                  _buildStatsItem(
                    icon: Icons.timer,
                    value: recipe.readyInMinutes?.toString() ?? '?',
                    label: 'mins',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (recipe.diets?.isNotEmpty ?? false)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: recipe.diets!
                  .map((diet) => Chip(
                        label: Text(diet),
                        labelStyle: const TextStyle(fontSize: 12),
                        backgroundColor: Colors.green[50],
                        side: BorderSide(color: Colors.green[100]!),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(Recipes recipe) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutrition Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Nutrition Information (per serving)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNutritionSummaryItem('Calories', 
                      _getNutrientValue(recipe, ['calorie'], 'kcal')),
                    _buildNutritionSummaryItem('Protein', 
                      _getNutrientValue(recipe, ['protein'], 'g')),
                    _buildNutritionSummaryItem('Carbs', 
                      _getNutrientValue(recipe, ['carbohydrate', 'carb'], 'g')),
                    _buildNutritionSummaryItem('Fat', 
                      _getNutrientValue(recipe, ['fat'], 'g')),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                ..._buildDetailedNutritionFacts(recipe),
                const SizedBox(height: 8),
                Text(
                 'Based on ${recipe.servings} ${recipe.servings == 1 ? 'serving' : 'servings'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(Recipes recipe) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingredients',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...recipe.extendedIngredients
                  ?.map((ingredient) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 4, right: 8),
                              child: Icon(Icons.circle, size: 8),
                            ),
                            Expanded(
                              child: Text(
                                '${ingredient.amount} ${ingredient.unit} ${ingredient.name}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList() ??
              [const Text('No ingredients listed')],
        ],
      ),
    );
  }

  Widget _buildInstructionsSection(Recipes recipe) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...recipe.analyzedInstructions
                  ?.expand((instruction) => instruction.steps
                      .map((step) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${step.number}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    step.step,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          )))
                  .toList() ??
              [const Text('No instructions available')],
        ],
      ),
    );
  }

  Widget _buildCommunityReviewsSection() {
    return Consumer<ViewRecipeDetailController>(
      builder: (context, controller, _) {
        final isOwner = controller.isOwner;
        final hasRated = controller.hasRated;  // Track if the user has rated

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Average Rating Section
              Row(
                children: [
                  const Text(
                    'Average Rating: ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${controller.averageRating.toStringAsFixed(1)} (${controller.ratingCount})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reviews Title
              const Text(
                'Community Reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Reviews List
              if (controller.reviews.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No reviews yet. Be the first to review!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else
                ...controller.reviews.map((review) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildReviewCard(review, controller),
                )),

              // Add Review Section (only for non-owners and if the user hasn't rated yet)
              if (!isOwner && !hasRated) ...[
                const SizedBox(height: 10),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How would you rate this recipe?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: RatingBar.builder(
                            initialRating: _userRating,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: false,
                            itemCount: 5,
                            itemSize: 36,
                            itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                            itemBuilder: (context, _) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            onRatingUpdate: (rating) {
                              setState(() {
                                _userRating = rating;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _reviewController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Tell others what you think about this recipe...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () async {
                              if (_userRating == 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a rating'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              
                              try {
                                await controller.submitReview(
                                  rating: _userRating.round(),
                                  comment: _reviewController.text,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Thanks for your review!'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _reviewController.clear();
                                setState(() => _userRating = 0);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error submitting review: ${e.toString()}'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.send, color: Colors.white),
                            label: const Text(
                              'Submit Review',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }


  Widget _buildReviewCard(RecipeRating review, ViewRecipeDetailController controller) {

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(review.uid.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'User ${review.uid.substring(0, 6)}...',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_controller.isOwner) 
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                '(You)',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                RatingBarIndicator(
                  rating: review.rating.toDouble(),
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 20,
                  direction: Axis.horizontal,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (review.comment.isNotEmpty)
              Text(review.comment),
            if (!_controller.isOwner) 
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _editReview(review, controller),
                      child: const Text('Edit'),
                    ),
                    TextButton(
                      onPressed: () => _deleteReview(review, controller),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editReview(RecipeRating review, ViewRecipeDetailController controller) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReviewDialog(
        initialRating: review.rating.toDouble(),
        initialComment: review.comment,
      ),
    );

    if (!mounted) return;
    
    if (result != null) {
      try {
        await controller.updateReview(
          ratingId: review.ratingId,
          rating: result['rating'] as int,
          comment: result['comment'] as String,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating review: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteReview(RecipeRating review, ViewRecipeDetailController controller) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (shouldDelete == true) {
      try {
        await controller.deleteReview(review.ratingId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting review: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildFavoriteButton() {
    return Consumer<ViewRecipeDetailController>(
      builder: (context, controller, _) {
        if (controller.isOwner) return const SizedBox.shrink();
        
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: controller.isFavourite ? Colors.red : Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () async {
            try {
              await controller.toggleFavourite();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                controller.isFavourite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                controller.isFavourite 
                    ? 'Remove from Favorites' 
                    : 'Add to Favorites',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.green),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDetailedNutritionFacts(Recipes recipe) {
    final nutrientGroups = [
      {
        'nutrients': [
          {'display': 'Saturated Fat', 'keys': ['saturated fat'], 'unit': 'g'},
          {'display': 'Cholesterol', 'keys': ['cholesterol'], 'unit': 'mg'},
          {'display': 'Sodium', 'keys': ['sodium'], 'unit': 'mg'},
          {'display': 'Dietary Fiber', 'keys': ['fiber', 'dietary fiber'], 'unit': 'g'},
          {'display': 'Total Sugars', 'keys': ['sugar', 'total sugars'], 'unit': 'g'},
          {'display': 'Vitamin D', 'keys': ['vitamin d'], 'unit': 'mcg'},
          {'display': 'Calcium', 'keys': ['calcium'], 'unit': 'mg'},
          {'display': 'Iron', 'keys': ['iron'], 'unit': 'mg'},
          {'display': 'Potassium', 'keys': ['potassium'], 'unit': 'mg'},
          {'display': 'Vitamin A', 'keys': ['vitamin a'], 'unit': 'mcg'},
          {'display': 'Vitamin C', 'keys': ['vitamin c'], 'unit': 'mg'},
        ],
      },
    ];

    return nutrientGroups.expand((group) {
      return [
        ...(group['nutrients'] as List).map((nutrient) {
          final display = nutrient['display'] as String;
          final keys = (nutrient['keys'] as List).cast<String>();
          final unit = nutrient['unit'] as String;
          
          final value = _getNutrientValue(recipe, keys, unit);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    display,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    value.isNotEmpty ? value : '--',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ];
    }).toList();
  }

  String _getNutrientValue(Recipes recipe, List<String> keys, String defaultUnit) {
    final nutrient = recipe.nutrition?.nutrients.firstWhere(
      (n) => keys.any((key) => n.title.toLowerCase().contains(key)),
      orElse: () => Nutrient(title: '', amount: 0, unit: defaultUnit),
    );
    
    final amount = nutrient?.amount ?? 0;
    final unit = nutrient?.unit ?? defaultUnit;
    
    return amount > 0 
      ? '${amount.toStringAsFixed(1)} $unit'
      : '';
  }

  ({String text, Color color}) _getSourceInfo(Recipes recipe) {
    String sourceType = recipe.sourceType?.toLowerCase() ?? 'unknown'; // Default to 'unknown' if sourceType is null

    switch (sourceType) {
      case 'user':
        return (text: 'Community', color: Colors.green);
      case 'business':
        return (text: 'Business', color: Colors.blue);
      case 'nutritionist':
        return (text: 'Nutritionist', color: Colors.purple);
      case 'spoonacular':
        return (text: 'Spoonacular', color: Colors.orange);
      default:
        return (text: 'Unknown', color: Colors.grey);
    }
  }

}

class ReviewDialog extends StatefulWidget {
  final double initialRating;
  final String initialComment;

  const ReviewDialog({
    super.key,
    required this.initialRating,
    required this.initialComment,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  late double _rating;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _commentController = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemSize: 32,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _rating = rating;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Edit your review...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, {
            'rating': _rating.round(),
            'comment': _commentController.text,
          }),
          child: const Text('Save'),
        ),
      ],
    );
  }
}