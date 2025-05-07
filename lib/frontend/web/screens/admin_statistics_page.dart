/*
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login_page.dart';
import 'recipe_management_page.dart';
import 'manage_accounts_page.dart';
import 'applications_page.dart';
import 'feedback_page.dart';

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({super.key});

  @override
  AdminStatisticsPageState createState() => AdminStatisticsPageState();
}

class AdminStatisticsPageState extends State<AdminStatisticsPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminStatisticsContent(),
    const RecipeManagementPage(),
    const ManageAccountsPage(),
    const ApplicationsPage(),
    const FeedbackPage(),
  ];

  final List<String> _titles = [
    "Admin Statistics",
    "Recipe Management",
    "Account Management",
    "Manage Applications",
    "Feedback",
  ];

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isLargeScreen = constraints.maxWidth > 600;
            return AppBar(
              title: Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.green[700],
              automaticallyImplyLeading: false,
              actions: isLargeScreen
                  ? _buildFullNavBar()
                  : [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                      ),
                    ],
            );
          },
        ),
      ),
      endDrawer: MediaQuery.of(context).size.width <= 600
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    height: 80,
                    decoration: BoxDecoration(color: Colors.green[700]),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "Menu",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildDrawerItem("Statistics", 0),
                  _buildDrawerItem("Recipes", 1),
                  _buildDrawerItem("Users", 2),
                  _buildDrawerItem("Applications", 3),
                  _buildDrawerItem("Feedback", 4),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    onTap: () => Navigator.pushReplacementNamed(context, "/"),
                  ),
                ],
              ),
            )
          : null,
      body: _pages[_selectedIndex],
    );
  }

  List<Widget> _buildFullNavBar() {
    return [
      _buildNavItem("Statistics", 0),
      _buildNavItem("Recipes", 1),
      _buildNavItem("Users", 2),
      _buildNavItem("Applications", 3),
      _buildNavItem("Feedback", 4),
      const SizedBox(width: 50),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Colors.green),
        child: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => LoginPage())),
        ),
      ),
      const SizedBox(width: 20),
    ];
  }

  Widget _buildNavItem(String label, int index) {
    return TextButton(
      onPressed: () => _onTabSelected(index),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 18)),
    );
  }

  Widget _buildDrawerItem(String label, int index) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 18)),
      onTap: () => _onTabSelected(index),
    );
  }
}

class AdminStatisticsContent extends StatelessWidget {
  const AdminStatisticsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection("Summary", _buildSummaryCards()),
          _buildSection("User Analytics", _buildUserAnalytics()),
          _buildSection("Business Partner Analytics", _buildPartnerAnalytics()),
          _buildSection("Recipe Analytics", _buildRecipeAnalytics()),
          _buildSection("Report Analytics", _buildReportAnalytics()),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildSummaryCard("Active Users", "100", Colors.blueAccent),
        _buildSummaryCard("Active Partners", "10", Colors.greenAccent),
        _buildSummaryCard("Recipes", "5.8K", Colors.orangeAccent),
        _buildSummaryCard("Reports", "8", Colors.redAccent),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    final bgColor = color.withAlpha((0.1 * 255).toInt()); // 10% opacity
    final borderColor = color.withAlpha((0.3 * 255).toInt()); // 30% opacity



    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUserAnalytics() {
    return Column(
      children: [
        _buildChartRow([
          _buildPieChart(
              "User Status",
              [
                PieChartSectionData(value: 65, color: Colors.greenAccent, title: '65% Active'),
                PieChartSectionData(value: 20, color: Colors.blueAccent, title: '20% Inactive'),
                PieChartSectionData(value: 15, color: Colors.orangeAccent, title: '15% Suspended'),
              ],
              150),
          _buildPieChart(
              "Gender",
              [
                PieChartSectionData(value: 55, color: Colors.pink[200]!, title: '55% Female'),
                PieChartSectionData(value: 45, color: Colors.blue[200]!, title: '45% Male'),
              ],
              150),
        ]),
        const SizedBox(height: 20),
        _buildChartRow([
          _buildBarChart("Age Groups", ['18-25', '26-35', '36+'], [8, 5, 7]),
          _buildBarChart("Country", ['SG', 'MY', 'Other'], [12, 8, 5]),
        ]),
      ],
    );
  }

  Widget _buildPartnerAnalytics() {
    return Column(
      children: [
        _buildChartRow([
          _buildPieChart(
              "Business Status",
              [
                PieChartSectionData(value: 60, color: Colors.greenAccent, title: '60% Active'),
                PieChartSectionData(value: 20, color: Colors.blueAccent, title: '20% Inactive'),
                PieChartSectionData(value: 15, color: Colors.orangeAccent, title: '15% Pending'),
                PieChartSectionData(value: 5, color: Colors.redAccent, title: '5% Suspended'),
              ],
              150),
          _buildPieChart(
              "Business Type",
              [
                PieChartSectionData(value: 65, color: Colors.purpleAccent, title: '65% Food Vendor'),
                PieChartSectionData(value: 35, color: Colors.tealAccent, title: '35% Nutritionist'),
              ],
              150),
        ]),
        const SizedBox(height: 20),
        _buildBarChart("Country", ['SG', 'MY', 'Other'], [10, 7, 4]),
      ],
    );
  }

  Widget _buildChartRow(List<Widget> charts) {
    return Row(
      children: charts
          .map((chart) => Expanded(child: chart))
          .toList(),
    );
  }

  Widget _buildPieChart(String title, List<PieChartSectionData> sections, double size) {
    return _buildChartSection(title, SizedBox(
      height: size,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: size * 0.3,
        ),
      ),
    ));
  }

  Widget _buildBarChart(String title, List<String> labels, List<double> values) {
    return _buildChartSection(title, SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(
            labels.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [BarChartRodData(toY: values[index])],
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(labels[value.toInt()]),
                ),
              ),
            ),
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
          ),
          gridData: const FlGridData(show: false),
        ),
      ),
    ));
  }

  Widget _buildChartSection(String title, Widget chart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54)),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: chart,
        ),
      ],
    );
  }

  Widget _buildRecipeAnalytics() {
    return Column(
      children: [
        const ListTile(
          title: Text("Top 5 Recipes"),
          subtitle: Text("Most viewed/downloaded recipes"),
        ),
        Column(
          children: [
            _buildRecipeItem("Healthy Salad Bowl", "200 views"),
            _buildRecipeItem("Protein Smoothie", "150 views"),
            _buildRecipeItem("Vegan Burger", "100 views"),
            _buildRecipeItem("Chicken Meal Prep", "80 views"),
            _buildRecipeItem("Oatmeal Breakfast", "65 views"),
          ],
        ),
        const SizedBox(height: 16),
        _buildPieChart(
          "Category Distribution",
          [
            PieChartSectionData(value: 35, color: Colors.greenAccent, title: '35% Breakfast'),
            PieChartSectionData(value: 25, color: Colors.blueAccent, title: '25% Lunch'),
            PieChartSectionData(value: 20, color: Colors.orangeAccent, title: '20% Dinner'),
            PieChartSectionData(value: 20, color: Colors.purpleAccent, title: '20% Snacks'),
          ],
          200,
        ),
      ],
    );
  }

  Widget _buildReportAnalytics() {
    return Column(
      children: [
        _buildReportItem("Spam Content", "5 reports"),
        _buildReportItem("Inappropriate Recipe", "3 reports"),
      ],
    );
  }

  Widget _buildRecipeItem(String title, String subtitle) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildReportItem(String title, String subtitle) {
    return ListTile(
      leading: const Icon(Icons.report_problem, size: 20, color: Colors.redAccent),
      title: Text(title),
    );
  }
}
*/