import 'package:flutter/material.dart';
import 'package:nutri_app/backend/controller/product_management_controller.dart';
import 'package:nutri_app/frontend/web/screens/product_detail_page.dart';
import 'package:nutri_app/frontend/web/screens/recipe_detail_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:nutri_app/backend/api/spoonacular_api_service.dart';
import 'package:nutri_app/backend/controller/recipe_management_controller.dart';

class RecipeManagementPage extends StatefulWidget {
  const RecipeManagementPage({super.key});

  @override
  RecipeManagementPageState createState() => RecipeManagementPageState();
}

class RecipeManagementPageState extends State<RecipeManagementPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  List<Map<String, dynamic>> allRecipes = [];
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredRecipes = [];
  List<Map<String, dynamic>> filteredProducts = [];
  late RecipeManagementController recipeController;
  late ProductManagementController productController;
  String searchQuery = "";
  String selectedStatus = "All";
  bool _isLoadingRecipes = false;
  bool _isLoadingProducts = false;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    recipeController = RecipeManagementController(supabase: Supabase.instance.client);
    productController = ProductManagementController(supabase: Supabase.instance.client);
    _fetchRecipes();
    _fetchProducts();
    _searchController.addListener(_filterItems);
  }

  void _fetchRecipes() async {
    setState(() {
      _isLoadingRecipes = true;
    });

    try {
      final recipes = await recipeController.fetchRecipes();
      setState(() {
        allRecipes = recipes;
        filteredRecipes = recipes;
      });
    } catch (e) {
      print("Error fetching recipes: $e");
    } finally {
      setState(() {
        _isLoadingRecipes = false;
      });
    }
  }

  void _fetchProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final products = await productController.fetchProducts();
      setState(() {
        allProducts = products;
        filteredProducts = products;
      });
    } catch (e) {
      print("Error fetching products: $e");
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  void _filterItems() {
    searchQuery = _searchController.text.toLowerCase();

    setState(() {
      filteredRecipes = allRecipes.where((recipe) {
        final matchesQuery = recipe['title'].toLowerCase().contains(searchQuery) ||
            recipe['submitter_name'].toLowerCase().contains(searchQuery);
        return matchesQuery;
      }).toList();

      filteredProducts = allProducts.where((product) {
        final name = product['name'] ?? '';
        final submitterName = product['submitter_name'] ?? '';
        return name.toLowerCase().contains(searchQuery) ||
            submitterName.toLowerCase().contains(searchQuery);
      }).toList();

    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 100 : 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Tabs for Recipes and Products
            TabBar(
              controller: _tabController,
              labelColor: Colors.green[800],
              unselectedLabelColor: Colors.black,
              indicatorColor: Colors.green[800],
              labelStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: "Recipes"),
                Tab(text: "Products"),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search for recipes or products",
                      prefixIcon: Icon(Icons.search, color: Colors.black54),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                    items: ["All", "Hidden", "Not hidden"]
                        .map((status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    ))
                        .toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            /// Tabs Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _isLoadingRecipes ? _buildLoadingIndicator() : _buildRecipeList(),
                  _isLoadingProducts ? _buildLoadingIndicator() : _buildProductList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeList() {
    if (filteredRecipes.isEmpty) {
      return const Center(
        child: Text(
          "No recipes found",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredRecipes.length,
      itemBuilder: (context, index) {
        final recipe = filteredRecipes[index];
        final isHidden = recipe['hidden'] ?? false;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeDetailPage(
                  recipe: recipe,
                  controller: recipeController,
                ),
              ),
            ).then((_) => _fetchRecipes());
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    recipe['image'] ?? 'https://via.placeholder.com/100',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe['title'] ?? 'Unknown Title',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text("Created by: ${recipe['submitter_name'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 14)),
                      Text("Date: ${recipe['created_at']?.split('T')[0] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                if (isHidden)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      "HIDDEN",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductList() {
    if (filteredProducts.isEmpty) {
      return const Center(
        child: Text(
          "No products found",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(
                  product: product,
                  controller: productController,
                ),
              ),
            ).then((_) => _fetchProducts());
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (product['image'] != null && product['image'].startsWith('http'))
                      ? Image.network(
                    product['image'] ?? 'https://via.placeholder.com/100',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                      : Image.asset(
                    product['image'] ?? 'assets/default_image.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'Unknown Product',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text("Created by: ${product['submitter_name'] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 14)),
                      Text("Date: ${product['created_at']?.split('T')[0] ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 14)),
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

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}