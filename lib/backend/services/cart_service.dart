import 'package:supabase_flutter/supabase_flutter.dart';

class CartService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Add a product to cart or update quantity if already exists
static Future<void> addToCart({
  required String productId,
  required int quantity,
}) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    print('[DEBUG] Adding to cart - User: $userId, Product: $productId');
    
    if (userId == null) throw Exception('User not authenticated');

    // Verify product exists
    final product = await Supabase.instance.client
        .from('products')
        .select('id, stock')
        .eq('id', productId)
        .single()
        .catchError((e) {
          print('[ERROR] Product lookup failed: $e');
          throw Exception('Product not found');
        });

    print('[DEBUG] Product stock: ${product['stock']}');

    // Insert into cart
    final response = await Supabase.instance.client
        .from('carts')
        .insert({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
        })
        .select()  // Return the inserted record
        .single();

    print('[SUCCESS] Added to cart: $response');
  } catch (e) {
    print('[ERROR] Add to cart failed: $e');
    throw Exception('Failed to add to cart: $e');
  }
}


  // Remove a product from cart
  static Future<void> removeFromCart(String cartItemId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('carts')
          .delete()
          .eq('id', cartItemId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to remove from cart: ${e.toString()}');
    }
  }

  // Get all cart items for current user with product details
static Future<List<Map<String, dynamic>>> getCartItems() async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) throw Exception('User not logged in');

  final response = await Supabase.instance.client
      .from('carts')
      .select('''
        id, 
        quantity,
        product_id,
        products:product_id (id, name, price, image)
      ''')
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  return (response as List).cast<Map<String, dynamic>>();
}

  // Update quantity of a cart item
  static Future<void> updateCartItemQuantity({
    required String cartItemId,
    required int newQuantity,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      if (newQuantity <= 0) {
        await removeFromCart(cartItemId);
        return;
      }

      final cartItem = await _supabase
          .from('carts')
          .select('product_id')
          .eq('id', cartItemId)
          .single();

      final product = await _supabase
          .from('products')
          .select('stock')
          .eq('id', cartItem['product_id'])
          .single();

      if (product['stock'] < newQuantity) {
        throw Exception('Insufficient stock available');
      }

      await _supabase
          .from('carts')
          .update({
            'quantity': newQuantity,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', cartItemId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update cart item quantity: ${e.toString()}');
    }
  }

  // Clear all items from cart for current user
  static Future<void> clearCart() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('carts').delete().eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to clear cart: ${e.toString()}');
    }
  }

  // Get cart items count for current user (sum of quantities)
  static Future<int> getCartItemsCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('carts')
          .select('sum(quantity)')
          .eq('user_id', userId);

      return (response[0]['sum'] as int?) ?? 0;
    } catch (e) {
      throw Exception('Failed to get cart items count: ${e.toString()}');
    }
  }

  // Get total price of all items in cart
  static Future<double> getCartTotal() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('carts')
          .select('quantity, products(price)')
          .eq('user_id', userId);

      double total = 0;
      for (final item in response) {
        final quantity = item['quantity'] as int;
        final price = item['products']['price'] as double;
        total += quantity * price;
      }

      return total;
    } catch (e) {
      throw Exception('Failed to calculate cart total: ${e.toString()}');
    }
  }
}
