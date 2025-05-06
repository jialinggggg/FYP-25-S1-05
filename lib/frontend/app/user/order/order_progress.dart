import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:nutri_app/frontend/app/shared/order_store.dart'; // Make sure this path is correct

class UserOrdersProgressScreen extends StatefulWidget {
  const UserOrdersProgressScreen({super.key});

  @override
  State<UserOrdersProgressScreen> createState() => _UserOrdersProgressScreenState();
}

class _UserOrdersProgressScreenState extends State<UserOrdersProgressScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  StreamSubscription? _supabaseSubscription;
  StreamSubscription? _storeSubscription;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  @override
  void dispose() {
    _supabaseSubscription?.cancel();
    _storeSubscription?.cancel();
    super.dispose();
  }

  void _setupListeners() {
    // Listen to Supabase real-time changes
    _supabaseSubscription = _supabase
      .from('orders')
      .stream(primaryKey: ['order_id'])
      .order('date', ascending: false)
      .listen(_handleOrderUpdate);

    // Listen to local store updates
    _storeSubscription = SharedOrderStore.onOrderUpdated.listen((updatedOrder) {
      _handleOrderUpdate([updatedOrder]);
    });

    // Initial data fetch
    _fetchOrders();
  }

  void _handleOrderUpdate(List<Map<String, dynamic>> updatedOrders) {
    if (!mounted) return;

    setState(() {
      for (final updatedOrder in updatedOrders) {
        final orderId = updatedOrder['order_id'] ?? updatedOrder['orderId'];
        final existingIndex = _orders.indexWhere(
          (o) => (o['order_id'] ?? o['orderId']) == orderId
        );

        if (existingIndex >= 0) {
          _orders[existingIndex] = updatedOrder;
        } else {
          _orders.add(updatedOrder);
        }
      }
      _isLoading = false;
    });
  }

  Future<void> _fetchOrders() async {
    try {
      // First try to get orders from local store
      final localOrders = SharedOrderStore.userOrders;
      if (localOrders.isNotEmpty) {
        _handleOrderUpdate(localOrders);
      }

      // Then fetch from Supabase to ensure we have latest
      final response = await _supabase
        .from('orders')
        .select()
        .order('date', ascending: false);

      _handleOrderUpdate(List<Map<String, dynamic>>.from(response));
      
      // Update local store with fresh data
      for (final order in response) {
        SharedOrderStore.addOrUpdateUserOrder(order);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching orders: $e')),
        );
        // Fallback to local store if Supabase fails
        _handleOrderUpdate(SharedOrderStore.userOrders);
      }
    }
  }

  List<Map<String, dynamic>> _generateSteps(Map<String, dynamic> order) {
    // Prefer steps from order if available, otherwise generate
    if (order['steps'] != null && order['steps'] is List) {
      return List<Map<String, dynamic>>.from(order['steps']);
    }

    const steps = ["Confirmed", "Preparing", "Out for Delivery", "Delivered"];
    final status = order['status']?.toString() ?? 'Confirmed';
    final currentIndex = steps.indexOf(status);
    
    return steps.map((step) => {
      'title': step,
      'done': steps.indexOf(step) <= currentIndex,
      'status': step,
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Progress"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              child: _orders.isEmpty
                  ? const Center(
                      child: Text(
                        "No orders found",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final steps = _generateSteps(order);

                        return Card(
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Order #${order['order_id'] ?? order['orderId']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      "\$${order['total']?.toStringAsFixed(2) ?? '0.00'}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Placed on ${_formatDate(order['date'])}",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  order['products']?.toString() ?? 'No products',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                const Text(
                                  "ORDER STATUS",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...steps.map<Widget>((step) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Icon(
                                          step["done"] ?? false
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: step["done"] ?? false
                                              ? Colors.green
                                              : Colors.grey,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          step["title"] ?? "Unknown",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: step["done"] ?? false
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      final dateTime = date is String 
          ? DateTime.parse(date).toLocal()
          : (date is DateTime ? date.toLocal() : DateTime.now());
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (e) {
      return "Unknown date";
    }
  }
}