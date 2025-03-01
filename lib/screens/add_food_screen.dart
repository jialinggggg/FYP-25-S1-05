import 'package:flutter/material.dart';

class AddFoodScreen extends StatefulWidget {
  final String mealType;
  final List<Map<String, dynamic>> existingFoods;

  const AddFoodScreen({super.key, required this.mealType, required this.existingFoods});

  @override
  AddFoodScreenState createState() => AddFoodScreenState();
}

class AddFoodScreenState extends State<AddFoodScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> allFoods = [
    {
      "name": "Tomato and Garlic Pasta",
      "calories": "176 kcal",
      "carbs": "35.1 g",
      "protein": "5.6 g",
      "fat": "1.8 g",
      "category": "Recipe",
    },
    {
      "name": "Avocado Toast",
      "calories": "220 kcal",
      "carbs": "18.5 g",
      "protein": "4.2 g",
      "fat": "12.3 g",
      "category": "Snack",
    },
    {
      "name": "Grilled Chicken",
      "calories": "210 kcal",
      "carbs": "0 g",
      "protein": "30 g",
      "fat": "5 g",
      "category": "Protein",
    },
  ];

  List<Map<String, dynamic>> displayedFoods = [];
  List<Map<String, dynamic>> selectedFoods = [];

  @override
  void initState() {
    super.initState();
    displayedFoods = List.from(allFoods);
    selectedFoods = List.from(widget.existingFoods);
    _searchController.addListener(filterFoods);
  }

  void filterFoods() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      displayedFoods = allFoods.where((food) => food["name"].toLowerCase().contains(query)).toList();
    });
  }

  void addFood(Map<String, dynamic> food) {
    setState(() {
      if (!selectedFoods.any((f) => f["name"] == food["name"])) {
        selectedFoods.add(food);
      }
    });
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
          onPressed: () => Navigator.pop(context, selectedFoods),
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

            // Selected Food Section
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

            // Done Button (Passes Selected Foods Back)
            SizedBox(
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
                  Navigator.pop(context, selectedFoods); // Send updated food list back
                },
                child: const Text(
                  "Done",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
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
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.restaurant, size: 80, color: Colors.grey),
          const SizedBox(height: 10),
          const Text(
            "Your Plate is Empty—Fill It Up!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFoodTile(Map<String, dynamic> food, int index) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(food["name"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () {
                    removeFood(index);
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("1 serving (250 g)", style: TextStyle(color: Colors.grey[600])),
                Text(food["calories"], style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMacroDetail(food["carbs"], "Carbs"),
                _buildMacroDetail(food["protein"], "Protein"),
                _buildMacroDetail(food["fat"], "Fat"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultTile(Map<String, dynamic> food) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(food["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(food["calories"]),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
          onPressed: () {
            addFood(food);
          },
        ),
      ),
    );
  }

  Widget _buildMacroDetail(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}