import 'package:flutter/material.dart';

class RecipeState extends ChangeNotifier {
  final _formKey = GlobalKey<FormState>();
  
  // Form state
  final _titleController = TextEditingController();
  final _servingsController = TextEditingController();
  final _readyInMinutesController = TextEditingController();
  String? _selectedImage;

  // Nutrition state
  final _caloriesController = TextEditingController(text: '0');
  final _proteinController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatsController = TextEditingController(text: '0');

  // Lists state
  final _ingredients = <IngredientState>[];
  final _instructions = <TextEditingController>[];
  final _dietTags = <TextEditingController>[];

  // Dish type state
  String? _selectedDishType;
  final List<String> _dishTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  // State getters
  GlobalKey<FormState> get formKey => _formKey;
  TextEditingController get titleController => _titleController;
  TextEditingController get servingsController => _servingsController;
  TextEditingController get readyInMinutesController => _readyInMinutesController;
  String? get selectedImage => _selectedImage;
  TextEditingController get caloriesController => _caloriesController;
  TextEditingController get proteinController => _proteinController;
  TextEditingController get carbsController => _carbsController;
  TextEditingController get fatsController => _fatsController;
  List<IngredientState> get ingredients => _ingredients;
  List<TextEditingController> get instructions => _instructions;
  List<TextEditingController> get dietTags => _dietTags;
  String? get selectedDishType => _selectedDishType;
  List<String> get dishTypes => _dishTypes;

  // State setters
  set selectedImage(String? value) {
    _selectedImage = value;
    notifyListeners();
  }

  set selectedDishType(String? value) {
    _selectedDishType = value;
    notifyListeners();
  }

  // State management methods
  void addIngredient() {
    _ingredients.add(IngredientState());
    notifyListeners();
  }

  void removeIngredient(int index) {
    _ingredients[index].dispose();
    _ingredients.removeAt(index);
    updateNutritionTotals();
    notifyListeners();
  }

  void addInstruction() {
    _instructions.add(TextEditingController());
    notifyListeners();
  }

  void removeInstruction(int index) {
    _instructions[index].dispose();
    _instructions.removeAt(index);
    notifyListeners();
  }

  void addDietTag() {
    _dietTags.add(TextEditingController());
    notifyListeners();
  }

  void removeDietTag(int index) {
    _dietTags[index].dispose();
    _dietTags.removeAt(index);
    notifyListeners();
  }

  void updateIngredientUnits(IngredientState ingredient, List<String> units) {
  ingredient.availableUnits = units;
  if (!ingredient.availableUnits.contains('g')) {
    ingredient.availableUnits.add('g');
  }
  ingredient.selectedUnit = ingredient.availableUnits.first;
  notifyListeners();
}

void updateNutritionTotals() {
  double calories = 0;
  double protein = 0;
  double carbs = 0;
  double fats = 0;

  for (final ingredient in _ingredients) {
    calories += double.tryParse(ingredient.caloriesController.text) ?? 0;
    protein += double.tryParse(ingredient.proteinController.text) ?? 0;
    carbs += double.tryParse(ingredient.carbsController.text) ?? 0;
    fats += double.tryParse(ingredient.fatsController.text) ?? 0;
  }

  _caloriesController.text = calories.toStringAsFixed(0);
  _proteinController.text = protein.toStringAsFixed(1);
  _carbsController.text = carbs.toStringAsFixed(1);
  _fatsController.text = fats.toStringAsFixed(1);
  notifyListeners();
}

  @override
  void dispose() {
    _titleController.dispose();
    _servingsController.dispose();
    _readyInMinutesController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    for (final instruction in _instructions) {
      instruction.dispose();
    }
    for (final tag in _dietTags) {
      tag.dispose();
    }
    super.dispose();
  }
}

class IngredientState {
  final nameController = TextEditingController();
  final measurementController = TextEditingController();
  final caloriesController = TextEditingController(text: '0');
  final proteinController = TextEditingController(text: '0');
  final carbsController = TextEditingController(text: '0');
  final fatsController = TextEditingController(text: '0');
  
  bool isExpanded = false;
  int? ingredientId;
  String selectedUnit = 'g';
  List<String> availableUnits = ['g'];
  double amount = 0;

  void dispose() {
    nameController.dispose();
    measurementController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatsController.dispose();
  }
}