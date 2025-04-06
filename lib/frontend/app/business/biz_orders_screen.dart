import 'package:flutter/material.dart';
import 'biz_partner_dashboard.dart';
import 'biz_products_screen.dart';
import 'biz_profile_screen.dart';
import 'biz_order_detail.dart';

class BizOrdersScreen extends StatefulWidget {
  const BizOrdersScreen({super.key});

  @override
  BizOrdersScreenState createState() => BizOrdersScreenState();
}

class BizOrdersScreenState extends State<BizOrdersScreen> {
  static final List<Map<String, dynamic>> _orderHistory = [

  ];

  static void addNewOrder(Map<String, dynamic> order) {
    if (!_orderHistory.any((o) => o["orderId"] == order["orderId"])) {
      _orderHistory.insert(0, order);
    }
  }

  List<Map<String, dynamic>> filteredOrders = [];
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterOrders);
    filteredOrders = List.from(_orderHistory);
  }

  void _filterOrders() {
    setState(() {
      String query = _searchController.text.toLowerCase();
      filteredOrders = _orderHistory.where((order) {
        return order["orderId"].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      switch (index) {
        case 0:
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const BizPartnerDashboard()));
          break;
        case 1:
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const BizProductsScreen()));
          break;
        case 2:
          break;
        case 3:
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const BizProfileScreen()));
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle new order passed via Navigator.pushNamed or push
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newOrder = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (newOrder != null && !_orderHistory.any((o) => o["orderId"] == newOrder["orderId"])) {
        setState(() {
          _orderHistory.insert(0, newOrder);
          filteredOrders = List.from(_orderHistory);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for Orders",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 10),

            /// 📦 Order List
            Expanded(
              child: filteredOrders.isEmpty
                  ? const Center(child: Text("No orders found."))
                  : ListView.builder(
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(order: order),
                        ),
                      ).then((_) {
                        setState(() {}); // Refresh after returning from detail screen
                      });
                    },
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    order["orderId"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (order["isNew"])
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "New",
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("Customer Name: ${order["customer"]}"),
                            Text("Order Date: ${order["date"]}"),
                            Text("Product(s) Ordered: ${order["products"]}"),
                            Text("Order Status: ${order["status"]}"),
                            Text("Total Amount: ${order["total"]}"),
                            Text("Payment Status: ${order["payment"]}"),
                            Text("Delivery Address: ${order["delivery"]}"),
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
      ),

      ///Bottom Nav
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
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