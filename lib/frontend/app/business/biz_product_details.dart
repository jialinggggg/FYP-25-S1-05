import 'dart:io';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product["name"]);
    _descriptionController = TextEditingController(text: widget.product["description"]);
    _priceController = TextEditingController(text: widget.product["price"]);
    _categoryController = TextEditingController(text: widget.product["category"]);
    _stockController = TextEditingController(text: widget.product["stock"]);
    _selectedImage = widget.product["image"];
  }

  /// **🖼 Pick Image Function (Future Feature)**
  void _pickImage() {
    // Image picker logic can be added later if needed
  }

  /// **✅ Save Updated Product**
  void _saveChanges() {
    Map<String, dynamic> updatedProduct = {
      "name": _nameController.text,
      "description": _descriptionController.text,
      "price": _priceController.text,
      "category": _categoryController.text,
      "stock": _stockController.text,
      "status": widget.product["status"],
      "image": _selectedImage ?? "assets/default_image.png",
    };

    widget.onUpdate(updatedProduct);
    Navigator.pop(context);
  }

  /// **🗑 Confirm & Delete Product**
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
            onPressed: () {
              widget.onDelete();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to Product List
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// **App Bar**
      appBar: AppBar(
        title: const Text("Product Details", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      /// **Body Content**
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🖼 **Product Image**
              GestureDetector(
                onTap: _pickImage, // Click to update image
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

              /// 📝 **Product Name**
              const Text("Product Name", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _nameController, decoration: const InputDecoration(border: OutlineInputBorder())),

              const SizedBox(height: 10),

              /// 📝 **Product Description**
              const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),

              const SizedBox(height: 10),

              /// **Price & Stock**
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

              /// **Category**
              const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _categoryController, decoration: const InputDecoration(border: OutlineInputBorder())),

              const SizedBox(height: 20),

              /// **Save & Delete Buttons**
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
                      child: const Text("Delete Product", style: TextStyle(color: Colors.white)),
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