import 'package:flutter/material.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(String) onAddToCart;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  ProductDetailsScreenState createState() => ProductDetailsScreenState();
}

class ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1; // Default quantity

  /// **Increase Quantity**
  void _increaseQuantity() {
    setState(() {
      quantity++;
    });
  }

  /// **Decrease Quantity (Min 1)**
  void _decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  /// **Add to Cart Function**
  void _addToCart() {
    for (int i = 0; i < quantity; i++) {
      widget.onAddToCart(widget.product["name"]);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${widget.product["name"]} added to cart!")),
    );

    Navigator.pop(context); // Go back after adding
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// **App Bar**
      appBar: AppBar(
        title: const Text("Products", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      /// **Body - Product Details**
      body: Column(
        children: [
          /// **🖼 Product Image**
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.product["image"]),
                fit: BoxFit.cover,
              ),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          /// **📜 Product Info**
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// **📝 Product Name**
                  Text(
                    widget.product["name"],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  /// **🔥 Cooking Information (Calories, Time, Difficulty)**
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoIcon(Icons.local_fire_department, "420 kcal"),
                      _infoIcon(Icons.access_time, "10 minutes"),
                      _infoIcon(Icons.restaurant, "Easy"),
                    ],
                  ),
                  const SizedBox(height: 10),

                  /// **📖 Description**
                  Text(
                    widget.product["description"],
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),

                  /// **🛒 Ingredients Section**
                  const Text(
                    "Ingredients",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),

                  /// **📝 Ingredients List (Example, can be expanded)**
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("• 300g Organic Chicken Patty"),
                      Text("• 300g Broccoli with Garlic"),
                      Text("• Organic Brown Sauce"),
                    ],
                  ),
                  const SizedBox(height: 20),

                  /// **➕ Quantity Selector**
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 30),
                        onPressed: _decreaseQuantity,
                      ),
                      Container(
                        width: 50,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[300],
                        ),
                        child: Text(
                          quantity.toString(),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 30),
                        onPressed: _increaseQuantity,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /// **🛒 "Add to Cart" Button**
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
              ),
              child: const Text("Add to Cart", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  /// **🔥 Cooking Information Icon**
  Widget _infoIcon(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.green),
        const SizedBox(height: 5),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}