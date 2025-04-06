import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../report/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../recipes/recipes_screen.dart';
import '../meal/main_log_screen.dart';
import 'cart_screen.dart';
import 'product_details.dart';
import '../../business/biz_orders_screen.dart';
import 'order_progress.dart';
import '../../shared/order_store.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  OrdersScreenState createState() => OrdersScreenState();
}

class OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> products = [
    {
      "name": "Chicken Patty Meal",
      "description": "A hearty Chicken Patty Meal served with a vibrant green salad and drizzled with a rich, creamy homemade mushroom sauce.",
      "price": 10.00,
      "category": "Meal",
      "image": "assets/grilled_chicken_salad.png",
    },
    {
      "name": "Green Juice",
      "description": "A refreshing blend of leafy greens, crisp fruits, and zesty citrus, packed with vitamins and nutrients.",
      "price": 5.00,
      "category": "Juice",
      "image": "assets/green_juice.png",
    },
  ];

  Map<String, int> cart = {}; // Cart to store selected items
  int cartItemCount = 0; // Number of items in the cart

  /// Navigation Index
  int _selectedIndex = 0; // Orders is the current page

  /// Navigation Logic
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });


    switch (index) {
      case 0: // Orders (stay here)
        break;
      case 1: // Recipes
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RecipesScreen()),
        );
        break;
      case 2: // Log
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLogScreen()),
        );
        break;
      case 3: // Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainReportDashboard()),
        );
        break;
      case 4: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  void _openProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          product: product,
          onAddToCart: _addToCart,
        ),
      ),
    );
  }

  /// Add Product to Cart
  void _addToCart(String productName) {
    setState(() {
      if (cart.containsKey(productName)) {
        cart[productName] = cart[productName]! + 1;
      } else {
        cart[productName] = 1;
      }
      cartItemCount++;
    });
  }

  void _updateCartCount() {
    cartItemCount = cart.values.fold(0, (sum, quantity) => sum + quantity);
  }

  /// Open Cart Screen
  void _openCartScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartScreen(cart: Map.from(cart))),
    );

    if (!mounted) return;

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        // Update cart (empty after checkout)
        cart = result["cart"] ?? {};
        _updateCartCount();
      });

      if (result["order"] != null) {
        // Add order statically to BizOrdersScreen
        BizOrdersScreenState.addNewOrder(result["order"]);
        SharedOrderStore.addOrUpdateUserOrder(result["order"]);
        SharedOrderStore.addOrUpdateUserOrder(result["order"]);

        //  show a toast or SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order placed successfully!")),
        );
      }
    }
  }

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(products); // Initialize filtered list
    _searchController.addListener(_onSearchChanged); // Listen for changes
  }

  void _onSearchChanged() {
    setState(() {
      String query = _searchController.text.toLowerCase().trim();


      // Prevent errors if the search query is empty
      if (query.isEmpty) {
        filteredProducts = List.from(products);
        return;
      }

      filteredProducts = products.where((product) {
        //Ensure product name is valid before calling `.toLowerCase()`
        String name = product["name"]?.toLowerCase() ?? "";
        return name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Products", style: TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.track_changes),
            tooltip: 'My Order Progress',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserOrdersProgressScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          /// Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _onSearchChanged(),
              decoration: InputDecoration(
                hintText: "Search for products",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),


          /// **Product List**
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
              child: Text("No products found!", style: TextStyle(fontSize: 16, color: Colors.grey)),
            )
                : ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return GestureDetector(
                  onTap: () => _openProductDetails(product),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.asset(product["image"], fit: BoxFit.cover),
                      ),
                      title: Text(product["name"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product["description"], maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text("Price: \$${product["price"].toStringAsFixed(2)}"),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),


      ///Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_rounded), label: "Recipes"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.list_bullet_below_rectangle), label: "Logs"),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),

      /// **🛒 Floating Cart Button**
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _openCartScreen,
        child: Stack(
          children: [
            const Icon(Icons.shopping_bag, color: Colors.white, size: 28),
            if (cartItemCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text(cartItemCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}