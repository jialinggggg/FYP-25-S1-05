import 'package:flutter/material.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';
import 'recipe_detail_page.dart';

class RecipeManagementPage extends StatefulWidget {
  const RecipeManagementPage({super.key});

  @override
  RecipeManagementPageState createState() => RecipeManagementPageState();
}

class RecipeManagementPageState extends State<RecipeManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String selectedStatus = "All"; // Default filter value
  List<Map<String, String>> filteredRecipes = [];

  List<Map<String, String>> recipes = [
    {
      "title": "Morning Toast",
      "submitter": "John",
      "date": "1/1/2025",
      "status": "Pending",
      "image": "morning_toast.png",
    },
    {
      "title": "Beef with Broccoli",
      "submitter": "Ken",
      "date": "15/12/2024",
      "status": "Approved",
      "image": "beef_broccoli.png",
    },
    {
      "title": "Avocado Salad",
      "submitter": "Emma",
      "date": "10/11/2024",
      "status": "Rejected",
      "image": "avocado_salad.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    filteredRecipes = List.from(recipes);
    _searchController.addListener(_filterRecipes);
  }

  void _filterRecipes() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      filteredRecipes = recipes.where((recipe) {
        bool matchesQuery = recipe["title"]!.toLowerCase().contains(query) ||
            recipe["submitter"]!.toLowerCase().contains(query);

        bool matchesStatus = selectedStatus == "All" || recipe["status"] == selectedStatus;

        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  ///Function to update the recipe status
  void _updateRecipeStatus(String title, String newStatus) {
    setState(() {
      for (var recipe in recipes) {
        if (recipe["title"] == title) {
          recipe["status"] = newStatus;
          break;
        }
      }
      _filterRecipes();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterRecipes);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: SingleChildScrollView(
        padding: isWideScreen
            ? EdgeInsets.symmetric(horizontal: 100, vertical: 20)
            : EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///Search Bar & Status Dropdown
            Row(
              children: [
                ///Search Bar
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search for recipes",
                      prefixIcon: Icon(Icons.search, color: Colors.black54),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),

                ///Dropdown Filter
                SizedBox(
                  width: 150, // Adjust width as needed
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
                        _filterRecipes();
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
            SizedBox(height: 20),

            ///List of Recipes
            filteredRecipes.isEmpty
                ? Center(
              child: Text(
                "No recipes found",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: filteredRecipes.length,
              itemBuilder: (context, index) {
                final recipe = filteredRecipes[index];

                return GestureDetector(
                  onTap: () {
                    ///Navigate to Recipe Detail Page & Pass Recipe Data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailPage(
                          recipe: recipe,
                          onStatusChanged: _updateRecipeStatus,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        ///Recipe Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            recipe["image"]!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 10),

                        ///Recipe Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe["title"]!,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text("Submitter: ${recipe["submitter"]}", style: TextStyle(fontSize: 14)),
                              Text("Date: ${recipe["date"]}", style: TextStyle(fontSize: 14)),
                              Text(
                                "Status: ${recipe["status"]}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: recipe["status"] == "Approved"
                                      ? Colors.green
                                      : recipe["status"] == "Rejected"
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}