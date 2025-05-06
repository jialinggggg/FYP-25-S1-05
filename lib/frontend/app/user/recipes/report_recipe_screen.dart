import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../backend/controllers/report_recipe_controller.dart';
import '../../../../backend/entities/recipes.dart';

class ReportRecipeScreen extends StatefulWidget {
  final Recipes recipe;

  const ReportRecipeScreen({super.key, required this.recipe});

  @override
  State<ReportRecipeScreen> createState() => _ReportRecipeScreenState();
}

class _ReportRecipeScreenState extends State<ReportRecipeScreen> {
  late final SupabaseClient _supabase;
  late ReportRecipeController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _initializeController();
  }

  void _initializeController() async {
    _controller = ReportRecipeController(_supabase);
    await _controller.checkIfAlreadyReported(widget.recipe.id);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report Recipe'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<ReportRecipeController>(
          builder: (context, controller, _) {
            if (controller.hasReported) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
                      const SizedBox(height: 20),
                      const Text(
                        'Thank you for reporting!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'This recipe has been flagged and our team will review it shortly.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // else, show report form
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecipeHeader(),
                    const SizedBox(height: 24),
                    _buildReportTypeSection(),
                    const SizedBox(height: 24),
                    _buildCommentField(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    _buildErrorText(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecipeHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: widget.recipe.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.recipe.image!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.fastfood, size: 30, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipe.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${widget.recipe.id}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSection() {
    const reportTypes = [
      'Inappropriate Content',
      'Spam or Fake',
      'Copyright Violation',
      'Incorrect Information',
      'Other'
    ];

    return Consumer<ReportRecipeController>(
      builder: (context, controller, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Type*',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...reportTypes.map((type) => RadioListTile<String>(
              title: Text(type),
              value: type,
              groupValue: controller.selectedReportType,
              onChanged: (value) {
                controller.setReportType(value!);
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            )),
          ],
        );
      },
    );
  }

  Widget _buildCommentField() {
    return Consumer<ReportRecipeController>(
      builder: (context, controller, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Comments*',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Please provide details about your report...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a comment';
                }
                return null;
              },
              onChanged: (value) => controller.setComment(value),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<ReportRecipeController>(
      builder: (context, controller, _) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: controller.isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      final success = await controller.submitReport(widget.recipe);
                      if (success && mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Report submitted successfully!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
            child: controller.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'SUBMIT REPORT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildErrorText() {
    return Consumer<ReportRecipeController>(
      builder: (context, controller, _) {
        if (controller.error != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              controller.error!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}