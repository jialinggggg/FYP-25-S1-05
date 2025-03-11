import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? existingProduct; // ✅ If editing an existing product

  const AddProductScreen({super.key, this.existingProduct});

  @override
  AddProductScreenState createState() => AddProductScreenState();
}

class AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  String? _selectedImage;

  @override
  void initState() {
    super.initState();

    // **Pre-fill fields if editing an existing product**
    if (widget.existingProduct != null) {
      _nameController.text = widget.existingProduct!["name"];
      _descriptionController.text = widget.existingProduct!["description"];
      _priceController.text = widget.existingProduct!["price"];
      _categoryController.text = widget.existingProduct!["category"];
      _stockController.text = widget.existingProduct!["stock"];
      _selectedImage = widget.existingProduct!["image"];
    }
  }

  /// **Request Permissions & Pick Image**
  Future<void> _pickImage() async {
    final permissionStatus = await Permission.storage.request(); // Request storage permission

    if (!mounted) return; // Ensure widget is still in the widget tree

    if (permissionStatus.isGranted) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (!mounted) return; // Check again after async call

      if (image != null) {
        setState(() {
          _selectedImage = image.path;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permission denied! Please enable it in settings.")),
        );
      }
    }
  }

  /// **Save Product (Create or Update)**
  void _saveProduct() {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a name and price for the product!")),
      );
      return;
    }

    Map<String, dynamic> newProduct = {
      "name": _nameController.text,
      "description": _descriptionController.text,
      "price": _priceController.text,
      "category": _categoryController.text,
      "stock": _stockController.text,
      "image": _selectedImage ?? "assets/default_image.png", // ✅ Default image if none selected
    };

    Navigator.pop(context, newProduct); // ✅ Pass product data back to ProductsScreen
  }

  /// **Delete Product (If Editing)**
  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, "delete"); // Return delete flag
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black), // ✅ Back button
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.existingProduct == null ? "Add Product" : "Edit Product"),
        backgroundColor: Colors.white,
        actions: widget.existingProduct != null
            ? [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteProduct, // ✅ Show delete confirmation
          )
        ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🖼 **Image Picker**
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: _selectedImage == null
                      ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image, size: 50, color: Colors.black54),
                        Text("Add Image"),
                      ],
                    ),
                  )
                      : Image.file(File(_selectedImage!), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),

              /// 📝 **Product Name**
              const Text("Product Name", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _nameController, decoration: const InputDecoration(border: OutlineInputBorder())),

              const SizedBox(height: 10),

              /// 📝 **Short Description**
              const Text("Enter a short description", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _descriptionController, decoration: const InputDecoration(border: OutlineInputBorder())),

              const SizedBox(height: 10),

              /// 📝 **Price**
              const Text("Price", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 10),

              /// 🏷 **Category**
              const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _categoryController, decoration: const InputDecoration(border: OutlineInputBorder())),

              const SizedBox(height: 10),

              /// 📦 **Stock Quantity**
              const Text("Stock Quantity", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: _stockController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              /// ✅ **Save Button**
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text("Save", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}