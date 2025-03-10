// lib/screens/signup_target.dart
import 'package:flutter/material.dart';
import 'signup_detail.dart';
import '../utils/calculations.dart';

class SignupTarget extends StatefulWidget {
  final String name;
  final String location;
  final String gender;
  final DateTime birthDate;
  final double weight;
  final double height;
  final String preExisting;
  final String allergies;

  const SignupTarget({
    super.key,
    required this.name,
    required this.location,
    required this.gender,
    required this.birthDate,
    required this.weight,
    required this.height,
    required this.preExisting,
    required this.allergies,
  });

  @override
  SignupTargetState createState() => SignupTargetState();
}

class SignupTargetState extends State<SignupTarget> {
  // Variables to store recommended values
  double _recommendedWeight = 0.0;
  int _recommendedCalories = 0;
  double _recommendedProtein = 0.0;
  double _recommendedFats = 0.0;
  double _recommendedCarbs = 0.0;

  // Controllers for editable fields
  final _desiredWeightController = TextEditingController();
  final _dailyCaloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatsController = TextEditingController();
  final _carbsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Calculate recommended values when the widget is initialized
    _calculateRecommendations();
  }

  // Function to calculate recommended values
  void _calculateRecommendations() {
    // Calculate ideal body weight
    _recommendedWeight = Calculations.calculateIdealBodyWeight(widget.gender, widget.height);

    // Calculate BMR and daily calories
    _recommendedCalories = Calculations.calculateBMR(widget.gender, _recommendedWeight, widget.height, DateTime.now().year - widget.birthDate.year).round();

    // Calculate macronutrients
    Map<String, double> macros = Calculations.calculateMacronutrients(_recommendedCalories);
    _recommendedProtein = macros['protein']!;
    _recommendedFats = macros['fats']!;
    _recommendedCarbs = macros['carbs']!;

    // Set initial values in the text fields
    _desiredWeightController.text = _recommendedWeight.toStringAsFixed(1);
    _dailyCaloriesController.text = _recommendedCalories.toString();
    _proteinController.text = _recommendedProtein.toStringAsFixed(1);
    _fatsController.text = _recommendedFats.toStringAsFixed(1);
    _carbsController.text = _recommendedCarbs.toStringAsFixed(1);
  }

  // Function to update a value with a step
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

  // Helper function to build an editable row
  Widget _buildEditableRow({
    required String label,
    required TextEditingController controller,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align items to the edges
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle_outline),
              onPressed: onDecrease,
            ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10), // Add padding for better alignment
                ),
                textAlign: TextAlign.right, // Align text to the right
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline),
              onPressed: onIncrease,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header "Target" text
            Center(
              child: Text(
                "Target",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Container(
                  width: 68,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == 3 ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Left-aligned text sections
            Text(
              "Let's Set Your Targets!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            Text(
              "Set your desired weight and daily calorie intake to personalize your wellness plan.",
              style: TextStyle(fontSize: 16, color: const Color.fromARGB(255, 99, 97, 97)),
            ),
            const SizedBox(height: 30),

            // Desired Weight Row
            _buildEditableRow(
              label: "Desired Weight (kg)",
              controller: _desiredWeightController,
              onDecrease: () => _updateValue('weight', -0.5),
              onIncrease: () => _updateValue('weight', 0.5),
            ),
            const SizedBox(height: 20),

            // Daily Calories Intake Row
            _buildEditableRow(
              label: "Daily Calories Intake",
              controller: _dailyCaloriesController,
              onDecrease: () => _updateValue('calories', -50),
              onIncrease: () => _updateValue('calories', 50),
            ),
            const SizedBox(height: 20),

            // Protein Intake Row
            _buildEditableRow(
              label: "Protein (g)",
              controller: _proteinController,
              onDecrease: () => _updateValue('protein', -5),
              onIncrease: () => _updateValue('protein', 5),
            ),
            const SizedBox(height: 20),

            // Fats Intake Row
            _buildEditableRow(
              label: "Fats (g)",
              controller: _fatsController,
              onDecrease: () => _updateValue('fats', -5),
              onIncrease: () => _updateValue('fats', 5),
            ),
            const SizedBox(height: 20),

            // Carbs Intake Row
            _buildEditableRow(
              label: "Carbs (g)",
              controller: _carbsController,
              onDecrease: () => _updateValue('carbs', -5),
              onIncrease: () => _updateValue('carbs', 5),
            ),

            const Spacer(),

            // Back and Next buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 30),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                // Next button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 135, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  onPressed: () {
                    // Navigate to the SignupDetails screen with the collected data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignUpDetail(
                          name: widget.name,
                          location: widget.location,
                          gender: widget.gender,
                          birthDate: widget.birthDate,
                          weight: widget.weight,
                          height: widget.height,
                          preExisting: widget.preExisting,
                          allergies: widget.allergies,
                          desiredWeight: double.parse(_desiredWeightController.text),
                          dailyCalories: int.parse(_dailyCaloriesController.text),
                          protein: double.parse(_proteinController.text),
                          fats: double.parse(_fatsController.text),
                          carbs: double.parse(_carbsController.text),
                        ),
                      ),
                    );
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