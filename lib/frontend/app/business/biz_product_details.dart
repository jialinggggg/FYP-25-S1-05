import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../backend/services/product_service.dart';

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
  bool _isUploading = false;

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

  Future<void> _pickImage() async {
  Permission permission = Platform.isAndroid
      ? (await Permission.photos.request().isGranted
          ? Permission.photos
          : Permission.storage)
      : Permission.photos;

  final permissionStatus = await permission.request();

  if (!mounted) return;

  if (permissionStatus.isGranted) {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (!mounted) return;

    if (image != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        final file = File(image.path);
        final imageUrl = await ProductService.uploadProductImage(
          file,
          'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        if (!mounted) return;

        if (imageUrl != null) {
          setState(() {
            _selectedImage = imageUrl;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload image")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission denied! Please enable it in settings.")),
      );
    }
  }
}


  Future<void> _saveChanges() async {
    final stock = int.tryParse(_stockController.text) ?? 0;
    if (stock > 100) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stock limit reached (100 max)")),
      );
      return;
    }

    final updatedProduct = {
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

      if (!mounted) return;
      
      if (response != null) {
        widget.onUpdate(response);
        if (response['wasCapped'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Stock was capped at 100")),
          );
        }
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update product")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteProduct() async {
    setState(() => _isDeleting = true);
    try {
      await ProductService.deleteProduct(widget.product['id'], _selectedImage);
      widget.onDelete();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
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
        title: const Text("Product Details"),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
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
      borderRadius: BorderRadius.circular(8),
    ),
    child: _isUploading
        ? const Center(child: CircularProgressIndicator())
        : _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image)),
                ),
              )
            : const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image, size: 50, color: Colors.black54),
                    SizedBox(height: 8),
                    Text("Select Product Image"),
                  ],
                ),
              ),
  ),
),

              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Product Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: "Price (\$)",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: "Stock Quantity",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text("Save Changes"),
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