import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? existingProduct;

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

  String? _selectedImageUrl;
  File? _selectedImageFile;
  bool _isUploading = false;

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    if (widget.existingProduct != null) {
      _nameController.text = widget.existingProduct!["name"];
      _descriptionController.text = widget.existingProduct!["description"];
      _priceController.text = widget.existingProduct!["price"];
      _categoryController.text = widget.existingProduct!["category"];
      _stockController.text = widget.existingProduct!["stock"];
      _selectedImageUrl = widget.existingProduct!["image"];
    }
  }

  Future<void> _showImageSourceDialog() async {
    final option = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('From Supabase Storage'),
              onTap: () => Navigator.pop(context, 1),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload New Image'),
              onTap: () => Navigator.pop(context, 2),
            ),
          ],
        ),
      ),
    );

    if (option == 1) {
      await _pickFromSupabase();
    } else if (option == 2) {
      await _pickFromGallery();
    }
  }

  Future<void> _pickFromSupabase() async {
  final selectedImage = await Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (context) => SupabaseImagePickerScreen(
        onImageSelected: (_) {}, // optional, can be removed
      ),
    ),
  );

  if (selectedImage != null && mounted) {
    setState(() {
      _selectedImageUrl = selectedImage;
      _selectedImageFile = null;
    });
  }
}


  Future<void> _pickFromGallery() async {
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
          _selectedImageFile = File(image.path);
          _selectedImageUrl = null;
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

  Future<String?> _uploadImageToSupabase() async {
    if (_selectedImageFile == null) return _selectedImageUrl;

    setState(() {
      _isUploading = true;
    });

    try {
      final fileExtension = _selectedImageFile!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = 'product-image/$fileName';

      await supabase.storage
          .from('product-image')
          .upload(filePath, _selectedImageFile!);

      final imageUrl = supabase.storage
          .from('product-image')
          .getPublicUrl(filePath);

      debugPrint('Image uploaded to: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error uploading image: ${e.toString()}")),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a name and price for the product!")),
      );
      return;
    }

    String? imageUrl = _selectedImageUrl;
    if (_selectedImageFile != null) {
      imageUrl = await _uploadImageToSupabase();
      if (imageUrl == null) return;
    }

    Map<String, dynamic> newProduct = {
      "name": _nameController.text,
      "description": _descriptionController.text,
      "price": _priceController.text,
      "category": _categoryController.text,
      "stock": _stockController.text,
      "image": imageUrl ?? "default_image.png",
    };

    if (mounted) {
      Navigator.pop(context, newProduct);
    }
  }

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
              Navigator.pop(context);
              Navigator.pop(context, "delete");
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.existingProduct == null ? "Add Product" : "Edit Product"),
        backgroundColor: Colors.white,
        actions: widget.existingProduct != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteProduct,
                )
              ]
            : null,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : _selectedImageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
                                )
                              : _selectedImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _selectedImageUrl!,
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

                  const Text("Product Name*", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter product name",
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter product description",
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text("Price*", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter price",
                      prefixText: "\$ ",
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),

                  const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter category",
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text("Stock Quantity", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter stock quantity",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "SAVE PRODUCT",
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SupabaseImagePickerScreen extends StatefulWidget {
  final Function(String) onImageSelected;

  const SupabaseImagePickerScreen({super.key, required this.onImageSelected});

  @override
  State<SupabaseImagePickerScreen> createState() => _SupabaseImagePickerScreenState();
}

class _SupabaseImagePickerScreenState extends State<SupabaseImagePickerScreen> {
  List<String> imageUrls = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchImagesFromSupabase();
  }

  Future<void> _fetchImagesFromSupabase() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await Supabase.instance.client
          .storage
          .from('product-image')
          .list();

      debugPrint('Found ${response.length} images in storage');

      if (response.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'No images found in storage';
        });
        return;
      }

      final List<String> urls = [];
      for (var file in response) {
        try {
          final url = Supabase.instance.client
              .storage
              .from('product-image')
              .getPublicUrl(file.name);
          urls.add(url);
          debugPrint('Added image URL: $url');
        } catch (e) {
          debugPrint('Error getting URL for ${file.name}: $e');
        }
      }

      setState(() {
        imageUrls = urls;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching images: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load images. Please try again.';
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Select Product Image'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchImagesFromSupabase,
        ),
      ],
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchImagesFromSupabase,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  final imageUrl = imageUrls[index];
                  return GestureDetector(
                    onTap: () {
                      widget.onImageSelected(imageUrl); // Optional callback
                      Navigator.pop(context, imageUrl); // Pass image URL back
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 40),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
  );
}
}