import 'package:flutter/material.dart';
import 'package:nutri_app/backend/services/cart_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(String) onAddToCart;
  final bool isInCart;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
    this.isInCart = false,
  });

  @override
  ProductDetailsScreenState createState() => ProductDetailsScreenState();
}

class ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;
  bool _isAdding = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _showSuccess = widget.isInCart;
  }

  void _increaseQuantity() {
    setState(() => quantity++);
  }

  void _decreaseQuantity() {
    if (quantity > 1) setState(() => quantity--);
  }

  Future<void> _addToCart() async {
    if (_isAdding || _showSuccess) return;

    setState(() => _isAdding = true);

    try {
      await CartService.addToCart(
        productId: widget.product["id"].toString(),
        quantity: quantity,
      );

      widget.onAddToCart(widget.product["name"]);

      if (!mounted) return;
      setState(() => _showSuccess = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${widget.product["name"]} added to cart!")),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _showReportDialog(BuildContext context) {
    final TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Report Product"),
          content: TextField(
            controller: reportController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "Describe the issue (e.g. scam, misleading info...)",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Submit"),
              onPressed: () async {
                final message = reportController.text.trim();
                if (message.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _submitReport(message);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitReport(String message) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be logged in to report.")),
        );
        return;
      }

      await Supabase.instance.client.from('product_report').insert({
        'product_id': widget.product["id"],
        'user_id': user.id,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thank you for your report!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit report: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 250,
            child: Image.network(
              widget.product["image"],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported, size: 100),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product["name"] ?? "",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Price: \$${(widget.product["price"] ?? 0).toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18, color: Colors.green),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.product["description"] ?? "",
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Add Quantity",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => _showReportDialog(context),
                      child: const Text(
                        "Report this Product",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _showSuccess ? null : _addToCart,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (_showSuccess) return Colors.green;
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.green.withOpacity(0.5);
                    }
                    return Colors.green;
                  },
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
              ),
              child: _isAdding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : _showSuccess
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, color: Colors.white),
                            SizedBox(width: 8),
                            Text("Added to Cart",
                                style: TextStyle(color: Colors.white)),
                          ],
                        )
                      : const Text(
                          "Add to Cart",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
