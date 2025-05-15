import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../backend/controller/recipe_report_controller.dart';


class FeedBackRecipeDetailPage extends StatefulWidget {
  final Map<String, dynamic> report;
  final RecipeReportController controller;

  const FeedBackRecipeDetailPage({super.key, required this.report, required this.controller});

  @override
  State<FeedBackRecipeDetailPage> createState() => _FeedBackRecipeDetailPageState();
}

class _FeedBackRecipeDetailPageState extends State<FeedBackRecipeDetailPage> {
  late RecipeReportController _controller;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.report;
    final createdAt = DateFormat('yyyy-MM-dd').format(DateTime.parse(recipe['created_at']));
    final List<dynamic> ingredients =
        (recipe['extended_ingredients'] is List) ? recipe['extended_ingredients'] : [];
    final List<dynamic> instructions = (recipe['analyzed_instructions'] is List)
        ? recipe['analyzed_instructions']
            .expand((s) => (s['steps'] as List?) ?? [])
            .toList()
        : [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recipe Report',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if ((recipe['status'] as String).isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: recipe['status'] == "pending"
                      ? Colors.orange
                      : recipe['status'] == "approved"
                      ? Colors.green
                      : Colors.red,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  recipe['status'].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${recipe['submitter_name']}",
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text('Reported on $createdAt by ${recipe['submitter_name']}',
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const Divider(color: Colors.black26),
            const SizedBox(height: 20),

            /// --- Report Details ---
            Text("Report Type: ${recipe['report_type']}", style: const TextStyle(fontSize: 16)),
            Text("Comment: ${recipe['comment']}", style: const TextStyle(fontSize: 16)),
            const Divider(height: 30, color: Colors.black45),
            const SizedBox(height: 30),

            /// --- Recipe Image ---
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

            /// --- Recipe Title ---
            Text(
              recipe['title'] ?? 'No Title',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 10),

            /// --- Info Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _iconText(Icons.rice_bowl, "${recipe['servings'] ?? 'Unknown'} servings"),
                const SizedBox(width: 15),
                _iconText(Icons.local_fire_department,
                    "${_calculateTotalCalories(ingredients)} kcal"),
                const SizedBox(width: 15),
                _iconText(Icons.access_time,
                    "${recipe['ready_in_minutes'] ?? 'Unknown'} minutes"),
              ],
            ),

            const SizedBox(height: 20),
            Text('Created on $createdAt by ${recipe['source_name'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 20),
            const Divider(color: Colors.black26),
            const SizedBox(height: 20),

            /// --- Ingredients Section ---
            Text("Ingredients",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 10),
            ...ingredients.map((ingredient) {
              final amount = ingredient['amount'] ?? '';
              final unit = ingredient['unit'] ?? '';
              final name = ingredient['name'] ?? '';
              return _buildBulletPoint("$amount $unit $name");
            }),

            const SizedBox(height: 20),

            /// --- Instructions Section ---
            Text("Instructions",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 10),
            ...instructions.map((step) {
              final number = step['number'] ?? 0;
              final text = step['step'] ?? '';
              return _buildNumberedStep(number, text);
            }),

            const SizedBox(height: 30),

            /// --- Approve / Reject Buttons ---
            if (!_loading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 300),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleApprove,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 18),
                              SizedBox(width: 5),
                              Text("Approve", style: TextStyle(fontSize: 16, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleReject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close, color: Colors.white, size: 18),
                              SizedBox(width: 5),
                              Text("Reject", style: TextStyle(fontSize: 16, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: 20),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.black87),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildNumberedStep(int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$step.", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87))),
        ],
      ),
    );
  }

  int _calculateTotalCalories(List<dynamic> ingredients) {
    if (ingredients.isEmpty) return 0;

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

  void _handleApprove() async {
    setState(() => _loading = true);
    try {
      await _controller.acceptRecipeReport(widget.report['id'], widget.report['source_type'], widget.report['report_id']);

      Navigator.pop(context, true);
    } catch (e) {
      _showError('Failed to approve report.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _handleReject() async {
    setState(() => _loading = true);
    try {
      await _controller.rejectRecipeReport(widget.report['report_id'], widget.report['recipe_id']);
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Failed to reject report.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
