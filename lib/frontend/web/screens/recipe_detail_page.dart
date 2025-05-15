import 'package:flutter/material.dart';
import 'package:nutri_app/backend/controller/recipe_management_controller.dart';
import 'package:nutri_app/backend/controller/recipe_report_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nutri_app/backend/api/spoonacular_api_service.dart';

class RecipeDetailPage extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final RecipeManagementController controller;

  const RecipeDetailPage({super.key, required this.recipe, required this.controller});

  @override
  RecipeDetailPageState createState() => RecipeDetailPageState();
}

class RecipeDetailPageState extends State<RecipeDetailPage> {
  late RecipeReportController reportController;
  bool isHidden = false;

  @override
  void initState() {
    super.initState();
    reportController = RecipeReportController(
      supabase: Supabase.instance.client,
      apiService: SpoonacularApiService(),
    );
    isHidden = widget.recipe['hidden'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final List<dynamic> analyzedInstructions = recipe['analyzed_instructions'] ?? [];
    final List<dynamic> extendedIngredients = recipe['extended_ingredients'] ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recipe',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (recipe['hidden'] == true)
              Container(
                margin: EdgeInsets.only(left: 10),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  "HIDDEN",
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  recipe['image'] ?? 'https://via.placeholder.com/300',
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              recipe['title'] ?? 'Unknown Title',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.rice_bowl, color: Colors.black54, size: 20),
                    SizedBox(width: 5),
                    Text('${recipe['servings'] ?? 'Unknown'} servings', style: TextStyle(color: Colors.black54)),
                  ],
                ),
                SizedBox(width: 15),
                Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.black54, size: 20),
                    SizedBox(width: 5),
                    Text(
                      '${_calculateTotalCalories(recipe['extended_ingredients'])} kcal',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                SizedBox(width: 15),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.black54, size: 20),
                    SizedBox(width: 5),
                    Text('${recipe['ready_in_minutes'] ?? 'Unknown'} minutes', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('Created on ${recipe['created_at']?.split('T')[0] ?? 'Unknown'} by ${recipe['submitter_name'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 20),
            const Divider(color: Colors.black26),
            const SizedBox(height: 20),

            /// Ingredients Section
            Text(
              "Ingredients",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 10),
            if (extendedIngredients.isNotEmpty)
              for (final ingredient in extendedIngredients)
                _buildBulletPoint(
                  "${ingredient['amount']} ${ingredient['unit']} ${ingredient['name']}",
                ),
            const SizedBox(height: 20),

            /// Instructions Section
            Text(
              'Instructions',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 10),
            if (analyzedInstructions.isNotEmpty)
              for (final section in analyzedInstructions)
                for (final step in section['steps'])
                  _buildNumberedStep(step['number'], step['step']),
            const SizedBox(height: 30),
            /// Hide/Unhide Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 300),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black26),
                ),
                child: Row(
                  children: [
                    /// Hide Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!isHidden) {
                            await reportController.hideRecipe(recipe['id'], recipe['source_type'] ?? 'unknown', recipe['created_at'] ?? DateTime.now().toIso8601String());
                            setState(() {
                              isHidden = true;
                              recipe['hidden'] = true;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isHidden ? Colors.red : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: isHidden ? BorderSide.none : BorderSide(color: Colors.black26),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility_off, color: isHidden ? Colors.white : Colors.black87, size: 18),
                            SizedBox(width: 5),
                            Text(
                              "Hide",
                              style: TextStyle(
                                fontSize: 16,
                                color: isHidden ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    /// Unhide Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isHidden) {
                            await reportController.unhideRecipe(recipe['id']);
                            setState(() {
                              isHidden = false;
                              recipe['hidden'] = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isHidden ? Colors.white : Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: isHidden ? BorderSide(color: Colors.black26) : BorderSide.none,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility, color: isHidden ? Colors.black87 : Colors.white, size: 18),
                            SizedBox(width: 5),
                            Text(
                              "Unhide",
                              style: TextStyle(
                                fontSize: 16,
                                color: isHidden ? Colors.black87 : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Bullet Point List
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 6, color: Colors.black87),
          SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16, color: Colors.black87))),
        ],
      ),
    );
  }

  /// Numbered Steps
  Widget _buildNumberedStep(int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$step.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16, color: Colors.black87))),
        ],
      ),
    );
  }

  /// Calculate Total Calories
  int _calculateTotalCalories(List<dynamic>? ingredients) {
    if (ingredients == null || ingredients.isEmpty) return 0;

    double totalCalories = 0;
    for (final ingredient in ingredients) {
      final nutrients = ingredient['nutrition']?['nutrients'] ?? [];
      for (final nutrient in nutrients) {
        if (nutrient['title'] == 'Calories') {
          totalCalories += nutrient['amount'];
          break;
        }
      }
    }

    return totalCalories.round();
  }
}
