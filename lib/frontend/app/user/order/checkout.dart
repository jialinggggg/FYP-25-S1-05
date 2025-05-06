import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum PaymentMethod { paynow, stripe }

class CheckoutScreen extends StatefulWidget {
  final Map<String, int> cart;
  final String orderId;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.cart,
    required this.orderId,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  PaymentMethod selectedPayment = PaymentMethod.paynow;
  bool _isProcessing = false;
  bool _paymentInProgress = false;
  final Map<String, int> _lockedCart = {};

  @override
  void initState() {
    super.initState();
    _lockedCart.addAll(widget.cart);
  }

  double calculateTotal() => widget.totalAmount;

  Future<void> _processPayNowPayment() async {
    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Scan to Pay with PayNow"),
          content: Image.asset("assets/paynow_qr.png", height: 200),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Payment successful via PayNow!")),
                );
                _completeOrder();
              },
              child: const Text("Done"),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processStripePayment() async {
    if (!mounted || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _paymentInProgress = true;
    });

    try {
      final session = _supabase.auth.currentSession;
      if (session == null) throw Exception('User not authenticated');

      final response = await http.post(
        Uri.parse('https://mmyzsijycjxdkxglrxxl.supabase.co/functions/v1/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'amount': (calculateTotal() * 100).toInt(),
          'currency': 'usd',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create payment intent: ${response.body}');
      }

      final paymentIntent = jsonDecode(response.body);
      final clientSecret = paymentIntent['clientSecret'];
      final customerId = paymentIntent['customer'];
      final ephemeralKey = paymentIntent['ephemeralKey'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Your Store',
          customerId: customerId,
          customerEphemeralKeySecret: ephemeralKey,
          style: ThemeMode.system,
          customFlow: false,
          allowsDelayedPaymentMethods: true,
        ),
      );

      try {
        await Stripe.instance.presentPaymentSheet();
        if (mounted) await _completeOrder();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment not completed")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _paymentInProgress = false;
        });
      }
    }
  }

  Future<void> _completeOrder() async {
  if (!mounted) return;
  setState(() => _isProcessing = true);

  try {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated")),
      );
      return;
    }

    // Retrieve product details from Supabase to extract seller_id
    final List<Map<String, dynamic>> productDetails = [];

    for (final entry in _lockedCart.entries) {
      final productResponse = await _supabase
          .from('products')
          .select('id, seller_id')
          .eq('name', entry.key)
          .maybeSingle();

      if (productResponse != null) {
        productDetails.add(productResponse);
      }
    }

    if (productDetails.isEmpty) {
      throw Exception("No valid product details found");
    }

    final sellerId = productDetails.first['seller_id'];

    final orderData = {
      "order_id": widget.orderId,
      "customer": user.id,
      "seller_id": sellerId,
      "date": DateTime.now().toIso8601String(),
      "status": "Confirmed",
      "payment": selectedPayment.name,
      "total": calculateTotal(),
      "delivery": "Singapore",
      "products": _lockedCart.entries.map((e) => "${e.key} x${e.value}").join(", "),
    };

    await _supabase.from('orders').insert(orderData);
    print("✅ Order inserted into single orders table");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order confirmed!")),
      );
      Navigator.pop(context, true);
    }

  } catch (e) {
    print("❌ Exception in _completeOrder: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error completing order: ${e.toString()}")),
      );
    }
  } finally {
    if (mounted) setState(() => _isProcessing = false);
  }
}



  Future<void> _handleCheckout() async {
    if (_isProcessing || !mounted) return;

    if (selectedPayment == PaymentMethod.paynow) {
      await _processPayNowPayment();
    } else {
      await _processStripePayment();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: !_paymentInProgress,
        leading: _paymentInProgress
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (mounted) {
                    setState(() => _paymentInProgress = false);
                  }
                },
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Order Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._lockedCart.entries.map((entry) => Text("• ${entry.key} x${entry.value}")),
            const SizedBox(height: 20),
            Text("Total: \$${calculateTotal().toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            const Text("Choose Payment Method:", style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<PaymentMethod>(
              title: const Text("PayNow"),
              value: PaymentMethod.paynow,
              groupValue: selectedPayment,
              onChanged: _paymentInProgress
                  ? null
                  : (value) {
                      if (value != null && mounted) {
                        setState(() => selectedPayment = value);
                      }
                    },
            ),
            RadioListTile<PaymentMethod>(
              title: const Text("Stripe (Pay via Credit Card)"),
              value: PaymentMethod.stripe,
              groupValue: selectedPayment,
              onChanged: _paymentInProgress
                  ? null
                  : (value) {
                      if (value != null && mounted) {
                        setState(() => selectedPayment = value);
                      }
                    },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Confirm & Pay", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}