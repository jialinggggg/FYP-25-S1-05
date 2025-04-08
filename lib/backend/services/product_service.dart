import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// **Delete product image and database record**
  static Future<void> deleteProduct(String productId, String? imagePath) async {
    // Remove image from Supabase Storage if applicable
    if (imagePath != null && imagePath.startsWith('storage/')) {
      final path = imagePath.replaceFirst('storage/', '');
      await _supabase.storage.from('product_images').remove([path]);
    }

    // Delete product from Supabase table
    await _supabase.from('products').delete().eq('id', productId);
  }

  /// **Update Product in Supabase**
  static Future<Map<String, dynamic>?> updateProduct(
      String productId, Map<String, dynamic> updatedProduct) async {
    try {
      // Get the status based on stock value
      final status = (int.tryParse(updatedProduct['stock'].toString()) ?? 0) > 50
          ? 'Out of stock' // If stock exceeds 50, mark as "Out of stock"
          : 'Available';   // Otherwise, mark as "Available"

      final response = await _supabase.from('products').upsert({
        'id': productId,
        'name': updatedProduct['name'],
        'description': updatedProduct['description'],
        'price': updatedProduct['price'],
        'category': updatedProduct['category'],
        'stock': updatedProduct['stock'],
        'status': status, // Set status based on stock
        'image': updatedProduct['image']?.toString(),
      }).select().single();

      // Return the updated product if successful
      return response;
    } catch (e) {
      print('Error updating product: $e');
      return null; // Return null in case of an error
    }
  }

  /// **Fetch Products from Supabase for the current seller**
  static Future<List<Map<String, dynamic>>> loadProducts() async {
    try {
      final data = await _supabase.from('products')
          .select()
          .eq('seller_id', _supabase.auth.currentUser!.id);

      if (data != null) {
        List<dynamic> productList = data is List ? data : [];
        return List<Map<String, dynamic>>.from(productList);
      } else {
        return [];
      }
    } catch (e) {
      print("Error occurred while loading products: $e");
      return [];
    }
  }

  /// **Insert a New Product into Supabase**
  static Future<void> insertProduct(Map<String, dynamic> newProduct) async {
    try {
      // Determine product status based on the stock value
      final status = (int.tryParse(newProduct['stock'].toString()) ?? 0) > 50
          ? 'Out of stock'
          : 'Available';

      await _supabase.from('products').insert({
        'name': newProduct['name'],
        'description': newProduct['description'],
        'price': newProduct['price'],
        'category': newProduct['category'],
        'stock': newProduct['stock'] ?? 0,
        'status': status,
        'image': newProduct['image']?.toString() ?? 'assets/default_image.png',
        'seller_id': _supabase.auth.currentUser!.id,
      });
    } catch (error) {
      print("Error inserting product: $error");
      rethrow;
    }
  }
}
