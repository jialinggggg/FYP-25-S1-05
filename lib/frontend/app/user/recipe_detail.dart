import 'package:flutter/material.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final Function(Map<String, dynamic>) onFavourite;
  final bool isFavourite;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.onFavourite,
    required this.isFavourite,
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
            /// 🔹 Recipe Image (Optimized with a placeholder)
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Image.network(
                recipe["image"] ?? "https://via.placeholder.com/150",
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),

            /// 🔹 Recipe Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe["name"] ?? "No Title",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  /// 📌 **Calories, Time, Difficulty**
                  Row(
                    children: [
                      _buildInfoCard(Icons.local_fire_department, "${recipe["calories"] ?? 0} kcal"),
                      const SizedBox(width: 15),
                      _buildInfoCard(Icons.timer, "${recipe["time"] ?? 0} minutes"),
                      const SizedBox(width: 15),
                      _buildInfoCard(Icons.restaurant, "Easy"), // Placeholder Difficulty
                    ],
                  ),

                  const SizedBox(height: 15),

                  /// 📌 **Description**
                  Text(
                    recipe["description"] ?? "No description available.",
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),

                  /// 🥑 **Ingredients**
                  const Text(
                    "Ingredients",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (recipe["ingredients"] as List<dynamic>?)
                            ?.map((ingredient) => Text("• $ingredient", style: const TextStyle(fontSize: 16)))
                            .toList() ??
                        [const Text("• No ingredients available.")],
                  ),

                  const SizedBox(height: 15),
                  const Divider(),

                  /// 📜 **Instructions**
                  const Text(
                    "Instructions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (recipe["instructions"] as List<dynamic>?)
                            ?.map((instruction) => Text("• $instruction", style: const TextStyle(fontSize: 16)))
                            .toList() ??
                        [const Text("• No instructions available.")],
                  ),

                  const SizedBox(height: 20),

                  /// ✅ **Favourite Button**
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onFavourite(recipe); // Calls function to add to favourites

                        // Show message based on status
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
                        backgroundColor: isFavourite ? Colors.red : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        isFavourite ? "❌ Remove from Favourites" : "💚 Add to Favourites",
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