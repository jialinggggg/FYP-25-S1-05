import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../backend/controllers/add_recipe_controller.dart';
import '../../../../backend/entities/extended_ingredient.dart';
import '../../../../backend/entities/analyzed_instruction.dart';
import '../../../../backend/entities/nutrition.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _servingsController;
  late final TextEditingController _readyInController;
  
  final List<String> _allDietOptions = [
    'Vegetarian', 'Vegan', 'Gluten Free', 'Dairy Free', 
    'Nut Free', 'Low Carb', 'High Protein'
  ];
  final List<String> _allDishTypeOptions = [
    'Breakfast', 'Lunch', 'Dinner', 'Snack', 
    'Dessert', 'Appetizer', 'Main Course', 'Side Dish'
  ];

  bool _imageError = false;
  final Map<int, bool> _expandedIngredients = {};
  final Map<int, bool> _showSuggestions = {};
  final Map<int, bool> _editingNutrition = {};
  final Map<int, TextEditingController> _ingredientNameControllers = {};


  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _servingsController = TextEditingController();
    _readyInController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<AddRecipeController>(context, listen: false);
      controller.clearState();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _servingsController.dispose();
    _readyInController.dispose();
    for (final controller in _ingredientNameControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> get _availableDietOptions {
    final controller = Provider.of<AddRecipeController>(context, listen: false);
    return _allDietOptions.where((diet) => !controller.diets.contains(diet)).toList();
  }

  List<String> get _availableDishTypeOptions {
    final controller = Provider.of<AddRecipeController>(context, listen: false);
    return _allDishTypeOptions.where((type) => !controller.dishTypes.contains(type)).toList();
  }

  bool get _isFormValid {
    final controller = Provider.of<AddRecipeController>(context, listen: false);
    return _titleController.text.isNotEmpty &&
        _servingsController.text.isNotEmpty &&
        int.tryParse(_servingsController.text) != null &&
        _readyInController.text.isNotEmpty &&
        int.tryParse(_readyInController.text) != null &&
        controller.extendedIngredients.isNotEmpty &&
        controller.extendedIngredients.every((i) => i.name.isNotEmpty && i.amount > 0) &&
        controller.analyzedInstructions.isNotEmpty &&
        controller.analyzedInstructions.first.steps.isNotEmpty &&
        controller.analyzedInstructions.first.steps.every((s) => s.step.isNotEmpty);
  }

  String? _validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a title';
    }
    return null;
  }

  String? _validateServings(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter servings';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  String? _validateReadyIn(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter time';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

   void _toggleIngredientExpansion(int index) {
    setState(() {
      _expandedIngredients[index] = !(_expandedIngredients[index] ?? false);
    });
  }

   Widget _buildImageSection() {
    final controller = Provider.of<AddRecipeController>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recipe Image', style: _sectionTitleStyle()),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(controller),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: controller.image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      controller.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    ),
                  )
                : _buildPlaceholderImage(),
          ),
        ),
        // show error text if image is still null when flagged
        if (_imageError && controller.image == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please upload a recipe image',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_a_photo, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text('Add Recipe Image', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _pickImage(AddRecipeController controller) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        if (controller.recipe != null) {
          // Updating existing recipe
          await controller.updateRecipeImage(controller.recipe!.id, image);
        } else {
          // Creating new recipe
          await controller.uploadRecipeImage(image);
        }
      }
    } catch (e) {
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
        );
      }
    }
  }

  String _getNutrientValue(Nutrition nutrition, List<String> keys, String defaultUnit) {
    final nutrient = nutrition.nutrients.firstWhere(
      (n) => keys.any((key) => n.title.toLowerCase().contains(key)),
      orElse: () => Nutrient(title: '', amount: 0, unit: defaultUnit),
    );
    
    final amount = nutrient.amount;
    final unit = nutrient.unit;
    
    return amount > 0 
      ? '${amount.toStringAsFixed(1)} $unit'
      : '--';
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNutritionSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionSummary() {
    final controller = Provider.of<AddRecipeController>(context, listen: false);
    final servings = int.tryParse(_servingsController.text) ?? 1;
    
    // Calculate all nutrients
    final Map<String, double> nutrientTotals = {};
    
    for (final ingredient in controller.extendedIngredients) {
      if (ingredient.nutrition != null) {
        for (final nutrient in ingredient.nutrition!.nutrients) {
          final key = nutrient.title.toLowerCase();
          nutrientTotals.update(
            key,
            (value) => value + nutrient.amount,
            ifAbsent: () => nutrient.amount,
          );
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            'Nutrition Information (per serving)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          
          // Macronutrients
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNutritionSummaryItem('Calories', 
                _formatNutrient(nutrientTotals, ['calories'], 'kcal', servings)),
              _buildNutritionSummaryItem('Protein', 
                _formatNutrient(nutrientTotals, ['protein'], 'g', servings)),
              _buildNutritionSummaryItem('Carbs', 
                _formatNutrient(nutrientTotals, ['carbohydrates', 'carb'], 'g', servings)),
              _buildNutritionSummaryItem('Fat', 
                _formatNutrient(nutrientTotals, ['fat'], 'g', servings)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          
          // Detailed Nutrients
          _buildNutritionRow('Saturated Fat', 
            _formatNutrient(nutrientTotals, ['saturated fat'], 'g', servings)),
          _buildNutritionRow('Cholesterol', 
            _formatNutrient(nutrientTotals, ['cholesterol'], 'mg', servings)),
          _buildNutritionRow('Sodium', 
            _formatNutrient(nutrientTotals, ['sodium'], 'mg', servings)),
          _buildNutritionRow('Fiber', 
            _formatNutrient(nutrientTotals, ['fiber', 'dietary fiber'], 'g', servings)),
          _buildNutritionRow('Sugar', 
            _formatNutrient(nutrientTotals, ['sugar', 'total sugars'], 'g', servings)),
          _buildNutritionRow('Vitamin D', 
            _formatNutrient(nutrientTotals, ['vitamin d'], 'mcg', servings)),
          _buildNutritionRow('Calcium', 
            _formatNutrient(nutrientTotals, ['calcium'], 'mg', servings)),
          _buildNutritionRow('Iron', 
            _formatNutrient(nutrientTotals, ['iron'], 'mg', servings)),
          _buildNutritionRow('Potassium', 
            _formatNutrient(nutrientTotals, ['potassium'], 'mg', servings)),
          _buildNutritionRow('Vitamin A', 
            _formatNutrient(nutrientTotals, ['vitamin a'], 'mcg', servings)),
          _buildNutritionRow('Vitamin C', 
            _formatNutrient(nutrientTotals, ['vitamin c'], 'mg', servings)),
          
          const SizedBox(height: 8),
          Text(
            'Based on $servings ${servings == 1 ? 'serving' : 'servings'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNutrient(Map<String, double> nutrientTotals, List<String> keys, String unit, int servings) {
    double amount = 0;
    for (final key in keys) {
      if (nutrientTotals.containsKey(key)) {
        amount += nutrientTotals[key]!;
        break;
      }
    }
    
    final perServing = amount / servings;
    return perServing > 0 ? '${perServing.toStringAsFixed(1)} $unit' : '--';
  }

  Widget _buildIngredientNameField(int index, ExtendedIngredient ingredient) {
    final controller = Provider.of<AddRecipeController>(context);
    final suggestions = controller.getIngredientSuggestions(index);
    final showSuggestions = _showSuggestions[index] ?? false;

    // Initialize controller if not exists
    if (!_ingredientNameControllers.containsKey(index)) {
      _ingredientNameControllers[index] = TextEditingController(text: ingredient.name);
    }
    final textController = _ingredientNameControllers[index]!;

    return SizedBox(
      height: showSuggestions ? 300 : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TextFormField(
            controller: textController,
            decoration: InputDecoration(
              hintText: 'Enter ingredient name',
              errorText: ingredient.name.isEmpty ? 'Please enter name' : null,
              suffixIcon: controller.isLoadingIngredientInfo(index)
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            onChanged: (value) {
              // Update the ingredient name directly
              final newIngredients = List<ExtendedIngredient>.from(controller.extendedIngredients);
              newIngredients[index] = ingredient.copyWith(name: value);
              controller.setExtendedIngredients(newIngredients);
              
              controller.searchIngredients(value, index);
              setState(() {
                _showSuggestions[index] = value.isNotEmpty;
              });
            },
          ),
          if (showSuggestions && suggestions.isNotEmpty)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: suggestions.length,
                          itemBuilder: (context, i) {
                            final suggestion = suggestions[i];
                            return ListTile(
                              leading: suggestion['image'] != null
                                  ? SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          suggestion['image'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => 
                                            const Icon(Icons.fastfood),
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.fastfood),
                              title: Text(suggestion['name'] ?? ''),
                              onTap: () {
                                controller.selectIngredient(suggestion, index);
                                // Update both the controller and the ingredient
                                textController.text = suggestion['name'] ?? '';
                                final newIngredients = List<ExtendedIngredient>.from(controller.extendedIngredients);
                                newIngredients[index] = ingredient.copyWith(name: suggestion['name'] ?? '');
                                controller.setExtendedIngredients(newIngredients);
                                setState(() {
                                  _showSuggestions[index] = false;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      TextButton.icon(
                        onPressed: () => controller.loadMoreIngredients(index),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Load More'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditableNutritionInfo(int index, ExtendedIngredient ingredient) {
    final nutrition = ingredient.nutrition;
    if (nutrition == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('No nutrition data available'),
      );
    }

    // Create a list of only the nutrients we want to display and edit
    final displayNutrients = [
      ...nutrition.nutrients.where((n) => [
        'calories', 'protein', 'fat', 'carbohydrate', 'carb',
        'saturated fat', 'cholesterol', 'sodium',
        'fiber', 'dietary fiber', 'sugar', 'total sugars',
        'vitamin d', 'calcium', 'iron', 'potassium',
        'vitamin a', 'vitamin c'
      ].any((key) => n.title.toLowerCase().contains(key)))
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Nutrition Facts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildEditableNutrientRows(displayNutrients),
          const Divider(height: 16),
          ElevatedButton(
            onPressed: () {
              // Create new nutrition with original nutrients but updated values
              final updatedNutrients = nutrition.nutrients.map((original) {
                final updated = displayNutrients.firstWhere(
                  (n) => n.title == original.title,
                  orElse: () => original,
                );
                return updated;
              }).toList();
              
              final updatedNutrition = Nutrition(nutrients: updatedNutrients);
              final updatedIngredient = ingredient.copyWith(nutrition: updatedNutrition);
              
              final controller = Provider.of<AddRecipeController>(context, listen: false);
              final newIngredients = List<ExtendedIngredient>.from(controller.extendedIngredients);
              newIngredients[index] = updatedIngredient;
              controller.setExtendedIngredients(newIngredients);
              
              setState(() {
                _editingNutrition[index] = false;
              });
            },
            child: const Text('Save Nutrition Data'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEditableNutrientRows(List<Nutrient> nutrients) {
    return nutrients.asMap().entries.map((entry) {
      final index = entry.key;
      final nutrient = entry.value;
      final controller = TextEditingController(text: nutrient.amount.toString());
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(nutrient.title, style: TextStyle(color: Colors.grey[600])),
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  suffixText: nutrient.unit,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (index >= 0 && index < nutrients.length) {
                    final newAmount = double.tryParse(value) ?? 0;
                    nutrients[index] = nutrient.copyWith(amount: newAmount);
                  }
                },
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildNutritionInfo(int index, ExtendedIngredient ingredient) {
    final isEditing = _editingNutrition[index] ?? false;
    if (isEditing) {
      return _buildEditableNutritionInfo(index, ingredient);
    }

    final nutrition = ingredient.nutrition;
    if (nutrition == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('No nutrition data available'),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nutrition Facts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              _buildNutritionRow('Calories', _getNutrientValue(nutrition, ['calories'], 'kcal')),
              _buildNutritionRow('Protein', _getNutrientValue(nutrition, ['protein'], 'g')),
              _buildNutritionRow('Fat', _getNutrientValue(nutrition, ['fat'], 'g')),
              _buildNutritionRow('Carbs', _getNutrientValue(nutrition, ['carbohydrate', 'carb'], 'g')),
              const Divider(height: 16),
              _buildNutritionRow('Saturated Fat', _getNutrientValue(nutrition, ['saturated fat'], 'g')),
              _buildNutritionRow('Cholesterol', _getNutrientValue(nutrition, ['cholesterol'], 'mg')),
              _buildNutritionRow('Sodium', _getNutrientValue(nutrition, ['sodium'], 'mg')),
              _buildNutritionRow('Fiber', _getNutrientValue(nutrition, ['fiber', 'dietary fiber'], 'g')),
              _buildNutritionRow('Sugar', _getNutrientValue(nutrition, ['sugar', 'total sugars'], 'g')),
              const Divider(height: 16),
              _buildNutritionRow('Vitamin D', _getNutrientValue(nutrition, ['vitamin d'], 'Âµg')),
              _buildNutritionRow('Calcium', _getNutrientValue(nutrition, ['calcium'], 'mg')),
              _buildNutritionRow('Iron', _getNutrientValue(nutrition, ['iron'], 'mg')),
              _buildNutritionRow('Potassium', _getNutrientValue(nutrition, ['potassium'], 'mg')),
              _buildNutritionRow('Vitamin A', _getNutrientValue(nutrition, ['vitamin a'], 'IU')),
              _buildNutritionRow('Vitamin C', _getNutrientValue(nutrition, ['vitamin c'], 'mg')),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _editingNutrition[index] = true;
            });
          },
          child: const Text('I want to edit the nutrition facts'),
        ),
      ],
    );
  }

    Widget _buildIngredientCard(int index) {
    final controller = Provider.of<AddRecipeController>(context);
    final ingredient = controller.extendedIngredients[index];
    final isExpanded = _expandedIngredients[index] ?? false;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ingredient Name Section with Remove button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ingredient Name',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildIngredientNameField(index, ingredient),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _removeIngredient(index),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Amount and Measurement Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Amount Field
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            key: ValueKey('amount_${ingredient.id}'), // Force rebuild when ingredient changes
                            initialValue: ingredient.amount > 0 ? ingredient.amount.toString() : '',
                            decoration: InputDecoration(
                              hintText: '0.0',
                              errorText: ingredient.amount <= 0 ? 'Please enter amount' : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              final amount = double.tryParse(value) ?? 0;
                              controller.updateIngredientAmountAndUnit(
                                index, 
                                amount, 
                                ingredient.unit,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Unit Dropdown
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[400]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButton<String>(
                              value: ingredient.unit,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: ingredient.possibleUnits
                                  .map<DropdownMenuItem<String>>((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(
                                    unit, 
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  controller.updateIngredientAmountAndUnit(
                                    index, 
                                    ingredient.amount, 
                                    value,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Expand/Collapse Button
                    Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                        ),
                        onPressed: () => _toggleIngredientExpansion(index),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Nutrition Info if expanded
            if (isExpanded) ...[
              const SizedBox(height: 12),
              _buildNutritionInfo(index, ingredient),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard(int index) {
    final controller = Provider.of<AddRecipeController>(context);
    final instruction = controller.analyzedInstructions.firstOrNull;
    if (instruction == null || index >= instruction.steps.length) {
      return const SizedBox();
    }
    final step = instruction.steps[index];

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
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Describe step ${index + 1}',
                      border: InputBorder.none,
                      errorText: step.step.isEmpty ? 'Please enter instruction' : null,
                    ),
                    onChanged: (value) {
                      setState(() {});
                      final newSteps = List<InstructionStep>.from(instruction.steps);
                      newSteps[index] = step.copyWith(step: value);
                      controller.setAnalyzedInstructions([
                        instruction.copyWith(steps: newSteps)
                      ]);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                  onPressed: () => _removeInstruction(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInputHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  TextStyle _sectionTitleStyle() {
    return const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.black87,
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

  void _addIngredient() {
    final controller = Provider.of<AddRecipeController>(context, listen: false);
    final newIndex = controller.extendedIngredients.length;
    controller.addExtendedIngredient(ExtendedIngredient(
      id: DateTime.now().millisecondsSinceEpoch,
      name: '',
      amount: 0,
      unit: 'g',
    ));
    _ingredientNameControllers[newIndex] = TextEditingController();
  }

  void _removeIngredient(int index) {
    _ingredientNameControllers[index]?.dispose();
    _ingredientNameControllers.remove(index);
    final controller = Provider.of<AddRecipeController>(context, listen: false);
    controller.removeExtendedIngredient(index);
    setState(() {
      _expandedIngredients.remove(index);
      _showSuggestions.remove(index);
      _editingNutrition.remove(index);
    });
  }

  void _addInstruction() {
    final controller = Provider.of<AddRecipeController>(context, listen: false);
    if (controller.analyzedInstructions.isEmpty) {
      controller.setAnalyzedInstructions([
        AnalyzedInstruction(
          name: 'Main instructions',
          steps: [InstructionStep(number: 1, step: '')],
        )
      ]);
    } else {
      final steps = List<InstructionStep>.from(controller.analyzedInstructions.first.steps);
      steps.add(InstructionStep(number: steps.length + 1, step: ''));
      controller.setAnalyzedInstructions([
        controller.analyzedInstructions.first.copyWith(steps: steps)
      ]);
    }
  }

  void _removeInstruction(int index) {
    final controller = Provider.of<AddRecipeController>(context, listen: false);
    if (controller.analyzedInstructions.isNotEmpty) {
      final steps = List<InstructionStep>.from(controller.analyzedInstructions.first.steps);
      steps.removeAt(index);
      // Renumber remaining steps
      for (var i = index; i < steps.length; i++) {
        steps[i] = steps[i].copyWith(number: i + 1);
      }
      controller.setAnalyzedInstructions([
        controller.analyzedInstructions.first.copyWith(steps: steps)
      ]);
    }
  }

  void _saveRecipe(BuildContext context) {
    final controller = Provider.of<AddRecipeController>(context, listen: false);

    // 1) check image first
    if (controller.image == null) {
      setState(() {
        _imageError = true;
      });
      return;
    } else {
      setState(() {
        _imageError = false;
      });
    }

    if (_formKey.currentState?.validate() ?? false) {
      controller.setServings(int.tryParse(_servingsController.text) ?? 0);
      controller.setReadyInMinutes(int.tryParse(_readyInController.text) ?? 0);
      controller.saveRecipe();
    }
  }

  void _showAddTagDialog({
    required BuildContext context,
    required String title,
    required List<String> options,
    required Function(String) onAdd,
  }) {
    String? selectedTag;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: DropdownButtonFormField<String>(
                value: selectedTag,
                items: options.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTag = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Select a tag',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () {
                    if (selectedTag != null) {
                      onAdd(selectedTag!);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AddRecipeController>(context);

    if (controller.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.error!)),
        );
        controller.setError(null);
      });
    }

    if (controller.recipe != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final saved = controller.recipe!;
        controller.clearState();
        Navigator.pop(context, saved);
      });
    }

    return WillPopScope(
      onWillPop: () async {
        controller.clearState();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add New Recipe', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                _buildImageSection(),
                const SizedBox(height: 24),

                // Basic Information Section
                _buildSectionHeader('Basic Information'),
                _buildInputHeader('Recipe Title'),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(hintText: 'Enter recipe title')
                      .copyWith(errorText: _titleController.text.isEmpty ? 'Please enter a title' : null),
                  validator: _validateTitle,
                  onChanged: (value) {
                    setState(() {});
                    controller.setTitle(value);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputHeader('Servings'),
                          TextFormField(
                            controller: _servingsController,
                            decoration: _inputDecoration(hintText: 'Enter servings')
                                .copyWith(
                                  errorText: _servingsController.text.isEmpty
                                      ? 'Please enter servings'
                                      : int.tryParse(_servingsController.text) == null
                                          ? 'Enter an amount'
                                          : null,
                                ),
                            keyboardType: TextInputType.number,
                            validator: _validateServings,
                            onChanged: (value) {
                              setState(() {});
                              controller.setServings(int.tryParse(value) ?? 0);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputHeader('Ready In (mins)'),
                          TextFormField(
                            controller: _readyInController,
                            decoration: _inputDecoration(hintText: 'Enter time')
                                .copyWith(
                                  errorText: _readyInController.text.isEmpty
                                      ? 'Please enter time'
                                      : int.tryParse(_readyInController.text) == null
                                          ? 'Enter an amount'
                                          : null,
                                ),
                            keyboardType: TextInputType.number,
                            validator: _validateReadyIn,
                            onChanged: (value) {
                              setState(() {});
                              controller.setReadyInMinutes(int.tryParse(value) ?? 0);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Dietary Information Section
                Row(
                  children: [
                    _buildSectionHeader('Dietary Information'),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _availableDietOptions.isNotEmpty 
                          ? () => _showAddTagDialog(
                                context: context,
                                title: 'Add Dietary Tag',
                                options: _availableDietOptions,
                                onAdd: (tag) => controller.addDiet(tag),
                              )
                          : null,
                      icon: const Icon(Icons.add, size: 18, color: Colors.green),
                      label: const Text('Add Tags', style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.diets.map((diet) {
                    return Chip(
                      label: Text(diet),
                      backgroundColor: Colors.green[50],
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => controller.removeDiet(diet),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Dish Types Section
                Row(
                  children: [
                    _buildSectionHeader('Dish Types'),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _availableDishTypeOptions.isNotEmpty
                          ? () => _showAddTagDialog(
                                context: context,
                                title: 'Add Dish Type Tag',
                                options: _availableDishTypeOptions,
                                onAdd: (tag) => controller.addDishType(tag),
                              )
                          : null,
                      icon: const Icon(Icons.add, size: 18, color: Colors.green),
                      label: const Text('Add Tags', style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.dishTypes.map((type) {
                    return Chip(
                      label: Text(type),
                      backgroundColor: Colors.green[50],
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => controller.removeDishType(type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Nutrition Section
                _buildSectionHeader('Nutrition Information'),
                const SizedBox(height: 8),
                _buildNutritionSummary(),
                const SizedBox(height: 24),

                // Ingredients Section
                Row(
                  children: [
                    _buildSectionHeader('Ingredients'),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addIngredient,
                      icon: const Icon(Icons.add, size: 18, color: Colors.green),
                      label: const Text('Add Ingredient', style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    for (int i = 0; i < controller.extendedIngredients.length; i++)
                      _buildIngredientCard(i),
                  ],
                ),
                if (controller.extendedIngredients.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Please add at least one ingredient',
                      style: TextStyle(color: Colors.red[400], fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 24),

                // Instructions Section
                Row(
                  children: [
                    _buildSectionHeader('Instructions'),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addInstruction,
                      icon: const Icon(Icons.add, size: 18, color: Colors.green),
                      label: const Text('Add Step', style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    for (int i = 0; i < (controller.analyzedInstructions.firstOrNull?.steps.length ?? 0); i++)
                      _buildInstructionCard(i),
                  ],
                ),
                if (controller.analyzedInstructions.isEmpty || controller.analyzedInstructions.first.steps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Please add at least one instruction step',
                      style: TextStyle(color: Colors.red[400], fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isFormValid ? () => _saveRecipe(context) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid ? Colors.green : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Recipe',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}