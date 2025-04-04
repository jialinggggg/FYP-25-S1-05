import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../utils/widget_utils.dart';
import '../../../../utils/input_validator.dart';
import '../../../../../utils/dialog_utils.dart';
import '../../../../backend/supabase/user_goals_service.dart';

class EditGoalsScreen extends StatefulWidget {
  final VoidCallback onUpdate;

  const EditGoalsScreen({super.key, required this.onUpdate});

  @override
  EditGoalsScreenState createState() => EditGoalsScreenState();
}

class EditGoalsScreenState extends State<EditGoalsScreen> {
  final UserGoalsService _userGoalsService = UserGoalsService(Supabase.instance.client); // Initialize UserGoalsService

  final TextEditingController _desiredWeightController = TextEditingController();
  final TextEditingController _dailyCaloriesController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();

  bool _weightError = false;
  bool _caloriesError = false;
  bool _fatsError = false;
  bool _proteinError = false;
  bool _carbsError = false;

  @override
  void initState() {
    super.initState();
    _fetchGoalsData();
  }

  Future<void> _fetchGoalsData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Fetch goals data using UserGoalsService
      final goalsData = await _userGoalsService.fetchGoals(userId);
      if (!mounted) return;
      setState(() {
        _desiredWeightController.text = goalsData?['weight']?.toString() ?? "";
        _dailyCaloriesController.text = goalsData?['daily_calories']?.toString() ?? "";
        _fatsController.text = goalsData?['fats']?.toString() ?? "";
        _proteinController.text = goalsData?['protein']?.toString() ?? "";
        _carbsController.text = goalsData?['carbs']?.toString() ?? "";
      });
    } catch (e) {
      if (!mounted) return;
      DialogUtils.showErrorDialog(
        context: context,
        message: 'Error fetching goals data: $e',
      );
    }
  }

  void _updateValue(String type, double step) {
    setState(() {
      switch (type) {
        case 'weight':
          double newWeight = double.parse(_desiredWeightController.text) + step;
          _desiredWeightController.text = newWeight.toStringAsFixed(1);
          break;
        case 'calories':
          int newCalories = int.parse(_dailyCaloriesController.text) + step.round();
          _dailyCaloriesController.text = newCalories.toString();
          break;
        case 'protein':
          double newProtein = double.parse(_proteinController.text) + step;
          _proteinController.text = newProtein.toStringAsFixed(1);
          break;
        case 'fats':
          double newFats = double.parse(_fatsController.text) + step;
          _fatsController.text = newFats.toStringAsFixed(1);
          break;
        case 'carbs':
          double newCarbs = double.parse(_carbsController.text) + step;
          _carbsController.text = newCarbs.toStringAsFixed(1);
          break;
      }
    });
  }

  bool _validateFields() {
    bool isValid = true;

    isValid &= InputValidator.validateNumericField(
      _desiredWeightController.text,
      (error) => setState(() => _weightError = error),
      20,
      500,
      "Weight must be between 20 kg and 500 kg",
    );

    isValid &= InputValidator.validateNumericField(
      _dailyCaloriesController.text,
      (error) => setState(() => _caloriesError = error),
      500,
      5000,
      "Calories must be between 500 and 5000",
    );

    isValid &= InputValidator.validateNumericField(
      _proteinController.text,
      (error) => setState(() => _proteinError = error),
      0,
      500,
      "Protein must be between 0 g and 500 g",
    );

    isValid &= InputValidator.validateNumericField(
      _fatsController.text,
      (error) => setState(() => _fatsError = error),
      0,
      500,
      "Fats must be between 0 g and 500 g",
    );

    isValid &= InputValidator.validateNumericField(
      _carbsController.text,
      (error) => setState(() => _carbsError = error),
      0,
      500,
      "Carbs must be between 0 g and 500 g",
    );

    return isValid;
  }

  Future<void> _updateGoals() async {
    if (!_validateFields()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _userGoalsService.updateGoals(
        uid: userId,
        weight: double.parse(_desiredWeightController.text),
        dailyCalories: int.parse(_dailyCaloriesController.text),
        protein: double.parse(_proteinController.text),
        carbs: double.parse(_carbsController.text),
        fats: double.parse(_fatsController.text),
      );

      if (!mounted) return;

      DialogUtils.showSuccessDialog(
        context: context,
        message: 'Goals updated successfully.',
        onOkPressed: () {
          Navigator.pop(context); // Close the dialog
          widget.onUpdate(); // Notify the parent screen to refresh
          Navigator.pop(context); // Navigate back to the previous screen
        },
      );
    } catch (e) {
      if (!mounted) return;
      DialogUtils.showErrorDialog(
        context: context,
        message: 'Error updating goals: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Goals'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Desired Weight Row
            WidgetUtils.buildEditableRow(
              label: "Desired Weight (kg)",
              controller: _desiredWeightController,
              onDecrease: () => _updateValue('weight', -0.5),
              onIncrease: () => _updateValue('weight', 0.5),
              hasError: _weightError,
              errorMessage: "Weight must be between 20 kg and 500 kg",
            ),
            const SizedBox(height: 20),

            // Daily Calories Intake Row
            WidgetUtils.buildEditableRow(
              label: "Daily Calories Intake",
              controller: _dailyCaloriesController,
              onDecrease: () => _updateValue('calories', -50),
              onIncrease: () => _updateValue('calories', 50),
              hasError: _caloriesError,
              errorMessage: "Calories must be between 500 and 5000",
            ),
            const SizedBox(height: 20),

            // Protein Intake Row
            WidgetUtils.buildEditableRow(
              label: "Protein (g)",
              controller: _proteinController,
              onDecrease: () => _updateValue('protein', -5),
              onIncrease: () => _updateValue('protein', 5),
              hasError: _proteinError,
              errorMessage: "Protein must be between 0 g and 500 g",
            ),
            const SizedBox(height: 20),

            // Fats Intake Row
            WidgetUtils.buildEditableRow(
              label: "Fats (g)",
              controller: _fatsController,
              onDecrease: () => _updateValue('fats', -5),
              onIncrease: () => _updateValue('fats', 5),
              hasError: _fatsError,
              errorMessage: "Fats must be between 0 g and 500 g",
            ),
            const SizedBox(height: 20),

            // Carbs Intake Row
            WidgetUtils.buildEditableRow(
              label: "Carbs (g)",
              controller: _carbsController,
              onDecrease: () => _updateValue('carbs', -5),
              onIncrease: () => _updateValue('carbs', 5),
              hasError: _carbsError,
              errorMessage: "Carbs must be between 0 g and 500 g",
            ),

            const Spacer(),

            // Save Button at the Bottom
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateGoals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}