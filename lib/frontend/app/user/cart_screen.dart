import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  final Map<String, int> cart; // Cart items (Product name -> Quantity)

  const CartScreen({super.key, required this.cart});

  @override
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  final Map<String, double> productPrices = {
    "Chicken Patty Meal": 10.00,
    "Green Juice": 5.00,
  };

  /// **Increase Quantity**
  void _increaseQuantity(String productName) {
    setState(() {
      widget.cart[productName] = (widget.cart[productName] ?? 0) + 1;
    });
    Navigator.pop(context, widget.cart);
  }

  void _decreaseQuantity(String productName) {
    setState(() {
      if (widget.cart[productName]! > 1) {
        widget.cart[productName] = widget.cart[productName]! - 1;
      } else {
        widget.cart.remove(productName);
      }
    });
    Navigator.pop(context, widget.cart);
  }

  /// **Calculate Total Price**
  double _calculateTotal() {
    double total = 0;
    widget.cart.forEach((product, quantity) {
      total += (productPrices[product] ?? 0) * quantity;
    });
    return total;
  }

  /// **Proceed to Checkout**
  void _checkout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Checkout feature coming soon!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// **App Bar**
      appBar: AppBar(
        title: const Text("Your Cart", style: TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),

      /// **Body - List of Cart Items**
      body: widget.cart.isEmpty
          ? const Center(
        child: Text(
          "Your cart is empty!",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.cart.length,
              itemBuilder: (context, index) {
                String productName = widget.cart.keys.elementAt(index);
                int quantity = widget.cart[productName] ?? 1;
                double price = productPrices[productName] ?? 0;
                return _buildCartItem(productName, quantity, price);
              },
            ),
          ),

          /// **Total Price & Checkout Button**
          _buildBottomBar(),
        ],
      ),
    );
  }

  /// **🛍 Cart Item Tile**
  Widget _buildCartItem(String productName, int quantity, double price) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          productName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Price: \$${price.toStringAsFixed(2)}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 30),
              onPressed: () => _decreaseQuantity(productName),
            ),
            Text("$quantity", style: const TextStyle(fontSize: 18)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 30),
              onPressed: () => _increaseQuantity(productName),
            ),
          ],
        ),
      ),
    );
  }

  /// **💰 Bottom Bar: Total Price & Checkout Button**
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        children: [
          /// **Total Price**
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text("\$${_calculateTotal().toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 10),

          /// **Checkout Button**
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _checkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Proceed to Checkout", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}