import 'package:flutter/material.dart';
import 'biz_partner_dashboard.dart';
import 'biz_profile_screen.dart';
import 'biz_orders_screen.dart';
import 'biz_product_details.dart';
import 'add_product.dart';
import '../../../backend/services/product_service.dart'; // Import the backend service

class BizProductsScreen extends StatefulWidget {
  const BizProductsScreen({super.key});

  static List<Map<String, dynamic>> staticProductList = [];

  @override
  BizProductsScreenState createState() => BizProductsScreenState();
}

class BizProductsScreenState extends State<BizProductsScreen> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 1; // Default index for "Products" tab

  @override
  void initState() {
    super.initState();
    _loadProducts(); // Load products from Supabase on initialization
    _searchController.addListener(_filterProducts);
  }

  /// **🔎 Filter Products Based on Search Input**
  void _filterProducts() {
    setState(() {
      String query = _searchController.text.toLowerCase();
      filteredProducts = products.where((product) {
        return product["name"].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  /// **➕ Navigate to Add Product Screen & Receive New Product**
  void _navigateToAddProduct() async {
    final newProduct = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );

    if (newProduct != null) {
      try {
        // Insert new product using the service
        await ProductService.insertProduct(newProduct);
        _loadProducts(); // Reload products after insertion
      } catch (error) {
        // Handle any errors or notify the user
        print("Error inserting product: $error");
      }
    }
  }

  /// **Fetch Products from Supabase using the service**
  void _loadProducts() async {
    final loadedProducts = await ProductService.loadProducts();
    setState(() {
      products = loadedProducts;
      filteredProducts = List.from(products);
      BizProductsScreen.staticProductList = List.from(products);
    });
  }

  /// **Bottom Navigation Logic**
  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });

      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BizPartnerDashboard()),
          );
          break;
        case 1:
          break; // Stay on Products screen
        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BizOrdersScreen()),
          );
          break;
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BizProfileScreen()),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Products",
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
            onPressed: _navigateToAddProduct, // Navigate to Add Product
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for products",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your Added Products",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            products.isEmpty
                ? const Center(
                    child: Text(
                      "No added products yet!",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: SizedBox(
                              width: 50,
                              height: 50,
                              child: (product["image"] != null &&
                                      product["image"].toString().isNotEmpty &&
                                      product["image"].toString() !=
                                          "assets/default_image.png")
                                  ? Image.network(
                                      product["image"].toString(),
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      "assets/default_image.png",
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            title: Text(
                              product["name"].toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product["description"].toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text("Price: ${product["price"]}"),
                                Text(
                                    "Category: ${product["category"].toString()}"),
                                Text("Stock Quantity: ${product["stock"]}"),
                                Text("Status: ${product["status"].toString()}"),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.green),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BizProductDetailsScreen(
                                    product: product,
                                    onUpdate: (updatedProduct) {
                                      setState(() {
                                        products[index] = updatedProduct;
                                        filteredProducts = List.from(products);
                                      });
                                    },
                                    onDelete: () {
                                      setState(() {
                                        products.removeAt(index);
                                        filteredProducts = List.from(products);
                                        BizProductsScreen.staticProductList =
                                            List.from(products);
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant), label: "Recipes"),
          BottomNavigationBarItem(
              icon: Icon(Icons.storefront), label: "Products"),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping), label: "Orders"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
