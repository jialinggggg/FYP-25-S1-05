import 'dart:convert';
import 'package:http/http.dart' as http;
import '../entities/spoonacular_recipe.dart';

class SpoonacularApiService {
  static const String _apiKey = '4a3dbd9522034168aad4673d5bf2e193';
  static const String _baseUrl = 'https://api.spoonacular.com';

  Future<List<Map<String, dynamic>>> searchIngredients({
    required String query,
    int number = 10,
    bool metaInformation = false,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/food/ingredients/search?apiKey=$_apiKey'
          '&query=$query'
          '&number=$number'
          '&metaInformation=$metaInformation',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = List<Map<String, dynamic>>.from(data['results'] ?? []);

        return results.map((ingredient) {
          // Format the image URL if available
          String? imageUrl = ingredient['image'];
          if (imageUrl != null && !imageUrl.startsWith('http')) {
            imageUrl = 'https://spoonacular.com/cdn/ingredients_100x100/$imageUrl';
          }

          return {
            'id': ingredient['id'],
            'name': ingredient['name'] ?? 'No Name',
            'image': imageUrl,
            'aisle': ingredient['aisle'] ?? 'Unknown aisle',
            'possibleUnits': List<String>.from(ingredient['possibleUnits'] ?? []),
          };
        }).toList();
      } else {
        throw 'API request failed with status ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      throw 'Failed to search ingredients: $e';
    }
  }

  Future<Map<String, dynamic>> getIngredientInfo(
    int id, {
    String? unit,
    double? amount,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/food/ingredients/$id/information?apiKey=$_apiKey'
        '${unit != null ? '&unit=$unit' : ''}'
        '${amount != null ? '&amount=$amount' : ''}',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Format the image URL if available
        String? imageUrl = data['image'];
        if (imageUrl != null && !imageUrl.startsWith('http')) {
          imageUrl = 'https://spoonacular.com/cdn/ingredients_100x100/$imageUrl';
        }

        return {
          'id': data['id'],
          'name': data['name'] ?? 'No Name',
          'image': imageUrl,
          'aisle': data['aisle'] ?? 'Unknown aisle',
          'possibleUnits': List<String>.from(data['possibleUnits'] ?? []),
          'nutrition': data['nutrition'] ?? {},
          'category': data['category'] ?? 'Unknown category',
          'consistency': data['consistency'] ?? 'Unknown',
          'shoppingListUnits': List<String>.from(data['shoppingListUnits'] ?? []),
        };
      } else {
        throw 'API request failed with status ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      throw 'Failed to get ingredient information: $e';
    }
  }

  Future<SpoonacularRecipe?> fetchRecipeById(int recipeId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/recipes/$recipeId/information?includeNutrition=true&apiKey=$_apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SpoonacularRecipe.fromJson(data);
    } else {
      print('Failed to fetch recipe: ${response.statusCode}');
      return null;
    }
  }

  Future<List<SpoonacularRecipe>> fetchRecipes({
    String? category,
    int? minCalories,
    int? maxCalories,
    int number = 10,
  }) async {
    String query = '$_baseUrl/recipes/complexSearch?apiKey=$_apiKey&number=$number&addRecipeNutrition=true';

    if (category != null) {
      query += '&diet=$category';
    }
    if (minCalories != null && maxCalories != null) {
      query += '&minCalories=$minCalories&maxCalories=$maxCalories';
    }

    final response = await http.get(Uri.parse(query));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'] ?? [];
      return results.map((json) => SpoonacularRecipe.fromJson(json)).toList();
    } else {
      print('Failed to fetch recipes: ${response.statusCode}');
      return [];
    }
  }
}