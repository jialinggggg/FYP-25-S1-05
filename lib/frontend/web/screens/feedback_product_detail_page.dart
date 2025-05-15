import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../backend/controller/recipe_report_controller.dart';

class FeedbackProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> report;
  final RecipeReportController controller;

  const FeedbackProductDetailPage({super.key, required this.report, required this.controller});

  @override
  State<FeedbackProductDetailPage> createState() => _FeedbackProductDetailPageState();
}

class _FeedbackProductDetailPageState extends State<FeedbackProductDetailPage> {
  late RecipeReportController _controller;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final createdAt = DateFormat('yyyy-MM-dd').format(DateTime.parse(report['created_at']));
    final imageUrl = report['image'] ?? 'https://via.placeholder.com/300';

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
            if ((report['status'] as String).isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: report['status'] == "active"
                      ? Colors.orange
                      : report['status'] == "approved"
                      ? Colors.green
                      : Colors.red,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  report['status'].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${report['name']}",
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text('Reported on $createdAt by ${report['submitter_name']}',
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const Divider(color: Colors.black26),
            const SizedBox(height: 20),

            /// --- Report Info ---
            Text("Message: ${report['message'] ?? '-'}", style: const TextStyle(fontSize: 16)),
            const Divider(height: 30),
            const SizedBox(height: 30),

            /// --- Product Image ---
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: (report['image'] != null && report['image'].startsWith('http'))
                    ? Image.network(
                  imageUrl ?? 'https://via.placeholder.com/100',
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                )
                    : Image.asset(
                  report['image'] ?? 'assets/default_image.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// --- Product Info ---
            Text(
              report['name'] ?? 'Unknown Product',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 20),
            Text(
              'Created by ${report['submitter_name'] ?? 'Unknown'} on ${report['created_at']?.split('T')[0] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const Divider(color: Colors.black26),
            const SizedBox(height: 30),

            Text("Description: ${report['description'] ?? 'N/A'}", style: const TextStyle(fontSize: 16)),
            Text("Category: ${report['category'] ?? 'N/A'}", style: const TextStyle(fontSize: 16)),
            Text("Price: \$${report['price'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16)),
            Text("Stock: ${report['stock'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16)),
            Text("Status: ${report['status'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 30),
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

  void _handleApprove() async {
    setState(() => _loading = true);
    try {
      await _controller.acceptProductReport(widget.report['id']);
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Failed to approve product report.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _handleReject() async {
    setState(() => _loading = true);
    try {
      await _controller.rejectProductReport(widget.report['id']);
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Failed to reject product report.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
