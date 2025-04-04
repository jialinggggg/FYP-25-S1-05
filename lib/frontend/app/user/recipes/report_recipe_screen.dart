import 'package:flutter/material.dart';

class ReportRecipeScreen extends StatefulWidget {
  final String recipeId;

  const ReportRecipeScreen({super.key, required this.recipeId});

  @override
  State<ReportRecipeScreen> createState() => _ReportRecipeScreenState();
}

class _ReportRecipeScreenState extends State<ReportRecipeScreen> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  final List<String> _reasons = [
    'Inappropriate content',
    'Incorrect information',
    'Spam or misleading',
    'Other'
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    // Here you would typically send the report to your backend
    print('Reporting recipe ${widget.recipeId} for: $_selectedReason');
    print('Additional details: ${_detailsController.text}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted successfully')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Recipe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please select the reason for reporting this recipe:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ..._reasons.map((reason) => RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) => setState(() => _selectedReason = value),
            )).toList(),
            const SizedBox(height: 20),
            const Text(
              'Additional details (optional):',
              style: TextStyle(fontSize: 16),
            ),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Provide more details about your report...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Submit Report',
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