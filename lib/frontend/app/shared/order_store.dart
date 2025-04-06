

class SharedOrderStore {
  static final List<Map<String, dynamic>> userOrders = [];

  static void addOrUpdateUserOrder(Map<String, dynamic> newOrder) {
    int index = userOrders.indexWhere((o) => o["orderId"] == newOrder["orderId"]);
    if (index != -1) {
      userOrders[index] = newOrder;
    } else {
      userOrders.add(newOrder);
    }
  }

  static void updateOrder(Map<String, dynamic> updatedOrder) {
    int index = userOrders.indexWhere((o) => o["orderId"] == updatedOrder["orderId"]);
    if (index != -1) {
      userOrders[index] = updatedOrder;
    }
  }

  static void clear() {
    userOrders.clear();
  }
}
