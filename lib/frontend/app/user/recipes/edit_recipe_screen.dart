import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../backend/entities/recipes.dart';
import '../../../../backend/controllers/edit_recipe_controller.dart';
import '../../../../backend/entities/extended_ingredient.dart';
import '../../../../backend/entities/analyzed_instruction.dart';
import '../../../../backend/entities/nutrition.dart';
import '../../../../backend/api/spoonacular_service.dart';

class EditRecipeScreen extends StatefulWidget {
  final int recipeId;
  const EditRecipeScreen({super.key, required this.recipeId});

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final EditRecipeController _controller;
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

  final Map<int, bool> _expandedIngredients = {};
  final Map<int, bool> _showSuggestions = {};
  final Map<int, bool> _editingNutrition = {};
  final Map<int, TextEditingController> _ingredientNameControllers = {};

  @override
  void initState() {
    super.initState();
    _controller = EditRecipeController(
      Supabase.instance.client,
      SpoonacularService(),
      widget.recipeId,
    )..loadRecipe();

    _titleController = TextEditingController();
    _servingsController = TextEditingController();
    _readyInController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _servingsController.dispose();
    _readyInController.dispose();
    for (final c in _ingredientNameControllers.values){
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _availableDietOptions =>
      _allDietOptions.where((d) => !_controller.diets.contains(d)).toList();

  List<String> get _availableDishTypeOptions =>
      _allDishTypeOptions.where((t) => !_controller.dishTypes.contains(t)).toList();

  bool get _isFormValid {
    return _titleController.text.isNotEmpty &&
        _servingsController.text.isNotEmpty &&
        int.tryParse(_servingsController.text) != null &&
        _readyInController.text.isNotEmpty &&
        int.tryParse(_readyInController.text) != null &&
        _controller.extendedIngredients.isNotEmpty &&
        _controller.extendedIngredients.every((i) => i.name.isNotEmpty && i.amount > 0) &&
        _controller.analyzedInstructions.isNotEmpty &&
        _controller.analyzedInstructions.first.steps.isNotEmpty &&
        _controller.analyzedInstructions.first.steps.every((s) => s.step.isNotEmpty);
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        await _controller.updateRecipeImage(widget.recipeId, image);
      }
    } catch (e) {
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<EditRecipeController>(
        builder: (ctx, controller, _) {
          // initialize fields once loaded
          if (!controller.isLoading) {
            _titleController.text = controller.title;
            _servingsController.text = controller.servings.toString();
            _readyInController.text = controller.readyInMinutes.toString();
          }

          if (controller.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (controller.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(ctx)
                  .showSnackBar(SnackBar(content: Text(controller.error!)));
              controller.clearError.call();
            });
          }

          return WillPopScope(
            onWillPop: () async => true,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Edit Recipe', style: TextStyle(fontWeight: FontWeight.bold)),
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

                      // Basic Information
                      _buildSectionHeader('Basic Information'),
                      _buildInputHeader('Recipe Title'),
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration(hintText: 'Enter recipe title')
                            .copyWith(errorText: _validateTitle(_titleController.text)),
                        validator: _validateTitle,
                        onChanged: (v) {
                          setState(() {});
                          controller.setTitle(v);
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
                                      .copyWith(errorText: _validateServings(_servingsController.text)),
                                  keyboardType: TextInputType.number,
                                  validator: _validateServings,
                                  onChanged: (v) {
                                    setState(() {});
                                    controller.setServings(int.tryParse(v) ?? 0);
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
                                      .copyWith(errorText: _validateReadyIn(_readyInController.text)),
                                  keyboardType: TextInputType.number,
                                  validator: _validateReadyIn,
                                  onChanged: (v) {
                                    setState(() {});
                                    controller.setReadyInMinutes(int.tryParse(v) ?? 0);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Dietary Information
                      Row(
                        children: [
                          _buildSectionHeader('Dietary Information'),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _availableDietOptions.isNotEmpty
                                ? () => _showAddTagDialog(
                                      context: ctx,
                                      title: 'Add Dietary Tag',
                                      options: _availableDietOptions,
                                      onAdd: controller.addDiet,
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

                      // Dish Types
                      Row(
                        children: [
                          _buildSectionHeader('Dish Types'),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _availableDishTypeOptions.isNotEmpty
                                ? () => _showAddTagDialog(
                                      context: ctx,
                                      title: 'Add Dish Type Tag',
                                      options: _availableDishTypeOptions,
                                      onAdd: controller.addDishType,
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

                      // Nutrition Information
                      _buildSectionHeader('Nutrition Information'),
                      const SizedBox(height: 8),
                      _buildNutritionSummary(controller),
                      const SizedBox(height: 24),

                      // Ingredients
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
                            _buildIngredientCard(i, controller),
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

                      // Instructions
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
                            _buildInstructionCard(i, controller),
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
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                final updatedRecipe = await controller.updateRecipe();
                                if (context.mounted){
                                  Navigator.of(context).pop<Recipes>(updatedRecipe);
                                }
                              } catch (e) {
                                // show error in-place if something goes wrong
                                if (context.mounted){
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to save changes: $e')),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFormValid ? Colors.green : Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save Changes',
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
        },
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recipe Image'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: (_controller.image != null)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _controller.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    ),
                  )
                : _buildPlaceholderImage(),
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

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _buildInputHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
      );

  InputDecoration _inputDecoration({String? hintText, String? labelText}) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildNutritionSummary(EditRecipeController c) {
    final nut = c.calculateTotalNutrition();
    final servings = c.servings > 0 ? c.servings : 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          const Text('Nutrition Information (per serving)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNutritionSummaryItem('Calories', _formatNutrient(nut.nutrients, ['calories'], 'kcal', servings)),
              _buildNutritionSummaryItem('Protein', _formatNutrient(nut.nutrients, ['protein'], 'g', servings)),
              _buildNutritionSummaryItem('Fat', _formatNutrient(nut.nutrients, ['fat'], 'g', servings)),
              _buildNutritionSummaryItem('Carbs', _formatNutrient(nut.nutrients, ['carbohydrates','carb'], 'g', servings)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
           // Detailed Nutrients
          _buildNutritionRow('Saturated Fat', 
            _formatNutrient(nut.nutrients, ['saturated fat'], 'g', servings)),
          _buildNutritionRow('Cholesterol', 
            _formatNutrient(nut.nutrients, ['cholesterol'], 'mg', servings)),
          _buildNutritionRow('Sodium', 
            _formatNutrient(nut.nutrients, ['sodium'], 'mg', servings)),
          _buildNutritionRow('Fiber', 
            _formatNutrient(nut.nutrients, ['fiber', 'dietary fiber'], 'g', servings)),
          _buildNutritionRow('Sugar', 
            _formatNutrient(nut.nutrients, ['sugar', 'total sugars'], 'g', servings)),
          _buildNutritionRow('Vitamin D', 
            _formatNutrient(nut.nutrients, ['vitamin d'], 'mcg', servings)),
          _buildNutritionRow('Calcium', 
            _formatNutrient(nut.nutrients, ['calcium'], 'mg', servings)),
          _buildNutritionRow('Iron', 
            _formatNutrient(nut.nutrients, ['iron'], 'mg', servings)),
          _buildNutritionRow('Potassium', 
            _formatNutrient(nut.nutrients, ['potassium'], 'mg', servings)),
          _buildNutritionRow('Vitamin A', 
            _formatNutrient(nut.nutrients, ['vitamin a'], 'mcg', servings)),
          _buildNutritionRow('Vitamin C', 
            _formatNutrient(nut.nutrients, ['vitamin c'], 'mg', servings)),
          
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

  String _formatNutrient(List<Nutrient> list, List<String> keys, String unit, int servings) {
    final nutrient = list.firstWhere(
      (n) => keys.any((k) => n.title.toLowerCase().contains(k)),
      orElse: () => Nutrient(title: '', amount: 0, unit: unit),
    );
    final amt = nutrient.amount;
    if (amt > 0) {
      final per = amt / servings;
      return '${per.toStringAsFixed(1)} $unit';
    }
    return '--';
  }

  Widget _buildNutritionSummaryItem(String label, String value) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );

  void _addIngredient() {
    final idx = _controller.extendedIngredients.length;
    _controller.addExtendedIngredient(ExtendedIngredient(
      id: DateTime.now().millisecondsSinceEpoch,
      name: '', amount: 0, unit: 'g',
    ));
    _ingredientNameControllers[idx] = TextEditingController();
    setState(() {});
  }

  void _removeIngredient(int i) {
    _ingredientNameControllers[i]?.dispose();
    _ingredientNameControllers.remove(i);
    _controller.removeExtendedIngredient(i);
    setState(() {
      _expandedIngredients.remove(i);
      _showSuggestions.remove(i);
      _editingNutrition.remove(i);
    });
  }

  Widget _buildIngredientCard(int index, EditRecipeController controller) {
    final ingredient = controller.extendedIngredients[index];
    final isLoading = controller.loadingIngredientInfo[index] ?? false;
    final isExp = _expandedIngredients[index] ?? false;
    final nameCtrl = _ingredientNameControllers[index] ?? (_ingredientNameControllers[index] = TextEditingController(text: ingredient.name));

    return Card(
      margin: const EdgeInsets.only(bottom: 12), elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildIngredientNameField(index, ingredient, controller),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _removeIngredient(index)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Amount', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      TextFormField(
                        key: ValueKey('amount_${ingredient.id}'),
                        initialValue: ingredient.amount > 0 ? ingredient.amount.toString() : '',
                        decoration: InputDecoration(
                          hintText: '0.0', errorText: ingredient.amount <= 0 ? 'Please enter amount' : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[400]!)),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (v) {
                          final amt = double.tryParse(v) ?? 0;
                          controller.updateIngredientAmountAndUnit(index, amt, ingredient.unit);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Unit', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(10)),
                        child: DropdownButton<String>(
                          value: ingredient.unit, isExpanded: true, underline: const SizedBox(),
                          items: ingredient.possibleUnits.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (u) {
                            if (u != null) controller.updateIngredientAmountAndUnit(index, ingredient.amount, u);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: IconButton(
                    icon: Icon(isExp ? Icons.expand_less : Icons.expand_more, size: 20),
                    onPressed: () => setState(() => _expandedIngredients[index] = !isExp),
                  ),
                ),
              ],
            ),
            if (isExp) ...[
              const SizedBox(height: 12),
              _buildNutritionInfo(index, ingredient, controller),
            ],
            if (isLoading) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientNameField(int index, ExtendedIngredient ingredient, EditRecipeController controller) {
    final suggestions = controller.ingredientSuggestions[index] ?? [];
    final showSug = _showSuggestions[index] ?? false;
    final textCtrl = _ingredientNameControllers[index]!;

    return SizedBox(
      height: showSug ? 300 : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TextFormField(
            controller: textCtrl,
            decoration: InputDecoration(
              hintText: 'Enter ingredient name',
              errorText: ingredient.name.isEmpty ? 'Please enter name' : null,
              suffixIcon: controller.loadingIngredientInfo[index] == true
                  ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
            ),
            onChanged: (v) {
              controller.searchIngredients(v, index);
              setState(() => _showSuggestions[index] = v.isNotEmpty);
            },
          ),
          if (showSug && suggestions.isNotEmpty)
            Positioned(
              top: 60, left: 0, right: 0,
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: suggestions.length,
                          itemBuilder: (ctx,i) {
                            final s = suggestions[i];
                            return ListTile(
                              leading: s['image'] != null
                                  ? SizedBox(width: 40, height: 40, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(s['image'], fit: BoxFit.cover)))
                                  : const Icon(Icons.fastfood),
                              title: Text(s['name'] ?? ''),
                              onTap: () {
                                controller.selectIngredient(s, index);
                                textCtrl.text = s['name'] ?? '';
                                setState(() => _showSuggestions[index] = false);
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      TextButton.icon(onPressed: () => controller.loadMoreIngredients(index), icon: const Icon(Icons.add, size: 18), label: const Text('Load More'))
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNutritionInfo(int index, ExtendedIngredient ingredient, EditRecipeController controller) {
    final nutrition = ingredient.nutrition;
    if (nutrition == null) {
      return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: const Text('No nutrition data available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nutrition Facts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
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
              _buildNutritionRow('Vitamin D', _getNutrientValue(nutrition, ['vitamin d'], 'mcg')),
              _buildNutritionRow('Calcium', _getNutrientValue(nutrition, ['calcium'], 'mg')),
              _buildNutritionRow('Iron', _getNutrientValue(nutrition, ['iron'], 'mg')),
              _buildNutritionRow('Potassium', _getNutrientValue(nutrition, ['potassium'], 'mg')),
              _buildNutritionRow('Vitamin A', _getNutrientValue(nutrition, ['vitamin a'], 'mcg')),
              _buildNutritionRow('Vitamin C', _getNutrientValue(nutrition, ['vitamin c'], 'mg')),
            ],
          ),
        ),
        TextButton(onPressed: () => setState(() => _editingNutrition[index] = true), child: const Text('I want to edit the nutrition facts')),
        if (_editingNutrition[index] == true) _buildEditableNutritionInfo(index, ingredient),
      ],
    );
  }

  String _getNutrientValue(Nutrition nutrition, List<String> keys, String defaultUnit) {
    final nutrient = nutrition.nutrients.firstWhere((n) => keys.any((k) => n.title.toLowerCase().contains(k)), orElse: () => Nutrient(title: '', amount: 0, unit: defaultUnit));
    return nutrient.amount > 0 ? '${nutrient.amount.toStringAsFixed(1)} $defaultUnit' : '--';
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEditableNutritionInfo(int index, ExtendedIngredient ingredient) {
    final nutrition = ingredient.nutrition!;
    final displayNutrients = nutrition.nutrients.where((n) {
      final key = n.title.toLowerCase();
      return ['calories','protein','fat','carbohydrate','carb','saturated fat','cholesterol','sodium','fiber','dietary fiber','sugar','total sugars','vitamin d','calcium','iron','potassium','vitamin a','vitamin c']
          .any((k) => key.contains(k));
    }).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Nutrition Facts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
          const SizedBox(height: 8),
          ...displayNutrients.map((n) {
            final ctrl = TextEditingController(text: n.amount.toString());
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(n.title, style: TextStyle(color: Colors.grey[600])),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: ctrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(suffixText: n.unit, border: const OutlineInputBorder()),
                      onChanged: (v) {
                        final amt = double.tryParse(v) ?? 0;
                        displayNutrients[displayNutrients.indexOf(n)] = n.copyWith(amount: amt);
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 16),
          ElevatedButton(
            onPressed: () {
              final updated = ingredient.nutrition!.copyWith(nutrients: displayNutrients);
              final updatedIng = ingredient.copyWith(nutrition: updated);
              _controller.replaceIngredient(index, updatedIng);
              setState(() => _editingNutrition.remove(index));
            },
            child: const Text('Save Nutrition Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard(int index, EditRecipeController controller) {
    final instr = controller.analyzedInstructions.firstOrNull;
    if (instr == null || index >= instr.steps.length) return const SizedBox();
    final step = instr.steps[index];
    final tc = TextEditingController(text: step.step);

    return Card(
      margin: const EdgeInsets.only(bottom: 12), elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(radius: 12, backgroundColor: Colors.green[100], child: Text('${index+1}', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: tc,
                maxLines: 3, minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Describe step ${index+1}',
                  border: InputBorder.none,
                  errorText: step.step.isEmpty ? 'Please enter instruction' : null,
                ),
                onChanged: (v) {
                  final newSteps = List<InstructionStep>.from(instr.steps);
                  newSteps[index] = step.copyWith(step: v);
                  controller.setAnalyzedInstructions([instr.copyWith(steps: newSteps)]);
                },
              ),
            ),
            IconButton(icon: const Icon(Icons.remove_circle, color: Colors.redAccent), onPressed: () => _removeInstruction(index)),
          ],
        ),
      ),
    );
  }

  void _addInstruction() {
    if (_controller.analyzedInstructions.isEmpty) {
      _controller.setAnalyzedInstructions([
        AnalyzedInstruction(name: 'Main instructions', steps: [InstructionStep(number: 1, step: '')])
      ]);
    } else {
      final steps = List<InstructionStep>.from(_controller.analyzedInstructions.first.steps);
      steps.add(InstructionStep(number: steps.length+1, step: ''));
      _controller.setAnalyzedInstructions([
        _controller.analyzedInstructions.first.copyWith(steps: steps)
      ]);
    }
  }

  void _removeInstruction(int index) {
    final instr = _controller.analyzedInstructions.first;
    final steps = List<InstructionStep>.from(instr.steps)..removeAt(index);
    for (var i = index; i < steps.length; i++) {
      steps[i] = steps[i].copyWith(number: i+1);
      _controller.setAnalyzedInstructions([instr.copyWith(steps: steps)]);
    }
  }

  void _showAddTagDialog({required BuildContext context, required String title, required List<String> options, required Function(String) onAdd}) {
    String? selectedTag;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(title),
              content: DropdownButtonFormField<String>(
                value: selectedTag,
                items: options.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                onChanged: (v) => setState(() => selectedTag = v),
                decoration: const InputDecoration(labelText: 'Select a tag', border: OutlineInputBorder()),
              ),
              actions: [
                TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
                TextButton(child: const Text('Add'), onPressed: () {
                  if (selectedTag != null) { onAdd(selectedTag!); Navigator.of(ctx).pop(); }
                }),
              ],
            );
          },
        );
      },
    );
  }
}
