import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';


class ProductService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// **Upload product image to Supabase storage**
  static Future<String?> uploadProductImage(File imageFile, String fileName) async {
  try {
    final fileExtension = fileName.split('.').last.toLowerCase();
    final mimeType = fileExtension == 'jpg' || fileExtension == 'jpeg' 
        ? 'image/jpeg' 
        : 'image/png';

    // Upload file (throws if error occurs)
    await _supabase.storage
        .from('product-image')
        .upload(
          fileName,
          imageFile,
          fileOptions: FileOptions(contentType: mimeType),
        );

    // Get public URL
    final response = await _supabase.storage
        .from('product-image')
        .createSignedUrl(fileName, 60 * 60 * 24 * 365 * 10); // 10 years

    return response;
  } catch (e) {
    debugPrint('Error uploading image: $e');
    return null;
  }
}


  /// **Delete product image and database record**
  static Future<void> deleteProduct(String productId, String? imagePath) async {
    if (imagePath != null && imagePath.startsWith('storage/')) {
      final path = imagePath.replaceFirst('storage/', '');
      await _supabase.storage.from('product-image').remove([path]);
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

      final response = await _supabase
          .from('products')
          .upsert({
            'id': productId,
            'name': updatedProduct['name'],
            'description': updatedProduct['description'],
            'price': updatedProduct['price'],
            'category': updatedProduct['category'],
            'stock': stock,
            'status': status,
            'image': updatedProduct['image']?.toString(),
          })
          .select()
          .single();

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

  /// **Fetch all 'Available' products for users, excluding reported ones**
  static Future<List<Map<String, dynamic>>> loadAllAvailableProducts() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // 1) Get this user's reported product IDs
      final reportedRes = await _supabase
          .from('product_report')
          .select('product_id')
          .eq('user_id', user.id);
      
      // Extract product IDs ensuring they match the type in products table
      final reportedIds = (reportedRes as List)
          .map((r) => r['product_id']?.toString())
          .whereType<String>()
          .toList();

      // 2) Fetch all available products
      var query = _supabase
          .from('products')
          .select()
          .eq('status', 'Available');

      // 3) If there are reported IDs, filter them out
      if (reportedIds.isNotEmpty) {
        query = query.not('id', 'in', reportedIds);
      }

      // 4) Execute the query
      final productsRes = await query;
      return List<Map<String, dynamic>>.from(productsRes);
    } catch (e) {
      print("Error fetching available products: $e");
      return [];
    }
  }

  /// **Insert a new product**
  static Future<bool> insertProduct(Map<String, dynamic> newProduct) async {
    try {
      int stock = int.tryParse(newProduct['stock'].toString()) ?? 0;
      bool isCapped = false;

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

  /// **Report a product**
  static Future<bool> reportProduct(int productId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Avoid duplicate reports
      final existing = await _supabase
          .from('product_report')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) return true; // Already reported

      await _supabase.from('product_report').insert({
        'user_id': user.id,
        'product_id': productId,
      });

      return true;
    } catch (e) {
      print("Error reporting product: $e");
      return false;
    }
  }
}