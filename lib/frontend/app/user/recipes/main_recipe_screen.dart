import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../backend/controllers/recipe_filter_controller.dart';
import '../../../../backend/controllers/recipe_list_controller.dart';
import '../../../../backend/controllers/recipe_search_controller.dart';
import '../../../../../backend/entities/recipes.dart';
import '../../../../../backend/entities/nutrition.dart';
import '../../../../../backend/api/spoonacular_service.dart';
import 'view_recipe_detail_screen.dart';

class MainRecipeScreen extends StatefulWidget {
  const MainRecipeScreen({super.key});

  @override
  State<MainRecipeScreen> createState() => _MainRecipeScreenState();
}

class _MainRecipeScreenState extends State<MainRecipeScreen> {
  late final SupabaseClient _supabase;
  late final RecipeListController _listController;
  late final RecipeSearchController _searchController;
  late final RecipeFilterController _filterController;
  final TextEditingController _searchTextController = TextEditingController();
  bool _isInitializing = true;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final int _localRecipesPerLoad = 6;
  final int _spoonacularRecipesPerLoad = 4;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _initializeControllers() async {
    final spoonacularService = Provider.of<SpoonacularService>(context, listen: false);
    _listController = RecipeListController(_supabase, spoonacularService);
    _searchController = RecipeSearchController(_supabase, spoonacularService);
    _filterController = RecipeFilterController(_supabase, spoonacularService);
    
    await _loadInitialRecipes();
    _searchTextController.addListener(_handleSearchTextChanged);

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  bool _shouldShowLoadMore() {
  return _listController.hasMore && 
         !_searchController.isSearching && 
         !_filterController.isFilterApplied &&
         !_listController.isLoading;
}

  Future<void> _loadInitialRecipes() async {
    await _listController.loadInitialRecipes(
      localLimit: _localRecipesPerLoad,
      spoonacularLimit: _spoonacularRecipesPerLoad,
    );
  }

  Future<void> _loadMoreRecipes() async {
    await _listController.loadMoreRecipes(
      localLimit: _localRecipesPerLoad,
      spoonacularLimit: _spoonacularRecipesPerLoad,
    );
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      if (_listController.hasMore && !_listController.isLoading && 
          !_searchController.isSearching && !_filterController.isFilterApplied) {
        _loadMoreRecipes();
      }
    }
  }

  void _handleSearchTextChanged() async {
    final query = _searchTextController.text.trim();
    _searchController.setSearchQuery(query);
    
    if (query.isEmpty) {
      // Only load initial recipes if we're not in filter mode
      if (!_filterController.isFilterApplied) {
        await _loadInitialRecipes();
      }
    } else {
      // Perform search and prevent overwriting by other operations
      await _searchController.searchRecipes(query);
    }
  }

  void _clearSearch() {
    _searchTextController.clear();
    _searchController.clearSearch();
    
    // Only load initial recipes if we're not in filter mode
    if (!_filterController.isFilterApplied) {
      _loadInitialRecipes();
    }
  }

  List<Recipes> _getDisplayedRecipes() {
    // Priority 1: Search results
    if (_searchController.searchQuery.isNotEmpty) {
      return _searchController.searchResults;
    }
    // Priority 2: Filtered results
    else if (_filterController.isFilterApplied) {
      return _filterController.filteredRecipes;
    }
    // Default: Regular recipe list
    else {
      return _listController.recipes;
    }
  }

  String? _getErrorMessage() {
    return _listController.error ?? 
           _searchController.error ?? 
           _filterController.error;
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filter Recipes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterOption(
                    context,
                    icon: Icons.create,
                    label: 'My Recipes',
                    filterType: RecipeFilterType.custom,
                    isSelected: _filterController.activeFilter == RecipeFilterType.custom,
                    onTap: () {
                      setModalState(() {
                        _filterController.setFilter(RecipeFilterType.custom, 'My Recipes');
                      });
                    },
                  ),
                  _buildFilterOption(
                    context,
                    icon: Icons.favorite,
                    label: 'Favorites',
                    filterType: RecipeFilterType.favourite,
                    isSelected: _filterController.activeFilter == RecipeFilterType.favourite,
                    onTap: () {
                      setModalState(() {
                        _filterController.setFilter(RecipeFilterType.favourite, 'Favorites');
                      });
                    },
                  ),
                  _buildFilterOption(
                    context,
                    icon: Icons.star,
                    label: 'Rated by Me',
                    filterType: RecipeFilterType.rated,
                    isSelected: _filterController.activeFilter == RecipeFilterType.rated,
                    onTap: () {
                      setModalState(() {
                        _filterController.setFilter(RecipeFilterType.rated, 'Rated by Me');
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _filterController.clearFilter();
                          Navigator.pop(context); // Close the bottom sheet immediately
                          _loadInitialRecipes();
                        },
                        child: const Text('Clear'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: _isLoading
                            ? null // Disable the button while loading
                            : () async {
                                // Close the bottom sheet immediately
                                Navigator.pop(context);

                                // Show loading indicator on the main screen
                                setState(() {
                                  _isLoading = true;
                                });

                                // Apply the filter and fetch filtered recipes
                                if (_filterController.activeFilter != null) {
                                  await _filterController.applyFilter(_filterController.activeFilter!);
                                }

                                // After loading is done, hide the loading indicator
                                setState(() {
                                  _isLoading = false;
                                });
                              },
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : const Text('Apply Filter', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchFilterIndicator() {
    return Consumer2<RecipeSearchController, RecipeFilterController>(
      builder: (context, searchController, filterController, child) {
        // Search indicator
        if (searchController.searchQuery.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text('Searched by: ${searchController.searchQuery}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.grey,)),
                const Spacer(),
                TextButton(
                  onPressed: _clearSearch,
                  child: const Text('Clear', style: TextStyle(color: Colors.green, decoration: TextDecoration.underline,)),
                ),
              ],
            ),
          );
        }
        // Filter indicator
        else if (filterController.isFilterApplied && filterController.activeFilter != null) {
          String label;
          switch (filterController.activeFilter!) {
            case RecipeFilterType.custom:
              label = 'My Recipes';
              break;
            case RecipeFilterType.favourite:
              label = 'Favorites';
              break;
            case RecipeFilterType.rated:
              label = 'Rated by Me';
              break;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text('Filtered by: $label',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.grey,)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    filterController.clearFilter();
                    _loadInitialRecipes();
                  },
                  child: const Text('Clear', style: TextStyle(color: Colors.green, decoration: TextDecoration.underline,)),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFilterOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required RecipeFilterType filterType,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSearchBar() {
    return Consumer<RecipeSearchController>(
      builder: (context, searchController, child) {
        return TextField(
          controller: _searchTextController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchTextController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
            hintText: "Search recipes...",
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          ),
          onSubmitted: (value) {
            final query = value.trim();
            _searchController.setSearchQuery(query);
            _searchController.searchRecipes(query);
          },
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Consumer<RecipeListController>(
      builder: (context, listController, child) {
        if (_searchController.isSearching || _filterController.isFilterApplied) {
          return const SizedBox.shrink();
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: ElevatedButton(
              onPressed: listController.isLoading ? null : _loadMoreRecipes,
              child: listController.isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load More Recipes'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipeItem(Recipes recipe) {
    // Determine source type display text and color
    String sourceText;
    Color sourceColor;
    bool showEatwellBanner = false;

    switch (recipe.sourceType?.toLowerCase()) {
      case 'user':
        sourceText = 'Community';
        sourceColor = Colors.green;
        showEatwellBanner = true;
        break;
      case 'business':
        sourceText = 'Business Partner';
        sourceColor = Colors.blue;
        showEatwellBanner = true;
        break;
      case 'nutritionist':
        sourceText = 'Nutritionist';
        sourceColor = Colors.purple;
        showEatwellBanner = true;
        break;
      case 'spoonacular':
        sourceText = 'Spoonacular';
        sourceColor = Colors.orange;
        showEatwellBanner = false;
        break;
      default:
        sourceText = 'Unknown';
        sourceColor = Colors.grey;
        showEatwellBanner = false;
    }

    return Consumer<RecipeListController>(
      builder: (context, listController, child) {
        final favoriteCount = listController.getFavoriteCount(recipe.id);
        final averageRating = listController.getAverageRating(recipe.id);
        final ratingCount = listController.getRatingCount(recipe.id);
        final hasRatings = listController.hasRatings(recipe.id);


        return GestureDetector(
          onTap: () async {
            final updated = await Navigator.of(context).push<Recipes>(
              MaterialPageRoute(builder: (_) => ViewRecipeDetailScreen(recipe: recipe)),
            );
            if (updated != null) {
              setState(() {
                final idx = _listController.recipes.indexWhere((r) => r.id == updated.id);
                if (idx != -1) {
                  _listController.recipes[idx] = updated;
                }
              });
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showEatwellBanner)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[400],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Only on EatWell',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                Container(
                  height: 180,
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
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                          Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.star, 
                                                  size: 16, 
                                                  color: Colors.amber),
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
                                              ],
                                            ),
                                          ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.favorite,
                                              size: 16,
                                              color: Colors.red,
                                            ),
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
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: sourceColor.withAlpha(10),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: sourceColor),
                            ),
                            child: Text(
                              sourceText,
                              style: TextStyle(
                                color: sourceColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                                      orElse: () => Nutrient(
                                        title: 'Calories',
                                        amount: 0,
                                        unit: 'kcal',
                                      ),
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
                      const SizedBox(height: 12),
                      
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
                      
                      if (recipe.dishTypes?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: recipe.dishTypes!
                                .map((type) => Chip(
                                      label: Text(type),
                                      labelStyle: const TextStyle(fontSize: 12),
                                      backgroundColor: Colors.blue[50],
                                      side: BorderSide(color: Colors.blue[100]!),
                                      visualDensity: VisualDensity.compact,
                                    ))
                                .toList(),
                          ),
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

  Widget _buildNutritionFact({
    required IconData icon,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.green),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 1, // Main Log is the active tab
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey[600],
      onTap: (index) {
        if (index == 1) return;
        Navigator.pushNamed(context, ['/orders', '/main_recipes', '/log', '/dashboard', '/profile'][index]);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Orders",),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Recipes",),
        BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Journal",),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard",),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile",),
      ],
    );
  }

  @override
  void dispose() {
    _searchTextController.removeListener(_handleSearchTextChanged);
    _searchTextController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _listController),
        ChangeNotifierProvider.value(value: _searchController),
        ChangeNotifierProvider.value(value: _filterController),
      ],
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "Recipes",
            style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt, color: Colors.green),
              onPressed: () => _showFilterBottomSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.green),
              onPressed: () => Navigator.pushNamed(context, '/add_recipe'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 8),
              _buildSearchFilterIndicator(),  // <-- Indicator inserted here
              
              // Loading and list content
              if (_isLoading)
                Expanded(
                  child: Center(
                    child: const CircularProgressIndicator(),
                  ),
                )
              else
                Expanded(
                  child: Consumer3<RecipeListController, RecipeSearchController, RecipeFilterController>(
                    builder: (context, listController, searchController, filterController, child) {
                      final displayedRecipes = _getDisplayedRecipes();
                      final errorMessage = _getErrorMessage();

                      if (errorMessage != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error: $errorMessage'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadInitialRecipes,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (displayedRecipes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                searchController.isSearching
                                  ? 'No recipes found for your search'
                                  : filterController.isFilterApplied
                                    ? 'No recipes match your filter'
                                    : 'No recipes available',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              if (searchController.isSearching || filterController.isFilterApplied)
                                ElevatedButton(
                                  onPressed: () {
                                    if (searchController.isSearching) {
                                      _clearSearch();
                                    } else {
                                      filterController.clearFilter();
                                      _loadInitialRecipes();
                                    }
                                  },
                                  child: const Text('Show Random Recipes'),
                                ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: displayedRecipes.length + (_shouldShowLoadMore() ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == displayedRecipes.length) {
                            return _buildLoadMoreButton();
                          }
                          final recipe = displayedRecipes[index];
                          return _buildRecipeItem(recipe);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }
}