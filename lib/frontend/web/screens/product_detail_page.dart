import 'package:flutter/material.dart';
import 'package:nutri_app/backend/api/spoonacular_api_service.dart';
import 'package:nutri_app/backend/controller/product_management_controller.dart';
import 'package:nutri_app/backend/controller/recipe_report_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final ProductManagementController controller;

  const ProductDetailPage({super.key, required this.product, required this.controller});

  @override
  ProductDetailPageState createState() => ProductDetailPageState();
}

class ProductDetailPageState extends State<ProductDetailPage> {
  late RecipeReportController reportController;
  bool isHidden = false;

  @override
  void initState() {
    super.initState();
    reportController = RecipeReportController(
      supabase: Supabase.instance.client,
      apiService: SpoonacularApiService(),
    );
    isHidden = widget.product['hidden'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Product',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (product['hidden'] == true)
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  "HIDDEN",
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  product['image'] ?? 'https://via.placeholder.com/300',
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product['name'] ?? 'Unknown Product',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 20),
            Text(
              'Created by ${product['submitter_name'] ?? 'Unknown'} on ${product['created_at']?.split('T')[0] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const Divider(color: Colors.black26),
            const SizedBox(height: 30),

            Text("Description: ${product['description'] ?? 'N/A'}", style: const TextStyle(fontSize: 16)),
            Text("Category: ${product['category'] ?? 'N/A'}", style: const TextStyle(fontSize: 16)),
            Text("Price: \$${product['price'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16)),
            Text("Stock: ${product['stock'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16)),
            Text("Status: ${product['status'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
