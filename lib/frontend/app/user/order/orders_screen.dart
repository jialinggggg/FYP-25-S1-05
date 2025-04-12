import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutri_app/backend/services/product_service.dart';
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
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  Map<String, int> cart = {};
  bool _hasItemsInCart = false;
  bool _showCheckIcon = false;

  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    try {
      final allProducts = await ProductService.loadAllAvailableProducts();
      if (mounted) {
        setState(() {
          products = List<Map<String, dynamic>>.from(allProducts);
          filteredProducts = List.from(products);
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch products: $e");
    }
  }

  void _onSearchChanged() {
    setState(() {
      String query = _searchController.text.toLowerCase().trim();
      if (query.isEmpty) {
        filteredProducts = List.from(products);
        return;
      }

      filteredProducts = products.where((product) {
        String name = product["name"]?.toString().toLowerCase() ?? "";
        return name.contains(query);
      }).toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RecipesScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLogScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
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

  void _openProductDetails(Map<String, dynamic> product) {
    if (product["stock"] > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(
            product: product,
            onAddToCart: _addToCart,
            isInCart: cart.containsKey(product["name"]),
          ),
        ),
      ).then((_) {
        if (mounted) setState(() {});
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This product is out of stock!")),
      );
    }
  }

  void _addToCart(String productName) {
    setState(() {
      cart[productName] = (cart[productName] ?? 0) + 1;
      _hasItemsInCart = true;
      _showCheckIcon = true;
    });

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _showCheckIcon = false;
        });
      }
    });
  }

  void _openCartScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartScreen(),
      ),
    );

    if (!mounted) return;

    if (result != null && result is Map<String, dynamic>) {
      if (result["order"] != null) {
        BizOrdersScreenState.addNewOrder(result["order"]);
        SharedOrderStore.addOrUpdateUserOrder(result["order"]);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order placed successfully!")),
        );

        setState(() {
          cart.clear();
          _hasItemsInCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Products",
          style: TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold),
        ),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for products",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Text("No products found!",
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return GestureDetector(
                        onTap: () => _openProductDetails(product),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: SizedBox(
                              width: 50,
                              height: 50,
                              child: Image.network(
                                product["image"]?.toString() ?? "",
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported),
                              ),
                            ),
                            title: Text(
                              product["name"]?.toString() ?? "",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product["description"]?.toString() ?? "",
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text("Price: \$${(product["price"] ?? 0).toStringAsFixed(2)}"),
                                if (product["stock"] == 0)
                                  const Text(
                                    "Out of Stock",
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold),
                                  ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _openCartScreen,
        child: _showCheckIcon
            ? const Icon(Icons.check_circle, color: Colors.white, size: 28)
            : const Icon(Icons.shopping_bag, color: Colors.white, size: 28),
      ),
    );
  }
}
