import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../backend/signup/signup_state.dart';
import '../../../../backend/api/spoonacular_service.dart';

class SignupMed extends StatefulWidget {
  const SignupMed({super.key});

  @override
  SignupMedState createState() => SignupMedState();
}

class SignupMedState extends State<SignupMed> {
  // All possible pre-existing conditions
  static const List<String> _preExistingOptions = [
    'High blood pressure',
    'Type 1 diabetes',
  ];

  // Pre-existing conditions selections
  final List<String?> _preExistingSelected = [];

  // Allergies controllers and suggestions
  final List<TextEditingController> _allergiesControllers = [];
  final List<List<Map<String, dynamic>>> _allergySuggestions = [];

  final SpoonacularService _spoonacularService = SpoonacularService();

  @override
  void dispose() {
    for (var controller in _allergiesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPreExistingField() {
    setState(() {
      _preExistingSelected.add(null);
    });
  }

  void _removePreExistingField(int index) {
    setState(() {
      _preExistingSelected.removeAt(index);
    });
  }

  void _addAllergyField() {
    setState(() {
      _allergiesControllers.add(TextEditingController());
      _allergySuggestions.add([]);
    });
  }

  void _removeAllergyField(int index) {
    setState(() {
      _allergiesControllers.removeAt(index);
      _allergySuggestions.removeAt(index);
    });
  }

  Future<void> _onAllergyChanged(String query, int index) async {
    if (query.isEmpty) {
      setState(() {
        _allergySuggestions[index] = [];
      });
      return;
    }
    try {
      final results = await _spoonacularService.searchIngredients(query: query);
      setState(() {
        _allergySuggestions[index] = results;
      });
    } catch (e) {
      setState(() {
        _allergySuggestions[index] = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final signupState = context.watch<SignupState>();

    // Compute remaining options for new dropdowns
    final remainingPreExisting = _preExistingOptions
        .where((opt) => !_preExistingSelected.contains(opt))
        .toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Medical History",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Progress indicator (step 3 of 7)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                7,
                (index) => Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == 2 ? Colors.green : Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            Text(
              "Help Us Understand Your Health Needs!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Pre-existing Conditions Section
            Text(
              "Do you have any pre-existing medical conditions?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "If yes, select medical conditions",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            Column(
              children: [
                if (_preExistingSelected.isNotEmpty)
                  ..._preExistingSelected.asMap().entries.map((entry) {
                    final index = entry.key;
                    final value = entry.value;
                    // Compute options for this dropdown, including the current value’s slot
                    final available = _preExistingOptions
                        .where((opt) => !
                            _preExistingSelected.contains(opt) ||
                            opt == value)
                        .toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: value,
                              decoration: InputDecoration(
                                hintText: "Select condition",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              items: available
                                  .map((opt) => DropdownMenuItem(
                                        value: opt,
                                        child: Text(opt),
                                      ))
                                  .toList(),
                              onChanged: (val) => setState(() {
                                _preExistingSelected[index] = val;
                              }),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () => _removePreExistingField(index),
                          ),
                        ],
                      ),
                    );
                  }),

                // Only show "Add" if there's at least one remaining option
                if (remainingPreExisting.isNotEmpty)
                  TextButton(
                    onPressed: _addPreExistingField,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.green),
                        Text(
                          "Add Medical Condition",
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 30),

            // Allergies Section
            Text(
              "Do you have any known allergies?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "If yes, add allergies",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            Column(
              children: [
                if (_allergiesControllers.isNotEmpty)
                  ..._allergiesControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    final suggestions = _allergySuggestions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    hintText: 'Enter allergy',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onChanged: (text) => _onAllergyChanged(text, index),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () => _removeAllergyField(index),
                              ),
                            ],
                          ),
                          if (suggestions.isNotEmpty)
                            Container(
                              constraints: BoxConstraints(maxHeight: 150),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: suggestions.length,
                                itemBuilder: (_, i) {
                                  final item = suggestions[i];
                                  return ListTile(
                                    leading: item['image'] != null
                                        ? Image.network(item['image'] as String)
                                        : null,
                                    title: Text(item['name'] as String),
                                    onTap: () {
                                      setState(() {
                                        controller.text = item['name'] as String;
                                        _allergySuggestions[index] = [];
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                TextButton(
                  onPressed: _addAllergyField,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.green),
                      Text(
                        "Add Allergy",
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),

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
                    // Gather selections
                    final preExisting = _preExistingSelected
                        .where((e) => e != null)
                        .cast<String>()
                        .toList();
                    final allergies = _allergiesControllers
                        .map((c) => c.text.trim())
                        .where((text) => text.isNotEmpty)
                        .toList();

                    // Update state
                    signupState.setPreExistingConditions(preExisting);
                    signupState.setAllergyList(allergies);

                    // Proceed to next screen
                    Navigator.pushNamed(context, '/signup_goal');
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
