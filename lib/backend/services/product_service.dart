import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// **Delete product image and database record**
  static Future<void> deleteProduct(String productId, String? imagePath) async {
    if (imagePath != null && imagePath.startsWith('storage/')) {
      final path = imagePath.replaceFirst('storage/', '');
      await _supabase.storage.from('product_images').remove([path]);
    }

    await _supabase.from('products').delete().eq('id', productId);
  }

  /// **Update Product in Supabase**
  static Future<Map<String, dynamic>?> updateProduct(
      String productId, Map<String, dynamic> updatedProduct) async {
    try {
      int stock = int.tryParse(updatedProduct['stock'].toString()) ?? 0;
      if (stock > 100) stock = 100;

      final status = stock >= 100 ? 'Max Limit Reached' : 'Available';

      final response = await _supabase.from('products').upsert({
        'id': productId,
        'name': updatedProduct['name'],
        'description': updatedProduct['description'],
        'price': updatedProduct['price'],
        'category': updatedProduct['category'],
        'stock': stock,
        'status': status,
        'image': updatedProduct['image']?.toString(),
      }).select().single();

      return response;
    } catch (e) {
      print('Error updating product: $e');
      return null;
    }
  }

  /// **Fetch Products created by the currently logged-in seller**
  static Future<List<Map<String, dynamic>>> loadProducts() async {
    try {
      final data = await _supabase
          .from('products')
          .select()
          .eq('seller_id', _supabase.auth.currentUser!.id);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("Error occurred while loading products: $e");
      return [];
    }
  }

  /// ✅ **Fetch all 'Available' products for Users**
  static Future<List<Map<String, dynamic>>> loadAllAvailableProducts() async {
    try {
      final data = await _supabase
          .from('products')
          .select()
          .eq('status', 'Available');

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("Error fetching available products: $e");
      return [];
    }
  }

static Future<bool> insertProduct(Map<String, dynamic> newProduct) async {
  try {
    int stock = int.tryParse(newProduct['stock'].toString()) ?? 0;
    bool isCapped = false;

    print("Original stock input: ${newProduct['stock']}");

    if (stock > 100) {
      stock = 100;
      isCapped = true;
    }

    final status = stock >= 100 ? 'Max Limit Reached' : 'Available';

    await _supabase.from('products').insert({
      'name': newProduct['name'],
      'description': newProduct['description'],
      'price': newProduct['price'],
      'category': newProduct['category'],
      'stock': stock,
      'status': status,
      'image': newProduct['image']?.toString() ?? 'assets/default_image.png',
      'seller_id': _supabase.auth.currentUser!.id,
    });

    return isCapped;
  } catch (error) {
    print("Error inserting product: $error");
    rethrow;
  }
}
}