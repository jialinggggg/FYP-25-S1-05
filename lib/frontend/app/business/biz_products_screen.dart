import 'dart:io';
import 'package:flutter/material.dart';
import 'biz_partner_dashboard.dart';
import 'biz_profile_screen.dart';
import 'biz_orders_screen.dart';
import 'add_product.dart';
import 'biz_product_details.dart';

class BizProductsScreen extends StatefulWidget {
  const BizProductsScreen({super.key});

  static List<Map<String, dynamic>> staticProductList = [];

  @override
  BizProductsScreenState createState() => BizProductsScreenState();
}

class BizProductsScreenState extends State<BizProductsScreen> {
  List<Map<String, dynamic>> products = [
    {
      "name": "Chicken Patty Meal",
      "description": "A hearty Chicken Patty Meal served with a vibrant green salad and drizzled with a rich, creamy homemade mushroom sauce, offering a perfect balance of flavors and nutrition.",
      "price": "S\$10.00",
      "category": "Meal",
      "stock": "100",
      "status": "Available",
      "image": "assets/grilled_chicken_salad.png"
    },
    {
      "name": "Green Juice",
      "description": "A refreshing blend of leafy greens, crisp fruits, and zesty citrus, packed with vitamins and nutrients to energize your day.",
      "price": "S\$10.00",
      "category": "Meal",
      "stock": "100",
      "status": "Available",
      "image": "assets/green_juice.png"
    },
  ];

  List<Map<String, dynamic>> filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 1; //Default index for "Products" tab

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);

    //Load from staticProductList if not emptyfonDelete:
    if (BizProductsScreen.staticProductList.isNotEmpty) {
      products = List.from(BizProductsScreen.staticProductList);
    }

    filteredProducts = List.from(products); // Initialize filtered list
  }

  /// **🔎 Filter Products Based on Search Input**
  void _filterProducts() {
    setState(() {
      String query = _searchController.text.toLowerCase();
      filteredProducts = products.where((product) {
        return product["name"].toLowerCase().contains(query);
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
      setState(() {
        products.add(newProduct);
        filteredProducts = List.from(products); //Update filtered list
        BizProductsScreen.staticProductList = List.from(products);
      });
    }
  }

  /// ** Bottom Navigation Logic**
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
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BizOrdersScreen()));
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
      /// **App Bar**
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

      /// Body Content
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for products",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 10),

            /// **My Products List**
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
                            product["image"] != "assets/default_img.png" &&
                            File(product["image"]).existsSync())
                            ? Image.file(File(product["image"]), fit: BoxFit.cover)
                            : Image.asset("assets/default_img.png", fit: BoxFit.cover),
                      ),
                      title: Text(
                        product["name"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product["description"], maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text("Price: ${product["price"]}"),
                          Text("Category: ${product["category"]}"),
                          Text("Stock Quantity: ${product["stock"]}"),
                          Text("Status: ${product["status"]}"),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.green),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BizProductDetailsScreen(
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
                                  BizProductsScreen.staticProductList = List.from(products); //update static list
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

      ///Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Recipes"),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: "Products"),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}