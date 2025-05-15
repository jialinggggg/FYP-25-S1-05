import 'package:flutter/material.dart';
import 'package:nutri_app/backend/services/cart_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'checkout.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCartItems();
    });
  }

  Future<void> _fetchCartItems() async {
    try {
      setState(() => _isLoading = true);
      final items = await CartService.getCartItems();

      debugPrint('[CART] Fetched ${items.length} items');
      if (items.isNotEmpty) {
        debugPrint('[CART] First item: ${items.first}');
      }

      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading cart: ${e.toString()}")),
      );
    }
  }

  Future<void> _resetCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Cart"),
        content: const Text("Are you sure you want to clear your entire cart?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("RESET", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('carts').delete().eq('user_id', userId);

      setState(() {
        _cartItems = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart has been reset")),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to reset cart: ${e.toString()}")),
      );
    }
  }

  ImageProvider _resolveImageProvider(String imagePath) {
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    } else if (imagePath.startsWith('/')) {
      return FileImage(File(imagePath));
    } else {
      return NetworkImage(_supabase.storage
          .from('product-image')
          .getPublicUrl(imagePath));
    }
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final product = item['products'] as Map<String, dynamic>? ?? {};
    final name = product['name']?.toString() ?? 'Unnamed Product';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = (item['quantity'] as int?) ?? 1;
    final cartItemId = item['id']?.toString() ?? '';
    final imagePath = product['image']?.toString();

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.grey[200],
          backgroundImage:
              imagePath != null ? _resolveImageProvider(imagePath) : null,
          child: imagePath == null ? const Icon(Icons.shopping_cart) : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('\$${price.toStringAsFixed(2)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.red),
              onPressed: () => _updateQuantity(cartItemId, quantity - 1),
            ),
            Text('$quantity', style: const TextStyle(fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.green),
              onPressed: () => _updateQuantity(cartItemId, quantity + 1),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateQuantity(String cartItemId, int newQuantity) async {
    try {
      if (newQuantity < 1) {
        await CartService.removeFromCart(cartItemId);
      } else {
        await CartService.updateCartItemQuantity(
          cartItemId: cartItemId,
          newQuantity: newQuantity,
        );
      }
      await _fetchCartItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: ${e.toString()}")),
      );
    }
  }

  double _calculateTotal() {
    return _cartItems.fold(0, (total, item) {
      final quantity = (item['quantity'] as int?) ?? 0;
      final price =
          ((item['products'] as Map)['price'] as num?)?.toDouble() ?? 0.0;
      return total + (quantity * price);
    });
  }

  Future<void> _handleCheckout() async {
    try {
      setState(() => _isLoading = true);

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('User not authenticated');
      }

      final Map<String, int> simplifiedCart = {
        for (var item in _cartItems)
          item['products']['name']: item['quantity'] as int,
      };

      final response = await http.post(
        Uri.parse(
            'https://mmyzsijycjxdkxglrxxl.supabase.co/functions/v1/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({'amount': (_calculateTotal() * 100).toInt()}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create payment intent: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final clientSecret = data['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'NutriApp',
          style: ThemeMode.light,
          customFlow: false,
        ),
      );

      try {
        await Stripe.instance.presentPaymentSheet();
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutScreen(
              cart: simplifiedCart,
              orderId: "O${DateTime.now().millisecondsSinceEpoch}",
              totalAmount: _calculateTotal(),
            ),
          ),
        );
      } on StripeException catch (e) {
        throw Exception('Payment failed: ${e.error.localizedMessage}');
      } catch (e) {
        throw Exception('Payment failed: $e');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during checkout: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCartItems,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _cartItems.isEmpty ? null : _resetCart,
            tooltip: 'Reset Cart',
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _fetchCartItems,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _cartItems.isEmpty
                ? const Center(child: Text("Your cart is empty"))
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) =>
                              _buildCartItem(_cartItems[index]),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("TOTAL:",
                                    style: TextStyle(fontSize: 18)),
                                Text(
                                  "\$${_calculateTotal().toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    onPressed: _resetCart,
                                    child: const Text("RESET CART"),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    onPressed: _handleCheckout,
                                    child: const Text(
                                      "CHECKOUT",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
