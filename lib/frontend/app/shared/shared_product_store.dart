import 'dart:async';

class SharedProductStore {
  // Shared product list accessible by both business and consumer side
  static final List<Map<String, dynamic>> products = [];
  static final StreamController<List<Map<String, dynamic>>> _productsStreamController = StreamController.broadcast();

  // Stream to listen for product list changes
  static Stream<List<Map<String, dynamic>>> get productsStream => _productsStreamController.stream;

  /// Add new product or update existing one based on 'id'
  static void addOrUpdateProduct(Map<String, dynamic> newProduct) {
    int index = products.indexWhere((p) => p["id"] == newProduct["id"]);
    if (index != -1) {
      products[index] = newProduct;
    } else {
      products.add(newProduct);
    }
    _notifyProductChanges();  // Notify listeners
  }

  /// Update existing product using its 'id'
  static void updateProduct(Map<String, dynamic> updatedProduct) {
    int index = products.indexWhere((p) => p["id"] == updatedProduct["id"]);
    if (index != -1) {
      products[index] = updatedProduct;
    }
    _notifyProductChanges();  // Notify listeners
  }

  /// Delete a product by its 'id'
  static void deleteProduct(String id) {
    products.removeWhere((p) => p["id"] == id);
    _notifyProductChanges();  // Notify listeners
  }

  /// Clear all products (use with caution!)
  static void clear() {
    products.clear();
    _notifyProductChanges();  // Notify listeners
  }

  // Private method to notify listeners about product list changes
  static void _notifyProductChanges() {
    _productsStreamController.add(List.from(products));  // Broadcast updated list
  }
}
