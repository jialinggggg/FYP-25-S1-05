import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../meal/main_log_screen.dart';
import 'add_recipe.dart';
import '../order/orders_screen.dart';
import 'favourites_screen.dart';
import 'my_recipes.dart';
import '../profile/profile_screen.dart';
import '../../../../services/spoonacular_api_service.dart';
import '../report/dashboard_screen.dart';
import 'category_recipes_screen.dart';
import '../../../../backend/supabase/recipe_service.dart';
import '../../../../backend/supabase/accounts_service.dart';
import '../../../../backend/supabase/user_profiles_service.dart';
import '../../../../backend/supabase/business_profiles_service.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  RecipesScreenState createState() => RecipesScreenState();
}

class RecipesScreenState extends State<RecipesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SpoonacularApiService _apiService = SpoonacularApiService();
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 1;
  int _initialTab = 0;
  late RecipeService _recipeService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize RecipeService
    final supabase = Supabase.instance.client;
    final accountService = AccountService(supabase);
    final userProfilesService = UserProfilesService(supabase);
    final businessProfilesService = BusinessProfilesService(supabase);
    _recipeService = RecipeService(
      supabase,
      accountService,
      userProfilesService,
      businessProfilesService,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['initialTab'] != null) {
      _initialTab = args['initialTab'];
      _tabController.index = _initialTab;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddRecipe() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
    );
  }

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

  void _navigateToCategoryScreen(String category, [String? title]) async {
    if (category == "community" || category == "business-partner" || category == "nutritionist") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryRecipesScreen(
            category: category,
            title: title ?? category,
            isFromDatabase: true,
            recipeService: _recipeService,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryRecipesScreen(
            category: category,
            title: title ?? category,
            apiService: _apiService,
          ),
        ),
      );
    }
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
          style: TextStyle(
            color: Colors.green,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.black, size: 28),
            onPressed: _navigateToAddRecipe,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for recipes...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.green,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.green,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
              tabs: const [
                Tab(text: "Discover"),
                Tab(text: "Favorites"),
                Tab(text: "My Recipes"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoverTab(),
                const FavouritesScreen(),
                const MyRecipesScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
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

  Widget _buildDiscoverTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Special"),
          const SizedBox(height: 12),
          _buildButtonRow([
            _buildCategoryButton(Icons.medical_services, "By Nutritionist", 
              () => _navigateToCategoryScreen("nutritionist", "By Nutritionist")),
            _buildCategoryButton(Icons.business, "By Business", 
              () => _navigateToCategoryScreen("business-partner", "By Business Partner")),
            _buildCategoryButton(Icons.people, "Community", 
              () => _navigateToCategoryScreen("community", "By Community")),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle("Pick Your Meal"),
          const SizedBox(height: 12),
          _buildButtonRow([
            _buildCategoryButton(Icons.breakfast_dining, "Breakfast", 
              () => _navigateToCategoryScreen("breakfast")),
            _buildCategoryButton(Icons.lunch_dining, "Lunch", 
              () => _navigateToCategoryScreen("lunch")),
          ]),
          const SizedBox(height: 12),
          _buildButtonRow([
            _buildCategoryButton(Icons.dinner_dining, "Dinner", 
              () => _navigateToCategoryScreen("dinner")),
            _buildCategoryButton(Icons.local_cafe, "Snacks", 
              () => _navigateToCategoryScreen("snack")),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle("Calorie Counters"),
          const SizedBox(height: 12),
          _buildButtonRow([
            _buildCategoryButton(Icons.local_fire_department, "50-100 kcal", 
              () => _navigateToCategoryScreen("50-100")),
            _buildCategoryButton(Icons.local_fire_department, "100-200 kcal", 
              () => _navigateToCategoryScreen("100-200")),
            _buildCategoryButton(Icons.local_fire_department, "200-300 kcal", 
              () => _navigateToCategoryScreen("200-300")),
          ]),
          const SizedBox(height: 12),
          _buildButtonRow([
            _buildCategoryButton(Icons.local_fire_department, "300-400 kcal", 
              () => _navigateToCategoryScreen("300-400")),
            _buildCategoryButton(Icons.local_fire_department, "400-500 kcal", 
              () => _navigateToCategoryScreen("400-500")),
            _buildCategoryButton(Icons.local_fire_department, "500+ kcal", 
              () => _navigateToCategoryScreen("500+")),
          ]),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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

  Widget _buildButtonRow(List<Widget> buttons) {
    return Row(
      children: buttons,
    );
  }

  Widget _buildCategoryButton(IconData icon, String text, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.green.withOpacity(0.3), width: 1),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 6),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}