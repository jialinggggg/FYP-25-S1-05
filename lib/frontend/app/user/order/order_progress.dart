import 'package:flutter/material.dart';
import '../../shared/order_store.dart';

class UserOrdersProgressScreen extends StatefulWidget {
  const UserOrdersProgressScreen({super.key});

  @override
  State<UserOrdersProgressScreen> createState() => _UserOrdersProgressScreenState();
}

class _UserOrdersProgressScreenState extends State<UserOrdersProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final userOrders = SharedOrderStore.userOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Progress"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: userOrders.length,
        itemBuilder: (context, index) {
          final order = userOrders[index];
          final steps = order["steps"] ?? [];
          return Card(
            margin: const EdgeInsets.all(12),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Order ID: ${order["orderId"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("Date: ${order["date"]}"),
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