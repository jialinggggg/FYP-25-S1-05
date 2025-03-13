import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AddFoodScreen extends StatefulWidget {
  final String mealType;
  final List<Map<String, dynamic>> existingFoods;

  const AddFoodScreen({super.key, required this.mealType, required this.existingFoods});

  @override
  AddFoodScreenState createState() => AddFoodScreenState();
}

class AddFoodScreenState extends State<AddFoodScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  Timer? _debounce;

  // Cache to store search results to avoid redundant API calls
  final Map<String, List<Map<String, dynamic>>> _searchCache = {};

  List<Map<String, dynamic>> displayedFoods = [];
  List<Map<String, dynamic>> selectedFoods = [];

  // Spoonacular API Key
  final String apiKey = "fede250789e24f828573be12cb0d08a8";

  @override
  void initState() {
    super.initState();
    selectedFoods = List.from(widget.existingFoods);

    // Debounce the search to reduce API calls
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _searchFoods(_searchController.text);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// 🔍 Fetch food data from Spoonacular API with caching
  Future<void> _searchFoods(String query) async {
    if (query.isEmpty) {
      setState(() {
        displayedFoods = [];
      });
      return;
    }

    // If we've already searched this query, use cached results.
    if (_searchCache.containsKey(query)) {
      setState(() {
        displayedFoods = _searchCache[query]!;
      });
      return;
    }

    final url =
        'https://api.spoonacular.com/food/ingredients/search?query=$query&number=10&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List<dynamic> results = jsonResponse['results'] ?? [];

        // Fetch detailed info for each food item
        List<Map<String, dynamic>> tempFoods = [];
        for (var food in results) {
          String foodName = food["name"] ?? "No Name";
          int foodId = food["id"];

          final detailedResponse = await _getFoodDetails(foodId);

          tempFoods.add({
            "name": foodName,
            "calories": detailedResponse["calories"]?.toString() ?? "N/A",
            "carbs": detailedResponse["carbs"]?.toString() ?? "N/A",
            "protein": detailedResponse["protein"]?.toString() ?? "N/A",
            "fat": detailedResponse["fat"]?.toString() ?? "N/A",
            "category": "Ingredient",
          });
        }

        // Cache the results for this query
        _searchCache[query] = tempFoods;

        setState(() {
          displayedFoods = tempFoods;
        });
      } else if (response.statusCode == 402) {
        print("Error fetching data: 402 Payment Required. Check your API quota.");
        setState(() {
          displayedFoods = [];
        });
      } else if (response.statusCode == 429) {
        print("Error fetching data: 429 Too Many Requests. Slow down your requests.");
        setState(() {
          displayedFoods = [];
        });
      } else {
        print("Error fetching data: ${response.statusCode}");
        setState(() {
          displayedFoods = [];
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        displayedFoods = [];
      });
    }
  }

  /// Fetch detailed nutritional info for a specific food item
  Future<Map<String, dynamic>> _getFoodDetails(int foodId) async {
    final url =
        'https://api.spoonacular.com/food/ingredients/$foodId/information?apiKey=$apiKey&amount=1&unit=gram';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List<dynamic> nutrients = jsonResponse['nutrition']?['nutrients'] ?? [];

        double calories = 0;
        double carbs = 0;
        double protein = 0;
        double fat = 0;

        for (var nutrient in nutrients) {
          switch (nutrient['name']) {
            case 'Calories':
              calories = nutrient['amount']?.toDouble() ?? 0;
              break;
            case 'Carbohydrates':
              carbs = nutrient['amount']?.toDouble() ?? 0;
              break;
            case 'Protein':
              protein = nutrient['amount']?.toDouble() ?? 0;
              break;
            case 'Fat':
              fat = nutrient['amount']?.toDouble() ?? 0;
              break;
          }
        }

        return {
          "calories": calories,
          "carbs": carbs,
          "protein": protein,
          "fat": fat,
        };
      } else if (response.statusCode == 402) {
        print("Error fetching detailed food info: 402 Payment Required.");
      } else if (response.statusCode == 429) {
        print("Error fetching detailed food info: 429 Too Many Requests.");
      } else {
        print("Error fetching detailed food info: ${response.statusCode}");
      }
      return {
        "calories": 0,
        "carbs": 0,
        "protein": 0,
        "fat": 0,
      };
    } catch (e) {
      print("Error: $e");
      return {
        "calories": 0,
        "carbs": 0,
        "protein": 0,
        "fat": 0,
      };
    }
  }

  /// ✅ Insert selected food into Supabase
  Future<void> addFood(Map<String, dynamic> food) async {
    print("Received food data: $food");

    String name = food["name"] ?? "Unknown";
    String type = food["category"] ?? "Unknown";

    if (name == "Unknown" || type == "Unknown") {
      print("Error: Missing required name or meal type.");
      return;
    }

    int calories = _parseInt(food["calories"]);
    double carbs = _parseFloat(food["carbs"]);
    double protein = _parseFloat(food["protein"]);
    double fats = _parseFloat(food["fat"]);

    print("Parsed values - calories: $calories, carbs: $carbs, protein: $protein, fats: $fats");

    try {
      final response = await supabase.from('meal_entries').insert({
        'name': name,
        'calories': calories,
        'carbs': carbs,
        'protein': protein,
        'fats': fats,
        'type': type,
      }).select();

      print("Supabase Response: $response");

      setState(() {
        selectedFoods.add(food);
      });
    } catch (e) {
      print("Supabase Insert Error: $e");
    }
  }

  int _parseInt(dynamic value) {
    if (value == null || value == "N/A") return 0;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    return value is int ? value : 0;
  }

  double _parseFloat(dynamic value) {
    if (value == null || value == "N/A") return 0.0;
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return value is double ? value : 0.0;
  }

  void removeFood(int index) {
    setState(() {
      selectedFoods.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.mealType, style: const TextStyle(color: Colors.black, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context, selectedFoods);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 10),
            const Text(
              "Nutrition Logged",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: selectedFoods.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: selectedFoods.length,
                            itemBuilder: (context, index) {
                              return _buildSelectedFoodTile(selectedFoods[index], index);
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Search Results",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: displayedFoods.isEmpty
                        ? const Center(child: Text("No food found!", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: displayedFoods.length,
                            itemBuilder: (context, index) {
                              return _buildSearchResultTile(displayedFoods[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context, selectedFoods);
            },
            child: const Text(
              "Done",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search food or recipes",
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFoodTile(Map<String, dynamic> food, int index) {
    return ListTile(
      title: Text(food["name"] ?? "No Name"),
      subtitle: Text(
          "${food["calories"] ?? "N/A"} kcal | ${food["carbs"] ?? "N/A"}g carbs | ${food["protein"] ?? "N/A"}g protein | ${food["fat"] ?? "N/A"}g fat"),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle, color: Colors.red),
        onPressed: () => removeFood(index),
      ),
    );
  }

  Widget _buildSearchResultTile(Map<String, dynamic> food) {
    return ListTile(
      title: Text(food["name"] ?? "No Name"),
      subtitle: Text(
          "${food["calories"] ?? "N/A"} kcal | ${food["carbs"] ?? "N/A"}g carbs | ${food["protein"] ?? "N/A"}g protein | ${food["fat"] ?? "N/A"}g fat"),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: Colors.green),
        onPressed: () => addFood(food),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text("No foods selected yet.", style: TextStyle(color: Colors.grey)),
    );
  }
}
