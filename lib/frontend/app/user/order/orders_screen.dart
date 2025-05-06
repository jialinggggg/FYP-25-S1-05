import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutri_app/backend/services/product_service.dart';
import '../report/main_report_screen.dart';
import '../profile/profile_screen.dart';
import '../recipes/main_recipe_screen.dart';
import '../meal/main_log_screen.dart';
import 'cart_screen.dart';
import 'product_details.dart';
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
  bool _showCheckIcon = false;
  final _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    final list = await ProductService.loadAllAvailableProducts();
    if (!mounted) return;
    setState(() {
      products = list;
      filteredProducts = List.from(list);
    });
  }

  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      filteredProducts = q.isEmpty
        ? List.from(products)
        : products.where((p) {
            return p['name']
                    ?.toString()
                    .toLowerCase()
                    .contains(q) ==
                true;
          }).toList();
    });
  }

  void _openProductDetails(Map<String, dynamic> product) {
  if (product['stock'] > 0) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          product: product,
          onAddToCart: _addToCart,
          isInCart: cart.containsKey(product['name']),
        ),
      ),
    ).then((_) {
      // Always refresh products when returning from details screen
      _fetchProducts();
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
      _showCheckIcon = true;
    });
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showCheckIcon = false);
    });
  }

  void _onItemTapped(int idx) {
    setState(() => _selectedIndex = idx);
    switch (idx) {
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainRecipeScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLogScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainReportScreen()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
    }
  }

  void _openCartScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
    if (!mounted) return;
    if (result is Map<String, dynamic> && result['order'] != null) {
      SharedOrderStore.addOrUpdateUserOrder(result['order']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully!")),
      );
      setState(() => cart.clear());
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Products",
          style: TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.track_changes),
            tooltip: 'My Order Progress',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const UserOrdersProgressScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
                    child: Text("No products found!", style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (_, i) {
                      final p = filteredProducts[i];
                      return GestureDetector(
                        onTap: () => _openProductDetails(p),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 3,
                          child: ListTile(
                            leading: SizedBox(
                              width: 50, height: 50,
                              child: Image.network(p['image'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported)),
                            ),
                            title: Text(p['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['description'] ?? '',
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text("Price: \$${(p['price'] ?? 0).toStringAsFixed(2)}"),
                                if (p['stock'] == 0)
                                  const Text("Out of Stock",
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black54,
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
            ? const Icon(Icons.check_circle, size: 28, color: Colors.white)
            : const Icon(Icons.shopping_bag, size: 28, color: Colors.white),
      ),
    );
  }
}
