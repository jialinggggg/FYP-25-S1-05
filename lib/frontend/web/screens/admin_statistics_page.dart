import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nutri_app/backend/api/spoonacular_api_service.dart';
import 'package:nutri_app/backend/controller/admin_statistics_controller.dart';
import 'login_page.dart';
import 'recipe_management_page.dart';
import 'manage_accounts_page.dart';
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
    const FeedbackPage(),
  ];

  final List<String> _titles = [
    "Admin Statistics",
    "Recipe and Product Management",
    "Account Management",
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
                  _buildDrawerItem("Management", 1),
                  _buildDrawerItem("Accounts", 2),
                  _buildDrawerItem("Feedback", 3),
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
      _buildNavItem("Management", 1),
      _buildNavItem("Accounts", 2),
      _buildNavItem("Feedback", 3),
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
    final controller = AdminStatisticsController(
      supabase: Supabase.instance.client,
      apiService: SpoonacularApiService(),
    );

    return FutureBuilder<Map<String, dynamic>>(
      future: controller.fetchStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryCards(stats),
              _buildSection("User Analytics", _buildUserAnalytics(stats)),
              _buildSection("Business Partner Analytics", _buildPartnerAnalytics(stats)),
              _buildSection("Recipe Analytics", _buildRecipeAnalytics(stats)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
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

  Widget _buildSummaryCards(Map<String, dynamic> stats) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildSummaryCard("Active Users", "${stats['activeUsers']}", Colors.blueAccent),
        _buildSummaryCard("Active Businesses", "${stats['activeBusinesses']}", Colors.greenAccent),
        _buildSummaryCard("Active Nutritionists", "${stats['activeNutritionists']}", Colors.orangeAccent),
        _buildSummaryCard("Recipes", "${stats['recipeCount']}", Colors.purpleAccent),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    final bgColor = color.withAlpha((0.1 * 255).toInt());
    final borderColor = color.withAlpha((0.3 * 255).toInt());

    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(10),
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
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUserAnalytics(Map<String, dynamic> stats) {
    final gender = stats['genderCount'] as Map<String, int>;
    final ageGroups = stats['ageGroups'] as Map<String, int>;
    final country = stats['countryCount'] as Map<String, int>;

    return Column(
      children: [
        _buildChartRow([
          _buildPieChart(
              "Gender Distribution",
              [
                PieChartSectionData(value: gender['Female']?.toDouble() ?? 0, color: Colors.pink[200]!, title: '${gender['Female']} Female'),
                PieChartSectionData(value: gender['Male']?.toDouble() ?? 0, color: Colors.blue[200]!, title: '${gender['Male']} Male'),
              ],
              150)
        ]),
        const SizedBox(height: 20),
        _buildChartRow([
          _buildBarChart("Age Groups", ageGroups.keys.toList(), ageGroups.values.map((v) => v.toDouble()).toList()),
          _buildBarChart("Country", country.keys.toList(), country.values.map((v) => v.toDouble()).toList()),
        ]),
      ],
    );
  }

  Widget _buildPartnerAnalytics(Map<String, dynamic> stats) {
    final businessTypes = stats['businessTypes'] as Map<String, int>;
    final businessCountries = stats['businessCountries'] as Map<String, int>;

    return Column(
      children: [
        _buildChartRow([
          _buildPieChart(
              "Partner Types",
              businessTypes.entries.map((e) {
                final color = e.key == 'Food & Meal Providers' ? Colors.purpleAccent : Colors.greenAccent;
                return PieChartSectionData(value: e.value.toDouble(), color: color, title: '${e.value} ${e.key}');
              }).toList(),
              150),
          _buildBarChart("Country of Business", businessCountries.keys.toList(), businessCountries.values.map((v) => v.toDouble()).toList()),
        ]),
      ],
    );
  }

  Widget _buildChartRow(List<Widget> charts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: charts
          .map((chart) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: chart,
        ),
      ))
          .toList(),
    );
  }


  Widget _buildPieChart(String title, List<PieChartSectionData> sections, double size) {
    return _buildChartSection(
      title,
      Padding(
        padding: const EdgeInsets.all(20),  // Increased padding inside the pie chart box
        child: SizedBox(
          height: size,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: size * 0.3,
            ),
          ),
        )
      )
    );
  }

  Widget _buildBarChart(String title, List<String> labels, List<double> values) {
    return _buildChartSection(
      title,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),  // More padding inside the bar chart box
        child: SizedBox(
          height: 150,
          child: BarChart(
            BarChartData(
              barGroups: List.generate(
                labels.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [BarChartRodData(
                    toY: values[index],
                    width: 16,
                    borderRadius: BorderRadius.circular(6),
                  ),],
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
        )
      )
    );
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
                color: Colors.black54
            )
          ),
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

  Widget _buildRecipeAnalytics(Map<String, dynamic> stats) {
    final topRecipes = stats['topRecipes'] as List<String>;
    final dishTypeDist = (stats['dishTypeDistribution'] as Map<String, int>)
        .entries
        .where((e) => e.value > 0)
        .fold<Map<String, int>>({}, (map, e) {
      map[e.key] = e.value;
      return map;
    });

    return Column(
      children: [
        const ListTile(
          title: Text("Top 5 Recipes"),
          subtitle: Text("Most favourited recipes"),
        ),
        Column(
          children: topRecipes.map((r) {
            final match = RegExp(r'^(.*) \((\d+ favs)\)$').firstMatch(r);
            if (match != null) {
              final title = match.group(1) ?? 'Unknown';
              final favCount = match.group(2) ?? '0 favs';
              return _buildRecipeItem(title, favCount);
            }
            return _buildRecipeItem(r, '0 favs');
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildPieChart(
          "Category Distribution",
          dishTypeDist.entries.map((e) {
            Color color;
            switch (e.key) {
              case 'Breakfast':
                color = Colors.cyanAccent;
                break;
              case 'Lunch':
                color = Colors.indigoAccent;
                break;
              case 'Dinner':
                color = Colors.orangeAccent;
                break;
              case 'Snack':
                color = Colors.redAccent;
                break;
              case 'Dessert':
                color = Colors.pinkAccent;
                break;
              case 'Appetizer':
                color = Colors.yellowAccent;
                break;
              case 'Main Course':
                color = Colors.tealAccent;
                break;
              case 'Side Dish':
                color = Colors.amberAccent;
                break;
              default:
                color = Colors.purpleAccent;
                break;
            }
            return PieChartSectionData(
              value: e.value.toDouble(),
              color: color,
              title: '${e.value} ${e.key}',
            );
          }).toList(),
          200,
        ),
      ],
    );
  }

  Widget _buildRecipeItem(String title, String subtitle) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}