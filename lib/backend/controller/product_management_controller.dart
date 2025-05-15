import 'package:supabase_flutter/supabase_flutter.dart';

class ProductManagementController {
  final SupabaseClient supabase;

  ProductManagementController({
    required this.supabase,
  });

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      // Fetch products
      final response = await supabase.from('products').select();

      if (response is List) {
        for (var product in response) {
          final uid = product['seller_id'];

          // Fetch submitter names
          final userProfile = await supabase.from('user_profiles')
              .select('name')
              .eq('uid', uid)
              .maybeSingle();
          final businessProfile = await supabase.from('business_profiles')
              .select('name')
              .eq('uid', uid)
              .maybeSingle();
          final nutritionistProfile = await supabase.from('nutritionist_profiles')
              .select('full_name')
              .eq('uid', uid)
              .maybeSingle();

          product['submitter_name'] = userProfile?['name'] ??
              businessProfile?['name'] ??
              nutritionistProfile?['full_name'] ??
              'Unknown';
        }

        return List<Map<String, dynamic>>.from(response);
      } else {
        print("Error: Unexpected response format for products.");
        return [];
      }
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchProductById(int productId) async {
    try {
      final response = await supabase.from('products').select().eq('id', productId).maybeSingle();
      return response;
    } catch (e) {
      print("Error fetching product: $e");
      return null;
    }
  }
}
