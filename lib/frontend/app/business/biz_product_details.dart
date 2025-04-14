import 'dart:io';
import 'package:flutter/material.dart';
import '../../../backend/services/product_service.dart'; // Make sure the path matches your project name

class BizProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onUpdate;
  final Function() onDelete;

  const BizProductDetailsScreen({
    super.key,
    required this.product,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  BizProductDetailsScreenState createState() => BizProductDetailsScreenState();
}

class BizProductDetailsScreenState extends State<BizProductDetailsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  late TextEditingController _stockController;
  String? _selectedImage;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product["name"]?.toString());
    _descriptionController = TextEditingController(text: widget.product["description"]?.toString());
    _priceController = TextEditingController(text: widget.product["price"]?.toString());
    _categoryController = TextEditingController(text: widget.product["category"]?.toString());
    _stockController = TextEditingController(text: widget.product["stock"]?.toString());
    _selectedImage = widget.product["image"]?.toString();
  }

  void _pickImage() {
    // You can implement image picking later.
  }

 void _saveChanges() async {
  int stock = int.tryParse(_stockController.text) ?? 0;

  // Check if stock exceeds the limit
  if (stock > 100) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("The stock limit reached (100 max)")),
    );
    return; // Exit the method to prevent updating if the stock exceeds 100
  }

  Map<String, dynamic> updatedProduct = {
    "name": _nameController.text,
    "description": _descriptionController.text,
    "price": _priceController.text,
    "category": _categoryController.text,
    "stock": stock,
    "status": widget.product["status"],
    "image": _selectedImage ?? "assets/default_image.png",
  };

  try {
    final response = await ProductService.updateProduct(
      widget.product['id'],
      updatedProduct,
    );

    if (response != null) {
      widget.onUpdate(response); // Updated product sent to parent

      // Check if response indicates stock was capped
      if (response['wasCapped'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("The stock limit reached (100 max)")),
        );
      }

      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update product")),
      );
    }
  } catch (e) {
    print('Error updating product: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}



  Future<void> _deleteProduct() async {
    setState(() => _isDeleting = true);

    try {
      await ProductService.deleteProduct(widget.product['id'], _selectedImage);
      widget.onDelete();

      // Ensure the context is still valid before popping
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: _deleteProduct,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: _isDeleting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                    image: _selectedImage != null && File(_selectedImage!).existsSync()
                        ? DecorationImage(image: FileImage(File(_selectedImage!)), fit: BoxFit.cover)
                        : const DecorationImage(image: AssetImage("assets/default_image.png"), fit: BoxFit.cover),
                  ),
                  child: const Center(child: Icon(Icons.camera_alt, color: Colors.black54, size: 30)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Product Name", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _nameController, decoration: const InputDecoration(border: OutlineInputBorder())),
              const SizedBox(height: 10),
              const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: "Price (\$)", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: "Stock Quantity", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _categoryController, decoration: const InputDecoration(border: OutlineInputBorder())),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmDelete,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: _isDeleting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Delete Product", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
