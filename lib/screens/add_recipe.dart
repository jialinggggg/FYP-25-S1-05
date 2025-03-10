import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  AddRecipeScreenState createState() => AddRecipeScreenState();
}

class AddRecipeScreenState extends State<AddRecipeScreen> {
  // Controllers for manual recipe entry
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // Controller for recipe search input
  final TextEditingController _recipeSearchController = TextEditingController();

  String? _selectedImage;
  final List<TextEditingController> _ingredientControllers = [];
  final List<TextEditingController> _instructionControllers = [];

  // Initialize your Supabase client
  final SupabaseClient supabase = Supabase.instance.client;

  // Spoonacular API key (replace with your own)
  final String apiKey = "fede250789e24f828573be12cb0d08a8";

  // For debouncing recipe search
  Timer? _recipeSearchDebounce;
  // Cache for recipe search results
  final Map<String, List<Map<String, dynamic>>> _recipeSearchCache = {};
  List<Map<String, dynamic>> _recipeResults = [];

  @override
  void initState() {
    super.initState();

    // Listen to changes in recipe search field with debounce
    _recipeSearchController.addListener(() {
      if (_recipeSearchDebounce?.isActive ?? false) _recipeSearchDebounce!.cancel();
      _recipeSearchDebounce = Timer(const Duration(milliseconds: 500), () {
        _searchRecipes(_recipeSearchController.text);
      });
    });
  }

  @override
  void dispose() {
    _recipeSearchDebounce?.cancel();
    _recipeSearchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    _timeController.dispose();
    for (final controller in _ingredientControllers) {
      controller.dispose();
    }
    for (final controller in _instructionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// SEARCH RECIPES VIA SPOONACULAR API
  Future<void> _searchRecipes(String query) async {
    if (query.isEmpty) {
      setState(() {
        _recipeResults = [];
      });
      return;
    }

    // Use cached results if available
    if (_recipeSearchCache.containsKey(query)) {
      setState(() {
        _recipeResults = _recipeSearchCache[query]!;
      });
      return;
    }

    final url =
        'https://api.spoonacular.com/recipes/complexSearch?query=$query&number=10&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List<dynamic> results = jsonResponse['results'] ?? [];
        List<Map<String, dynamic>> tempResults = [];

        for (var recipe in results) {
          tempResults.add({
            "id": recipe["id"],
            "title": recipe["title"],
            "image": recipe["image"],
          });
        }

        // Cache the results
        _recipeSearchCache[query] = tempResults;

        setState(() {
          _recipeResults = tempResults;
        });
      } else {
        print("Error fetching recipe search results: ${response.statusCode}");
        setState(() {
          _recipeResults = [];
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        _recipeResults = [];
      });
    }
  }

  /// GET RECIPE DETAILS FROM SPOONACULAR AND PREFILL FORM
  Future<void> _populateRecipeDetails(int recipeId) async {
    final url = 'https://api.spoonacular.com/recipes/$recipeId/information?apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Prefill form fields
        _nameController.text = jsonResponse['title'] ?? "";
        _timeController.text = jsonResponse['readyInMinutes']?.toString() ?? "";
        _descriptionController.text = jsonResponse['summary'] ?? "";
        if (jsonResponse['nutrition'] != null &&
            jsonResponse['nutrition']['nutrients'] != null) {
          var nutrients = jsonResponse['nutrition']['nutrients'];
          var calInfo = nutrients.firstWhere(
            (n) => n['name'] == 'Calories',
            orElse: () => null,
          );
          _caloriesController.text = calInfo != null ? calInfo['amount'].toString() : "";
        }

        // Use API-provided image if available
        if (jsonResponse['image'] != null) {
          _selectedImage = jsonResponse['image'];
        }

        // Populate ingredients (using extendedIngredients if available)
        if (jsonResponse['extendedIngredients'] != null) {
          _ingredientControllers.clear();
          for (var ingredient in jsonResponse['extendedIngredients']) {
            final controller = TextEditingController(text: ingredient['original'] ?? "");
            _ingredientControllers.add(controller);
          }
        }

        // Populate instructions (using analyzedInstructions)
        if (jsonResponse['analyzedInstructions'] != null &&
            jsonResponse['analyzedInstructions'].length > 0 &&
            jsonResponse['analyzedInstructions'][0]['steps'] != null) {
          _instructionControllers.clear();
          List steps = jsonResponse['analyzedInstructions'][0]['steps'];
          for (var step in steps) {
            final controller = TextEditingController(text: step['step'] ?? "");
            _instructionControllers.add(controller);
          }
        }

        // Clear recipe search results and search field
        setState(() {
          _recipeResults = [];
          _recipeSearchController.clear();
        });
      } else {
        print("Error fetching recipe details: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  /// REQUEST PERMISSION & PICK IMAGE FROM GALLERY
  Future<void> _pickImage() async {
    final permissionStatus = await Permission.storage.request();
    if (!mounted) return;
    if (permissionStatus.isGranted) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (!mounted) return;
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

  /// ADD / REMOVE INGREDIENT FIELDS
  void _addIngredientField() {
    setState(() => _ingredientControllers.add(TextEditingController()));
  }

  void _removeIngredientField(int index) {
    setState(() => _ingredientControllers.removeAt(index));
  }

  /// ADD / REMOVE INSTRUCTION FIELDS
  void _addInstructionField() {
    setState(() => _instructionControllers.add(TextEditingController()));
  }

  void _removeInstructionField(int index) {
    setState(() => _instructionControllers.removeAt(index));
  }

  /// SAVE THE RECIPE TO SUPABASE AND THEN PASS IT BACK
  Future<void> _saveRecipe() async {
  if (_nameController.text.isEmpty || _selectedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please add a name and an image for the recipe!")),
    );
    return;
  }

  // Convert ingredients and instructions to JSON format
  List<Map<String, dynamic>> ingredients = _ingredientControllers
      .where((c) => c.text.isNotEmpty)
      .map((c) => {"ingredient": c.text})
      .toList();

  List<Map<String, dynamic>> instructions = _instructionControllers
      .where((c) => c.text.isNotEmpty)
      .map((c) => {"step": c.text})
      .toList();

  Map<String, dynamic> newRecipe = {
    "name": _nameController.text,
    "description": _descriptionController.text,
    "calories": int.tryParse(_caloriesController.text) ?? 0,
    "time": int.tryParse(_timeController.text) ?? 0,
    "image": _selectedImage ?? "assets/default_image.png",
    "ingredients": jsonEncode(ingredients), // Store as JSON
    "instructions": jsonEncode(instructions), // Store as JSON
  };

  try {
    final response = await supabase.from('recipes').insert(newRecipe).select();
    print("Recipe saved: $response");
    Navigator.pop(context, newRecipe);
  } catch (error) {
    print("Error saving recipe: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to save recipe: $error")),
    );
  }
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
              // --- RECIPE SEARCH SECTION ---
              const Text("Search Spoonacular Recipes", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: _recipeSearchController,
                decoration: const InputDecoration(
                  hintText: "Enter recipe name...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              _recipeResults.isNotEmpty
                  ? Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListView.builder(
                        itemCount: _recipeResults.length,
                        itemBuilder: (context, index) {
                          final recipe = _recipeResults[index];
                          return ListTile(
                            leading: recipe["image"] != null
                                ? Image.network(recipe["image"], width: 50, height: 50, fit: BoxFit.cover)
                                : const Icon(Icons.fastfood),
                            title: Text(recipe["title"] ?? "No Title"),
                            onTap: () {
                              // When a recipe is selected, prefill the form with its details.
                              _populateRecipeDetails(recipe["id"]);
                            },
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
              const SizedBox(height: 20),

              // --- MANUAL RECIPE ENTRY SECTION ---
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
                      : _selectedImage!.startsWith("http")
                          ? Image.network(_selectedImage!, fit: BoxFit.cover)
                          : Image.file(File(_selectedImage!), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Recipe Name", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _nameController, decoration: const InputDecoration(border: OutlineInputBorder())),
              const SizedBox(height: 10),
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
              const Text("Enter a short description", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _descriptionController, decoration: const InputDecoration(border: OutlineInputBorder())),
              const SizedBox(height: 10),
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
