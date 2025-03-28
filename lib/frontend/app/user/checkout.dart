import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, int> cart;

  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String selectedPayment = 'PayNow'; // Default selected payment method

  double calculateTotal() {
    double total = 0;
    widget.cart.forEach((productName, quantity) {
      if (productName == "Chicken Patty Meal") {
        total += 10.0 * quantity;
      } else if (productName == "Green Juice") {
        total += 5.0 * quantity;
      }
    });
    return total;
  }

  void _handleCheckout() {
    if (selectedPayment == 'PayNow') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Scan to Pay with PayNow"),
          content: Image.asset(
            "assets/paynow_qr.png",
            height: 200,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Payment successful via PayNow!")),
                );
                Navigator.pop(context, 'checkout_complete'); // Go back to previous screen
              },
              child: const Text("Done"),
            ),
          ],
        ),
      );
    } else if (selectedPayment == 'PayPal') {
      // Simulate PayPal checkout
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Redirecting to PayPal...")),
      );

      // Simulate delay and success
      Future.delayed(const Duration(seconds: 2), () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment successful via PayPal!")),
        );
        Navigator.pop(context, 'checkout_complete');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Order Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...widget.cart.entries.map((entry) => Text("• ${entry.key} x${entry.value}")),
            const SizedBox(height: 20),
            Text("Total: \$${totalPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 30),

            /// 🔘 Payment Method Selection
            const Text("Choose Payment Method:", style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile(
              title: const Text("PayNow"),
              value: 'PayNow',
              groupValue: selectedPayment,
              onChanged: (value) {
                setState(() {
                  selectedPayment = value.toString();
                });
              },
            ),
            RadioListTile(
              title: const Text("PayPal"),
              value: 'PayPal',
              groupValue: selectedPayment,
              onChanged: (value) {
                setState(() {
                  selectedPayment = value.toString();
                });
              },
            ),

            const Spacer(),

            /// ✅ Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Confirm & Pay", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}