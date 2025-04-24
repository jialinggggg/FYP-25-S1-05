import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserOrdersProgressScreen extends StatefulWidget {
  const UserOrdersProgressScreen({super.key});

  @override
  State<UserOrdersProgressScreen> createState() => _UserOrdersProgressScreenState();
}

class _UserOrdersProgressScreenState extends State<UserOrdersProgressScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final response = await _supabase.from('orders').select().order('date', ascending: false);
    setState(() {
      _orders = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _generateSteps(String status) {
    return [
      {"title": "Order Confirmed", "done": true},
      {"title": "Preparing Order", "done": status != "Confirmed"},
      {"title": "Out for Delivery", "done": status == "Out for Delivery" || status == "Delivered"},
      {"title": "Delivered", "done": status == "Delivered"},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Progress"),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final steps = _generateSteps(order["status"]);

                return Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Order ID: ${order["order_id"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Date: ${DateTime.parse(order["date"]).toLocal().toString().split(' ')[0]}"),
                        Text("Product(s): ${order["products"]}"),
                        const SizedBox(height: 10),
                        const Text("Progress:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...steps.map<Widget>((step) {
                          return Row(
                            children: [
                              Icon(
                                step["done"] ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: step["done"] ? Colors.green : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(step["title"] ?? "Untitled Step"),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
