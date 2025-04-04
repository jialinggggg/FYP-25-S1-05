import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../backend/state/signup_state.dart';
import '../../../../backend/services/input_validation_service.dart';
import '../../../../utils/date_picker.dart';
import '../../../../utils/widget_utils.dart';

class SignupTarget extends StatefulWidget {
  const SignupTarget({super.key});

  @override
  SignupTargetState createState() => SignupTargetState();
}

class SignupTargetState extends State<SignupTarget> {
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _dailyCaloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final InputValidationService _validationService = InputValidationService();
  Map<String, dynamic>? _calculatedGoals;
  String? _targetWeightError;
  String? _targetDateError;

  @override
  void initState() {
    super.initState();
    // Schedule the calculation for after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateGoals();
    });
  }

  Future<void> _calculateGoals() async {
    final signupState = context.read<SignupState>();
    _calculatedGoals = _validationService.calculateRecommendedGoals(
      gender: signupState.gender,
      weight: signupState.weight,
      height: signupState.height,
      birthDate: signupState.birthDate!,
      goal: signupState.goal,
      activity: signupState.activity,
    );
    
    if (_calculatedGoals != null) {
      _targetWeightController.text = _calculatedGoals!['targetWeight'].toStringAsFixed(1);
      _dailyCaloriesController.text = _calculatedGoals!['dailyCalories'].toString();
      _proteinController.text = _calculatedGoals!['protein'].toStringAsFixed(1);
      _carbsController.text = _calculatedGoals!['carbs'].toStringAsFixed(1);
      _fatsController.text = _calculatedGoals!['fats'].toStringAsFixed(1);
      
      // Don't call notifyListeners during build
      signupState.setTargetWeight(_calculatedGoals!['targetWeight']);
      signupState.setDailyCalories(_calculatedGoals!['dailyCalories']);
      signupState.setProtein(_calculatedGoals!['protein']);
      signupState.setCarbs(_calculatedGoals!['carbs']);
      signupState.setFats(_calculatedGoals!['fats']);
      signupState.setTargetDate(_calculatedGoals!['targetDate']);
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final signupState = context.watch<SignupState>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Targets",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator (step 6 of 7)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                7,
                (index) => Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == 5 ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            Text(
              "Set Your Health Targets!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Recommended Goals Section
            if (_calculatedGoals != null) ...[
              Text(
                "Recommended Targets:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Based on your goal to ${signupState.goal.toLowerCase()} and ${signupState.activity.toLowerCase()} lifestyle",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
            ],

            // Target Weight
            WidgetUtils.buildEditableRow(
              label: "Target Weight (kg)",
              controller: _targetWeightController,
              onDecrease: () {
                final current = double.tryParse(_targetWeightController.text) ?? 0;
                if (current > 20) {
                  _targetWeightController.text = (current - 0.5).toStringAsFixed(1);
                  signupState.setTargetWeight(double.parse(_targetWeightController.text));
                }
              },
              onIncrease: () {
                final current = double.tryParse(_targetWeightController.text) ?? 0;
                if (current < 500) {
                  _targetWeightController.text = (current + 0.5).toStringAsFixed(1);
                  signupState.setTargetWeight(double.parse(_targetWeightController.text));
                }
              },
              hasError: _targetWeightError != null,
              errorMessage: _targetWeightError,
            ),
            const SizedBox(height: 20),

            // Target Date
            Text(
              "Target Date",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                      text: signupState.targetDate == null 
                          ? '' 
                          : "${signupState.targetDate!.toLocal()}".split(' ')[0],
                    ),
                    decoration: InputDecoration(
                      hintText: "Select target date",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await DatePicker.selectDate(context);
                      if (date != null) {
                        signupState.setTargetDate(date);
                        setState(() => _targetDateError = null);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await DatePicker.selectDate(context);
                    if (date != null) {
                      signupState.setTargetDate(date);
                      setState(() => _targetDateError = null);
                    }
                  },
                ),
              ],
            ),
            if (_targetDateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _targetDateError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),

            // Nutrition Targets
            Text(
              "Nutrition Targets:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            WidgetUtils.buildEditableRow(
              label: "Daily Calories (kcal)",
              controller: _dailyCaloriesController,
              onDecrease: () {
                final current = int.tryParse(_dailyCaloriesController.text) ?? 0;
                if (current > 1000) {
                  _dailyCaloriesController.text = (current - 50).toString();
                  signupState.setDailyCalories(int.parse(_dailyCaloriesController.text));
                }
              },
              onIncrease: () {
                final current = int.tryParse(_dailyCaloriesController.text) ?? 0;
                if (current < 5000) {
                  _dailyCaloriesController.text = (current + 50).toString();
                  signupState.setDailyCalories(int.parse(_dailyCaloriesController.text));
                }
              },
            ),
            const SizedBox(height: 15),

            WidgetUtils.buildEditableRow(
              label: "Protein (g)",
              controller: _proteinController,
              onDecrease: () {
                final current = double.tryParse(_proteinController.text) ?? 0;
                if (current > 10) {
                  _proteinController.text = (current - 5).toStringAsFixed(1);
                  signupState.setProtein(double.parse(_proteinController.text));
                }
              },
              onIncrease: () {
                final current = double.tryParse(_proteinController.text) ?? 0;
                if (current < 300) {
                  _proteinController.text = (current + 5).toStringAsFixed(1);
                  signupState.setProtein(double.parse(_proteinController.text));
                }
              },
            ),
            const SizedBox(height: 15),

            WidgetUtils.buildEditableRow(
              label: "Carbs (g)",
              controller: _carbsController,
              onDecrease: () {
                final current = double.tryParse(_carbsController.text) ?? 0;
                if (current > 10) {
                  _carbsController.text = (current - 5).toStringAsFixed(1);
                  signupState.setCarbs(double.parse(_carbsController.text));
                }
              },
              onIncrease: () {
                final current = double.tryParse(_carbsController.text) ?? 0;
                if (current < 500) {
                  _carbsController.text = (current + 5).toStringAsFixed(1);
                  signupState.setCarbs(double.parse(_carbsController.text));
                }
              },
            ),
            const SizedBox(height: 15),

            WidgetUtils.buildEditableRow(
              label: "Fats (g)",
              controller: _fatsController,
              onDecrease: () {
                final current = double.tryParse(_fatsController.text) ?? 0;
                if (current > 10) {
                  _fatsController.text = (current - 5).toStringAsFixed(1);
                  signupState.setFats(double.parse(_fatsController.text));
                }
              },
              onIncrease: () {
                final current = double.tryParse(_fatsController.text) ?? 0;
                if (current < 200) {
                  _fatsController.text = (current + 5).toStringAsFixed(1);
                  signupState.setFats(double.parse(_fatsController.text));
                }
              },
            ),
            const SizedBox(height: 25),

            const Spacer(),

            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 135, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  onPressed: () {
                    if (_targetWeightController.text.isEmpty) {
                      setState(() => _targetWeightError = 'Please enter target weight');
                    } else if (signupState.targetDate == null) {
                      setState(() => _targetDateError = 'Please select target date');
                    } else {
                      Navigator.pushNamed(context, '/signup_detail');
                    }
                  },
                  child: Text(
                    "Next",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}