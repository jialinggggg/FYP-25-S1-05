import 'dart:async';

class SharedOrderStore {
  // Private constructor to prevent instantiation
  SharedOrderStore._();

  // Main storage using orderId as key for O(1) access
  static final Map<String, Map<String, dynamic>> _orders = {};

  // Stream controller for real-time updates
  static final StreamController<Map<String, dynamic>> _updateStream =
      StreamController.broadcast();

  // Public stream for order updates
  static Stream<Map<String, dynamic>> get onOrderUpdated => _updateStream.stream;

  // Public getter for all orders (unmodifiable)
  static List<Map<String, dynamic>> get userOrders =>
      List.unmodifiable(_orders.values);

  /// Adds or updates an order with comprehensive synchronization
  static void addOrUpdateUserOrder(Map<String, dynamic> order) {
    final orderId = _extractOrderId(order);
    if (orderId == null) return;

    final normalizedOrder = _normalizeOrder(order);
    _orders[orderId] = normalizedOrder;
    _notifyUpdate(normalizedOrder);
  }

  /// Updates existing order if present
  static void updateOrder(Map<String, dynamic> order) {
    final orderId = _extractOrderId(order);
    if (orderId == null || !_orders.containsKey(orderId)) return;

    final normalizedOrder = _normalizeOrder(order);
    _orders[orderId] = normalizedOrder;
    _notifyUpdate(normalizedOrder);
  }

  /// Gets a specific order by ID
  static Map<String, dynamic>? getOrder(String orderId) {
    return _orders[orderId];
  }

  /// Clears all orders from storage
  static void clear() {
    _orders.clear();
  }

  /// Removes a specific order by ID
  static void removeOrder(String orderId) {
    _orders.remove(orderId);
  }

  // --- Private Helper Methods ---

  static String? _extractOrderId(Map<String, dynamic> order) {
    return order['order_id']?.toString() ?? order['orderId']?.toString();
  }

  static void _notifyUpdate(Map<String, dynamic> order) {
    if (!_updateStream.isClosed) {
      _updateStream.add(order);
    }
  }

  static Map<String, dynamic> _normalizeOrder(Map<String, dynamic> order) {
    final orderId = _extractOrderId(order) ?? '';
    final status = order['status']?.toString();
    final steps = order['steps'];

    final effectiveStatus = status ?? _orders[orderId]?['status']?.toString() ?? 'Confirmed';
    final effectiveSteps = steps ?? _orders[orderId]?['steps'] ?? _generateSteps(effectiveStatus);

    return {
      'order_id': orderId,
      'orderId': orderId, // Maintain both formats for compatibility
      'customer': order['customer'] ?? _orders[orderId]?['customer'] ?? 'Unknown Customer',
      'products': order['products'] ?? _orders[orderId]?['products'] ?? '',
      'total': order['total'] ?? _orders[orderId]?['total'] ?? 0.0,
      'date': order['date'] ?? _orders[orderId]?['date'] ?? DateTime.now().toIso8601String(),
      'delivery': order['delivery'] ?? _orders[orderId]?['delivery'] ?? '',
      'status': effectiveStatus,
      'steps': effectiveSteps,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  static List<Map<String, dynamic>> _generateSteps(String status) {
    const steps = [
      "Confirmed",
      "Preparing",
      "Out for Delivery", 
      "Delivered",
    ];

    final currentIndex = steps.indexOf(status);
    return steps.map((step) => {
      'title': step,
      'done': steps.indexOf(step) <= currentIndex,
      'status': step,
    }).toList();
  }

  /// Close the stream controller when no longer needed
  static void dispose() {
    _updateStream.close();
  }
}
