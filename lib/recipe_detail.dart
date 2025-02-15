import 'package:flutter/material.dart';


class RecipeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final Function(Map<String, dynamic>) onFavourite; // Callback function
  final bool isFavourite;

    const RecipeDetailScreen({
      super.key,
      required this.recipe,
      required this.onFavourite,
      required this.isFavourite, // ✅ Added
    });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Recipe Image
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Image.asset(recipe["image"], fit: BoxFit.cover),
            ),

            /// 🔹 Recipe Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe["name"],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  /// 📌 **Calories, Time, Difficulty**
                  Row(
                    children: [
                      _buildInfoCard(Icons.local_fire_department, "${recipe["calories"]} kcal"),
                      const SizedBox(width: 15),
                      _buildInfoCard(Icons.timer, "${recipe["time"]} minutes"),
                      const SizedBox(width: 15),
                      _buildInfoCard(Icons.restaurant, "Easy"), // Placeholder Difficulty
                    ],
                  ),

                  const SizedBox(height: 15),

                  /// 📌 **Description**
                  Text(
                    recipe["description"],
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),

                  /// 🥑 **Ingredients**
                  const Text("Ingredients", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (recipe["ingredients"] as List<String>)
                        .map((ingredient) => Text("• $ingredient", style: const TextStyle(fontSize: 16)))
                        .toList(),
                  ),

                  const SizedBox(height: 15),
                  const Divider(),

                  /// 📜 **Instructions**
                  const Text("Instructions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (recipe["instructions"] as List<String>)
                        .asMap()
                        .entries
                        .map((entry) => Text(
                      "${entry.key + 1}. ${entry.value}",
                      style: const TextStyle(fontSize: 16),
                    ))
                        .toList(),
                  ),

                  const SizedBox(height: 20),

                  /// ✅ **Favourite Button**
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onFavourite(recipe); // Calls function to add to favourites

                        // ✅ Show message based on status
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFavourite ? "${recipe["name"]} removed from favourites!"
                                  : "${recipe["name"]} added to favourites!",
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFavourite ? Colors.red : Colors.green, // ✅ Change color
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        isFavourite ? "❌ Remove from Favourites" : "💚 Add to Favourites", // ✅ Toggle text
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
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


  /// 🔹 **Reusable Info Card Widget**
  Widget _buildInfoCard(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}