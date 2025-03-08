import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  AddRecipeScreenState createState() => AddRecipeScreenState();
}

class AddRecipeScreenState extends State<AddRecipeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  String? _selectedImage;
  final List<TextEditingController> _ingredientControllers = [];
  final List<TextEditingController> _instructionControllers = [];

  ///Request Permissions & Pick Image
  Future<void> _pickImage() async {
    final permissionStatus = await Permission.storage.request(); //Request storage permission

    if (!mounted) return; //Check if widget is still in the widget tree

    if (permissionStatus.isGranted) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (!mounted) return; //Check again after async call

      if (image != null) {
        setState(() {
          _selectedImage = image.path;
        });
      }
    } else {
      if (mounted) { //Ensure widget is mounted before using `context`
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permission denied! Please enable it in settings.")),
        );
      }
    }
  }

  ///Add/Delete Ingredient
  void _addIngredientField() {
    setState(() => _ingredientControllers.add(TextEditingController()));
  }

  void _removeIngredientField(int index) {
    setState(() => _ingredientControllers.removeAt(index));
  }

  ///Add/Delete Instruction Step
  void _addInstructionField() {
    setState(() => _instructionControllers.add(TextEditingController()));
  }

  void _removeInstructionField(int index) {
    setState(() => _instructionControllers.removeAt(index));
  }

  /// ✅ **Save Recipe**
  /// ✅ **Save Recipe & Pass Back to BizProductsScreen**
  void _saveRecipe() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a name and an image for the recipe!")),
      );
      return;
    }

    List<String> ingredients = _ingredientControllers.map((c) => c.text).where((i) => i.isNotEmpty).toList();
    List<String> instructions = _instructionControllers.map((c) => c.text).where((s) => s.isNotEmpty).toList();

    Map<String, dynamic> newRecipe = {
      "name": _nameController.text,
      "description": _descriptionController.text,
      "calories": _caloriesController.text,
      "time": _timeController.text,
      "image": _selectedImage ?? "assets/default_image.png",
      "ingredients": ingredients,
      "instructions": instructions,
    };

    /// ✅ **Pass the new recipe back to BizProductsScreen**
    Navigator.pop(context, newRecipe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Recipe"),
        backgroundColor: Colors.white,
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

              /// 📝 **Recipe Name**
              const Text("Recipe Name", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _nameController, decoration: const InputDecoration(border: OutlineInputBorder())),

              const SizedBox(height: 10),

              /// 🍽 **Calories & Time Input**
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(labelText: "Calories (kcal)", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _timeController,
                      decoration: const InputDecoration(labelText: "Time (minutes)", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              ///Short Description
              const Text("Enter a short description", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _descriptionController, decoration: const InputDecoration(border: OutlineInputBorder())),

              const SizedBox(height: 10),

              /// Ingredients
              const Text("Ingredients", style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _ingredientControllers.length,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ingredientControllers[index],
                              decoration: const InputDecoration(hintText: "Enter ingredient", border: OutlineInputBorder()),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeIngredientField(index),
                          ),
                        ],
                      );
                    },
                  ),
                  TextButton(
                    onPressed: _addIngredientField,
                    child: const Text("+ Add Ingredient", style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// 📜 **Instructions**
              const Text("Instructions", style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _instructionControllers.length,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _instructionControllers[index],
                              decoration: InputDecoration(labelText: "Step ${index + 1}", border: const OutlineInputBorder()),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeInstructionField(index),
                          ),
                        ],
                      );
                    },
                  ),
                  TextButton(
                    onPressed: _addInstructionField,
                    child: const Text("+ Add Step", style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveRecipe,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15)),
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