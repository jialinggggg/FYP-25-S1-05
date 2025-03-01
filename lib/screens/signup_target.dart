import 'package:flutter/material.dart';
import 'signup_detail.dart';

class SignupTarget extends StatefulWidget {
  final String name;
  final String location;
  final String gender;
  final int age;
  final double weight;
  final double height;
  final String preExisting;
  final String allergies;
  final String goal;

  const SignupTarget({
    super.key, 
    required this.name, 
    required this.location,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.preExisting,
    required this.allergies,
    required this.goal,
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
    // Example calculations (replace with actual logic)
    _recommendedWeight = _calculateRecommendedWeight(); // Start with current weight
    _recommendedCalories = _calculateDailyCalories();
    _recommendedProtein = _recommendedCalories * 0.3 / 4; // 30% of calories from protein
    _recommendedFats = _recommendedCalories * 0.3 / 9; // 30% of calories from fats
    _recommendedCarbs = _recommendedCalories * 0.4 / 4; // 40% of calories from carbs

    // Set initial values in the text fields
    _desiredWeightController.text = _recommendedWeight.toStringAsFixed(1);
    _dailyCaloriesController.text = _recommendedCalories.toString();
    _proteinController.text = _recommendedProtein.toStringAsFixed(1);
    _fatsController.text = _recommendedFats.toStringAsFixed(1);
    _carbsController.text = _recommendedCarbs.toStringAsFixed(1);
  }

  // Function to calculate recommended weight 
  double _calculateRecommendedWeight() {
    // Ideal Body Weight (IBW) calculation
    double ibw;
    if (widget.gender == 'Male'){
      ibw = 50 + (0.9 * (widget.height - 152));
    } else {
      ibw = 45.5 + (0.9 * (widget.height - 152));
    }
    return ibw;
  }

  // Function to calculate daily calories (example logic)
  int _calculateDailyCalories() {
    // Basal Metabolic Rate (BMR) calculation
    double bmr;
    if (widget.gender == 'Male') {
      bmr = 88.362 + (13.397 * widget.weight) + (4.799 * widget.height) - (5.677 * widget.age);
    } else {
      bmr = 447.593 + (9.247 * widget.weight) + (3.098 * widget.height) - (4.330 * widget.age);
    }

    // Adjust BMR based on goal
    switch (widget.goal) {
      case 'lose_weight':
        return (bmr * 0.8).round(); // 20% calorie deficit
      case 'gain_weight':
        return (bmr * 1.2).round(); // 20% calorie surplus
      case 'gain_muscle':
        return (bmr * 1.1).round(); // 10% calorie surplus
      default:
        return bmr.round(); // Maintain weight
    }
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
                6,
                (index) => Container(
                  width: 55,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == 4 ? Colors.green : Colors.black,
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
                          age: widget.age,
                          weight: double.parse(_desiredWeightController.text),
                          height: widget.height,
                          preExisting: widget.preExisting,
                          allergies: widget.allergies,
                          goal: widget.goal,
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

  // Helper function to build an editable row
  Widget _buildEditableRow({
    required String label,
    required TextEditingController controller,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 20),
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
            ),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline),
          onPressed: onIncrease,
        ),
      ],
    );
  }
}