import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nutri_app/backend/api/spoonacular_api_service.dart';
import '../../../backend/controller/recipe_report_controller.dart';
import 'feedback_recipe_detail_page.dart';
import 'feedback_product_detail_page.dart';
import 'package:intl/intl.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({ super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> with SingleTickerProviderStateMixin {
  late final RecipeReportController _controller;
  List<Map<String, dynamic>> _recipeReports = [];
  List<Map<String, dynamic>> _productReports = [];
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  String selectedStatus = "All";
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = RecipeReportController(supabase: Supabase.instance.client, apiService: SpoonacularApiService());
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
      });
    });
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    try {
      final recipeReports = await _controller.fetchRecipeReports();
      final productReports = await _controller.fetchProductReports();

      if (mounted) {
        setState(() {
          _recipeReports = recipeReports;
          _productReports = productReports;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false); 
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      body: _loading
        ? const Center(child: CircularProgressIndicator()) // Loading spinner
        : Padding(
        padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 100 : 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Tabs for Recipes and Products
            TabBar(
              controller: _tabController,
              labelColor: Colors.green[800],
              unselectedLabelColor: Colors.black,
              indicatorColor: Colors.green[800],
              labelStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: "Recipes"),
                Tab(text: "Products"),
              ],
            ),
            const SizedBox(height: 10),

            /// Search Bar and Status Dropdown
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search for Recipes",
                      prefixIcon: const Icon(Icons.search, color: Colors.black54),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                    items: ["All", "Approved", "Pending", "Rejected"]
                        .map((status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    ))
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            /// Tabs Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecipeReportsList(_recipeReports),
                  _buildProductReportsList(_productReports),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeReportsList(List<Map<String, dynamic>> reports) {
    // Normalize query and status
    final query = searchQuery.toLowerCase();
    final statusFilter = selectedStatus.toLowerCase();

    // Filter reports
    final filteredReports = reports.where((report) {
      final title = (report['title'] ?? '').toString().toLowerCase();
      final reporter = (report['submitter_name'] ?? report['uid'] ?? '').toString().toLowerCase();
      final reportStatus = (report['status'] ?? 'pending').toString().toLowerCase();

      final matchesQuery = title.contains(query) || reporter.contains(query);
      final matchesStatus = selectedStatus == "All" || reportStatus == statusFilter;

      return matchesQuery && matchesStatus;
    }).toList();

    if (filteredReports.isEmpty) {
      return const Center(
        child: Text("No reports found", style: TextStyle(fontSize: 16, color: Colors.black54)),
      );
    }

    return ListView.builder(
      itemCount: filteredReports.length,
      itemBuilder: (context, index) {
        final report = filteredReports[index];
        final createdAt = DateFormat('yyyy-MM-dd').format(DateTime.parse(report['created_at']));
        final status = report['status'] ?? 'pending';
        final reporter = report['submitter_name'] ?? 'Unknown';


        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FeedBackRecipeDetailPage(
                  report: report,
                  controller: _controller,
                ),
              ),
            ).then((_) => _loadReports());
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    report['image'] ?? 'https://via.placeholder.com/100',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 40),
                      );
                    },
                  )
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report['title'] ?? 'Unknown Title',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Report ID: ${report['report_id']}"),
                      Text("Reported by: $reporter"),
                      Text("Report Type: ${report['type'] ?? report['report_type']}"),
                      Text("Date: $createdAt"),
                    ],
                  ),
                ),
                if ((status as String).isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == "pending"
                          ? Colors.orange
                          : status == "approved"
                              ? Colors.green
                              : Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductReportsList(List<Map<String, dynamic>> reports) {
    // Normalize query and status
    final query = searchQuery.toLowerCase();
    final statusFilter = selectedStatus.toLowerCase();

    // Filter reports
    final filteredReports = reports.where((report) {
      final title = (report['name'] ?? '').toString().toLowerCase(); // Product name
      final reporter = (report['submitter_name'] ?? report['uid'] ?? '').toString().toLowerCase();
      final rawStatus = report['status']?.toString().toLowerCase() ?? 'pending';
      final displayStatus = rawStatus == 'active' ? 'pending' : rawStatus;


      final matchesQuery = title.contains(query) || reporter.contains(query);
      final matchesStatus = selectedStatus == "All" || displayStatus == statusFilter;

      return matchesQuery && matchesStatus;
    }).toList();

    if (filteredReports.isEmpty) {
      return const Center(
        child: Text("No reports found", style: TextStyle(fontSize: 16, color: Colors.black54)),
      );
    }

    return ListView.builder(
      itemCount: filteredReports.length,
      itemBuilder: (context, index) {
        final report = filteredReports[index];
        final createdAt = DateFormat('yyyy-MM-dd').format(DateTime.parse(report['created_at']));
        final rawStatus = report['status']?.toString().toLowerCase() ?? 'pending';
        final displayStatus = rawStatus == 'active' ? 'pending' : rawStatus;

        final reporter = report['submitter_name'] ?? 'Unknown';
      
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FeedbackProductDetailPage(
                  report: report,
                  controller: _controller,
                ),
              ),
            ).then((_) => _loadReports());
          },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  report['image'] ?? 'https://via.placeholder.com/150',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 40),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report['name'] ?? 'Unknown Product',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Report ID: ${report['id']}"),
                    Text("Reported by: $reporter"),
                    Text("Date: $createdAt"),
                  ],
                ),
              ),
              if ((displayStatus).isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: displayStatus == "pending"
                        ? Colors.orange
                        : displayStatus == "approved"
                            ? Colors.green
                            : Colors.red,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    displayStatus.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          ),
        );
      },
    );
  }

}