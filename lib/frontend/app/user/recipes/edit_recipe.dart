import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../backend/controller/edit_recipe_controller.dart';
import '../../../../backend/state/recipe_state.dart';

class EditRecipeScreen extends StatefulWidget {
  final String recipeId;

  const EditRecipeScreen({super.key, required this.recipeId});

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Recipe", 
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: const _EditRecipeContent(),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: const Text('Are you sure you want to delete this recipe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<EditRecipeController>(context, listen: false)
            .deleteRecipe(widget.recipeId);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete recipe: $e')),
          );
        }
      }
    }
  }
}

class _EditRecipeContent extends StatefulWidget {
  const _EditRecipeContent();

  @override
  State<_EditRecipeContent> createState() => _EditRecipeContentState();
}

class _EditRecipeContentState extends State<_EditRecipeContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecipe();
    });
  }

  Future<void> _loadRecipe() async {
    try {
      await Provider.of<EditRecipeController>(context, listen: false)
          .loadRecipe(Provider.of<EditRecipeScreen>(context, listen: false).recipeId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recipe: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<RecipeState>(context);
    final controller = Provider.of<EditRecipeController>(context);
    final recipeId = Provider.of<EditRecipeScreen>(context, listen: false).recipeId;

    if (state.titleController.text.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: state.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(context, state),
            const SizedBox(height: 24),
            _buildBasicInfoSection(state),
            const SizedBox(height: 24),
            _buildDietTagsSection(context, state, controller),
            const SizedBox(height: 24),
            _buildNutritionSection(state),
            const SizedBox(height: 24),
            _buildIngredientsSection(context, state, controller),
            const SizedBox(height: 24),
            _buildInstructionsSection(context, state, controller),
            const SizedBox(height: 24),
            _buildUpdateButton(context, controller, recipeId),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, RecipeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recipe Image", style: _sectionTitleStyle()),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(context, state),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: state.selectedImage != null
                ? _buildNetworkImage(state.selectedImage!)
                : _buildImagePlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageError(),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, size: 50, color: Colors.black54),
            SizedBox(height: 8),
            Text("Image failed to load", style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_a_photo, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text("Add Recipe Image", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(RecipeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 8),
            Text(
              "Basic Recipe Information",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "Recipe Title",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: state.titleController,
          decoration: _inputDecoration(hintText: "Enter recipe title"),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Servings",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: state.servingsController,
                    decoration: _inputDecoration(hintText: "Enter Servings"),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ready In (Minutes)",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: state.readyInMinutesController,
                    decoration: _inputDecoration(hintText: "Enter Time"),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "Dish Type",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: state.selectedDishType,
          decoration: _inputDecoration(hintText: "Select dish type"),
          items: state.dishTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) => state.selectedDishType = value,
          validator: (value) => value == null ? 'Please select a dish type' : null,
        ),
      ],
    );
  }

  Widget _buildDietTagsSection(BuildContext context, RecipeState state, EditRecipeController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Diet Tags", style: _sectionTitleStyle()),
            const Spacer(),
            TextButton.icon(
              onPressed: controller.addDietTag,
              icon: const Icon(Icons.add, size: 18, color: Colors.green),
              label: const Text("Add Tag", style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < state.dietTags.length; i++)
              InputChip(
                label: Text(state.dietTags[i].text.isEmpty 
                    ? "New tag" 
                    : state.dietTags[i].text),
                onPressed: () => _showEditTagDialog(context, state, i),
                deleteIcon: const Icon(Icons.cancel, size: 18),
                onDeleted: () => controller.removeDietTag(i),
              ),
          ],
        ),
      ],
    );
  }

  void _showEditTagDialog(BuildContext context, RecipeState state, int index) {
    final tagController = TextEditingController(text: state.dietTags[index].text);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Diet Tag"),
          content: TextField(
            controller: tagController,
            decoration: const InputDecoration(
              hintText: "e.g. Vegetarian, Gluten-Free",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                state.dietTags[index].text = tagController.text;
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNutritionSection(RecipeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Nutrition Information", style: _sectionTitleStyle()),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              TextField(
                controller: state.caloriesController,
                decoration: _inputDecoration(
                  labelText: "Calories",
                  suffixText: "kcal",
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: state.proteinController,
                        decoration: _inputDecoration(
                          labelText: "Protein",
                          suffixText: "g",
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: state.carbsController,
                        decoration: _inputDecoration(
                          labelText: "Carbs",
                          suffixText: "g",
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: state.fatsController,
                        decoration: _inputDecoration(
                          labelText: "Fats",
                          suffixText: "g",
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection(BuildContext context, RecipeState state, EditRecipeController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Ingredients", style: _sectionTitleStyle()),
            const Spacer(),
            TextButton.icon(
              onPressed: controller.addIngredient,
              icon: const Icon(Icons.add, size: 18, color: Colors.green),
              label: const Text("Add Ingredient", style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            for (int i = 0; i < state.ingredients.length; i++)
              _buildIngredientCard(context, state.ingredients[i], i, controller),
          ],
        ),
      ],
    );
  }

  Widget _buildIngredientCard(BuildContext context, IngredientState ingredient, int index, EditRecipeController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ingredient.nameController,
                    decoration: _inputDecoration(hintText: "Ingredient name"),
                    onChanged: (value) async {
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (value == ingredient.nameController.text) {
                        await controller.searchIngredients(ingredient);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove_circle, size: 24, color: Colors.red),
                  onPressed: () => controller.removeIngredient(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: ingredient.measurementController,
                    decoration: _inputDecoration(hintText: "Amount"),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      ingredient.amount = double.tryParse(value) ?? 0;
                      if (ingredient.ingredientId != null && ingredient.amount > 0) {
                        controller.calculateIngredientNutrition(ingredient);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: ingredient.selectedUnit,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: ingredient.availableUnits.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ingredient.selectedUnit = value;
                          if (ingredient.ingredientId != null && ingredient.amount > 0) {
                            controller.calculateIngredientNutrition(ingredient);
                          }
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(
                      ingredient.isExpanded 
                          ? Icons.keyboard_arrow_up 
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      ingredient.isExpanded = !ingredient.isExpanded;
                      Provider.of<RecipeState>(context, listen: false).notifyListeners();
                    },
                  ),
                ),
              ],
            ),
            if (ingredient.isExpanded) _buildNutritionDetails(context, ingredient),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionDetails(BuildContext context, IngredientState ingredient) {
    final state = Provider.of<RecipeState>(context, listen: false);
    
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text("Nutrition Details", style: _subsectionTitleStyle()),
          const SizedBox(height: 12),
          TextField(
            controller: ingredient.caloriesController,
            decoration: _inputDecoration(
              labelText: "Calories",
              suffixText: "kcal",
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => state.updateNutritionTotals(),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ingredient.proteinController,
                    decoration: _inputDecoration(
                      labelText: "Protein",
                      suffixText: "g",
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => state.updateNutritionTotals(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: ingredient.carbsController,
                    decoration: _inputDecoration(
                      labelText: "Carbs",
                      suffixText: "g",
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => state.updateNutritionTotals(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: ingredient.fatsController,
                    decoration: _inputDecoration(
                      labelText: "Fats",
                      suffixText: "g",
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => state.updateNutritionTotals(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection(BuildContext context, RecipeState state, EditRecipeController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Instructions", style: _sectionTitleStyle()),
            const Spacer(),
            TextButton.icon(
              onPressed: controller.addInstruction,
              icon: const Icon(Icons.add, size: 18, color: Colors.green),
              label: const Text("Add Step", style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            for (int i = 0; i < state.instructions.length; i++)
              _buildInstructionCard(context, state.instructions[i], i, controller),
          ],
        ),
      ],
    );
  }

  Widget _buildInstructionCard(BuildContext context, TextEditingController instruction, int index, EditRecipeController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.green[100],
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: instruction,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: "Describe step ${index + 1}",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                  onPressed: () => controller.removeInstruction(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton(BuildContext context, EditRecipeController controller, String recipeId) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            await controller.updateRecipe(recipeId);
            if (context.mounted) Navigator.pop(context);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update recipe: $e')),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          "Update Recipe", 
          style: TextStyle(
            fontSize: 16, 
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, RecipeState state) async {
    // TODO: Implement image picking functionality
    state.selectedImage = 'https://via.placeholder.com/400x300';
    state.notifyListeners();
  }

  // Helper methods for styling
  TextStyle _sectionTitleStyle() {
    return TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.grey[800],
    );
  }

  TextStyle _subsectionTitleStyle() {
    return TextStyle(
      fontWeight: FontWeight.w600,
      color: Colors.grey[700],
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    String? labelText,
    String? suffixText,
    bool filled = false,
    Color? fillColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      suffixText: suffixText,
      filled: filled,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}