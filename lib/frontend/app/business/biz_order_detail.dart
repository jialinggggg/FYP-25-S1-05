import 'package:flutter/material.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  int _currentStep = 0;

  final List<String> _steps = [
    "Order Received",
    "Preparing",
    "Out for Delivery",
    "Delivered",
  ];

  @override
  void initState() {
    super.initState();

    // Set progress based on current status
    final status = widget.order["status"];
    switch (status) {
      case "Preparing":
        _currentStep = 1;
        break;
      case "Out for Delivery":
        _currentStep = 2;
        break;
      case "Delivered":
        _currentStep = 3;
        break;
      default:
        _currentStep = 0;
    }
  }

  void _updateStatus(int newStep) {
    setState(() {
      _currentStep = newStep;
      widget.order["status"] = _steps[newStep];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Order status updated to '${_steps[newStep]}'")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(
        title: Text("Order ${order["orderId"]}"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Customer: ${order["customer"]}", style: const TextStyle(fontSize: 16)),
            Text("Date: ${order["date"]}", style: const TextStyle(fontSize: 16)),
            Text("Products: ${order["products"]}", style: const TextStyle(fontSize: 16)),
            Text("Total: ${order["total"]}", style: const TextStyle(fontSize: 16)),
            Text("Delivery: ${order["delivery"]}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Text("Order Progress:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),

            Stepper(
              currentStep: _currentStep,
              onStepTapped: _updateStatus,
              controlsBuilder: (context, _) => const SizedBox.shrink(),
              steps: _steps.map((step) {
                return Step(
                  title: Text(step),
                  content: const SizedBox.shrink(),
                  isActive: _steps.indexOf(step) <= _currentStep,
                  state: _steps.indexOf(step) < _currentStep
                      ? StepState.complete
                      : StepState.indexed,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}