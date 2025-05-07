import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../backend/entities/recipes.dart';
import '../../../../backend/entities/nutrition.dart';
import '../../../../backend/controllers/biz_recipe_list_controller.dart';
import '../../../../backend/controllers/recipe_list_controller.dart';
import '../user/recipes/view_recipe_detail_screen.dart';


class BizPartnerDashboard extends StatefulWidget {
  const BizPartnerDashboard({super.key});

  @override
  State<BizPartnerDashboard> createState() => _BizPartnerDashboardState();
}

class _BizPartnerDashboardState extends State<BizPartnerDashboard> {
  bool _isInitializing = true;
  int _selectedIndex = 0;
  String _searchQuery = '';
  String? _userType; // 'business' or 'nutritionist'

  @override
  void initState() {
    super.initState();
    _loadUserTypeAndData();
  }

  Future<void> _loadUserTypeAndData() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId != null) {
      // load account type
      final acc = await client
          .from('accounts')
          .select('type')
          .eq('uid', userId)
          .single();
      setState(() {
        _userType = (acc)['type'] as String;
      });

      // load business recipes
      if (mounted){
        final bizCtrl = context.read<BusinessRecipeListController>();
        await bizCtrl.loadUserRecipes();
      }
    }
    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  Widget _buildRecipeItem(Recipes recipe) {
    return Consumer<RecipeListController>(
      builder: (context, listController, child) {
        final favoriteCount = listController.getFavoriteCount(recipe.id);
        final averageRating = listController.getAverageRating(recipe.id);
        final ratingCount = listController.getRatingCount(recipe.id);
        final hasRatings = listController.hasRatings(recipe.id);
        return GestureDetector(
          onTap: () async {
            final updated = await Navigator.of(context).push<Recipes>(
              MaterialPageRoute(
                builder: (_) => ViewRecipeDetailScreen(recipe: recipe),
              ),
            );
            if (!mounted) return;
            if (updated != null && context.mounted) {
              final bizCtrl = context.read<BusinessRecipeListController>();
              bizCtrl.loadUserRecipes();
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12), topRight: Radius.circular(12),
                    ),
                  ),
                  child: recipe.image != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12), topRight: Radius.circular(12),
                          ),
                          child: Image.network(recipe.image!, fit: BoxFit.cover),
                        )
                      : const Center(
                          child: Icon(Icons.fastfood, size: 50, color: Colors.grey),
                        ),
                ),
                Padding(
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
                                fontSize: 18, fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                hasRatings
                                    ? '${averageRating.toStringAsFixed(1)} ($ratingCount)'
                                    : '0.0 (0)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: hasRatings ? Colors.black : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.favorite, size: 16, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(
                                favoriteCount.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: favoriteCount > 0 ? Colors.black : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildNutritionFact(
                            icon: Icons.local_fire_department,
                            value: recipe.nutrition?.nutrients
                                    .firstWhere(
                                      (n) => n.title.toLowerCase() == 'calories',
                                      orElse: () => Nutrient(title: 'Calories', amount: 0, unit: 'kcal'),
                                    )
                                    .amount
                                    .toStringAsFixed(0) ??
                                '0',
                            unit: 'kcal',
                          ),
                          _buildNutritionFact(
                            icon: Icons.people,
                            value: recipe.servings?.toString() ?? '?',
                            unit: 'servings',
                          ),
                          _buildNutritionFact(
                            icon: Icons.timer,
                            value: recipe.readyInMinutes?.toString() ?? '?',
                            unit: 'mins',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Recipes',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.green),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/add_recipe');
              if (result is Recipes && context.mounted) {
                // we just created/updated one—refresh the biz list
                context.read<BusinessRecipeListController>().loadUserRecipes();
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: Consumer<BusinessRecipeListController>(
        builder: (context, ctrl, child) {
          if (ctrl.isLoading) return const Center(child: CircularProgressIndicator());
          if (ctrl.error != null) return Center(child: Text('Error: ${ctrl.error}'));

          final filtered = ctrl.recipes.where((r) =>
            r.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isEmpty ? 'No recipes found' : 'No recipes match "$_searchQuery"',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildRecipeItem(filtered[index]),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  /// Picks the right tabs based on whether this is a business or nutritionist user
  Widget _buildBottomNavBar(BuildContext context) {
    final isBiz = _userType == 'business';
    // Choose nav items based on account type
    final items = isBiz
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Recipes'),
            BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Products'),
            BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ]
        : const [
            BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Recipes'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ];

    // Define route names in main.dart
    final routes = isBiz
        ? ['/biz_recipes', '/biz_products', '/biz_orders', '/biz_profile']
        : ['/biz_recipes', '/nutri_profile'];

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      onTap: (i) {
        if (i == _selectedIndex) return;
        setState(() => _selectedIndex = i);
        Navigator.pushReplacementNamed(context, routes[i]);
      },
      items: items,
    );
  }


  Widget _buildNutritionFact({required IconData icon, required String value, required String unit}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.green),
        const SizedBox(height: 4),
        Text(
          '$value $unit',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
