import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../shared/order_store.dart';


class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Map<String, dynamic> _currentOrder;
  int _currentStep = 0;
  StreamSubscription? _orderUpdateSubscription;

  final List<String> _statusSteps = [
    "Confirmed",
    "Preparing",
    "Out for Delivery",
    "Delivered",
  ];

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _currentStep = _statusSteps.indexOf(_currentOrder["status"] ?? "Confirmed");

    // Listen for external updates to this order
    _orderUpdateSubscription = SharedOrderStore.onOrderUpdated.listen((updatedOrder) {
      if (updatedOrder['order_id'] == _currentOrder['order_id'] && mounted) {
        setState(() {
          _currentOrder = updatedOrder;
          _currentStep = _statusSteps.indexOf(updatedOrder["status"] ?? "Confirmed");
        });
      }
    });
  }

  @override
  void dispose() {
    _orderUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _updateStatus(int newStep) async {
    final updatedStatus = _statusSteps[newStep];
    final updatedOrder = {
      ..._currentOrder,
      "status": updatedStatus,
      "steps": _generateSteps(updatedStatus),
      "last_updated": DateTime.now().toIso8601String(),
    };

    try {
      // Update Supabase
      await Supabase.instance.client
          .from('orders')
          .update({
            "status": updatedStatus,
            "steps": updatedOrder["steps"],
            "last_updated": updatedOrder["last_updated"],
          })
          .eq('order_id', updatedOrder['order_id']);

      // Update local store
      SharedOrderStore.addOrUpdateUserOrder(updatedOrder);

      if (mounted) {
        setState(() {
          _currentOrder = updatedOrder;
          _currentStep = newStep;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status updated to '$updatedStatus'")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e")),
        );
      }
    }
  }

  List<Map<String, dynamic>> _generateSteps(String status) {
    final currentIndex = _statusSteps.indexOf(status);
    return _statusSteps.asMap().entries.map((entry) {
      return {
        "title": entry.value,
        "done": entry.key <= currentIndex,
        "status": entry.value,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${_currentOrder["order_id"]}"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _updateStatus(_currentStep), // Force refresh
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderInfoCard(),
            const SizedBox(height: 24),
            _buildProgressStepper(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Customer: ${_currentOrder["customer"] ?? "Unknown"}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Date: ${_formatDate(_currentOrder["date"])}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Products: ${_currentOrder["products"] ?? "N/A"}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Total: \$${_currentOrder["total"]?.toStringAsFixed(2) ?? "0.00"}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Delivery: ${_currentOrder["delivery"] ?? "N/A"}",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStepper() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Order Progress",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Stepper(
          currentStep: _currentStep,
          onStepTapped: (newStep) {
            setState(() {
              _currentStep = newStep;
            });
            _updateStatus(newStep);
          },
          controlsBuilder: (context, _) => const SizedBox.shrink(),
          steps: _statusSteps.map((step) {
            final stepIndex = _statusSteps.indexOf(step);
            final isActive = stepIndex <= _currentStep;
            return Step(
              title: Text(
                step,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.green : Colors.grey,
                ),
              ),
              content: const SizedBox.shrink(),
              isActive: isActive,
              state: stepIndex < _currentStep
                  ? StepState.complete
                  : StepState.indexed,
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    try {
      final dateTime = date is String
          ? DateTime.parse(date).toLocal()
          : (date is DateTime ? date.toLocal() : DateTime.now());
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "Unknown date";
    }
  }
}
