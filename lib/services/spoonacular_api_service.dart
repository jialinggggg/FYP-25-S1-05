import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SpoonacularApiService {
  // Private constructor
  SpoonacularApiService._instantiate();

  // Singleton instance
  static final SpoonacularApiService _instance = SpoonacularApiService._instantiate();

  // Factory constructor to return the singleton instance
  factory SpoonacularApiService() {
    return _instance;
  }

  final String _baseURL = 'api.spoonacular.com';
  static const String apiKey = "4a3dbd9522034168aad4673d5bf2e193";
  

  Future<List<Map<String, dynamic>>> fetchRandomRecipes({
    String? tags,
    int? minCalories,
    int? maxCalories,
    int number = 5,
  }) async {
    Map<String, String> parameters = {
      'number': number.toString(),
      'apiKey': apiKey,
      'includeNutrition': 'true',
    };
    
    if (tags != null) parameters['tags'] = tags;
    if (minCalories != null) parameters['minCalories'] = minCalories.toString();
    if (maxCalories != null) parameters['maxCalories'] = maxCalories.toString();

    Uri uri = Uri.https(_baseURL, '/recipes/random', parameters);
    
    try {
      var response = await http.get(uri);
      
      Map<String, dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> recipes = List.from(data["recipes"]);
      
      // Map the recipes to include consistent nutrition data
      return recipes.map((recipe) {
        return {
          ...recipe,
          "nutrition": recipe["nutrition"] ?? {},
          "calories": recipe["nutrition"]?["nutrients"]?.firstWhere(
            (nutrient) => nutrient["name"]?.toLowerCase() == "calories",
            orElse: () => {"amount": 0},
          )["amount"]?.round() ?? 0,
        };
      }).toList();
      
    } catch (err) {
      throw err.toString();
    }
  }

  Future<Map<String, dynamic>> fetchRecipeDetails(String id) async {
    Map<String, String> parameters = {
      'apiKey': apiKey,
      'includeNutrition': 'true',
    };

    Uri uri = Uri.https(_baseURL, '/recipes/$id/information', parameters);
    
    try {
      var response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // First validate if the response is valid JSON
        try {
          Map<String, dynamic> data = json.decode(response.body);
          final mappedData = _mapRecipeData(data);
          return mappedData;
        } catch (e) {
          throw 'Failed to parse recipe data: $e';
        }
      } else {
        throw 'API request failed with status ${response.statusCode}: ${response.body}';
      }
    } catch (err) {
      throw 'Network error: $err';
    }
  }

  Future<List<Map<String, dynamic>>> searchRecipes({
    required String query,
    int number = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.https(
          _baseURL, 
          '/recipes/complexSearch',
          {
            'apiKey': apiKey,
            'query': query,
            'number': number.toString(),
          },
        ),
      );

      final data = json.decode(response.body);
      final results = List<Map<String, dynamic>>.from(data['results'] ?? []);

      return results.map((recipe) {
        // Fix image URL if needed
        String? imageUrl = recipe['image'];
        if (imageUrl != null && !imageUrl.startsWith('http')) {
          imageUrl = 'https://spoonacular.com/recipeImages/$imageUrl';
        }

        return {
          'id': recipe['id'],
          'name': recipe['title'] ?? 'No Title',
          'image': imageUrl,
          'readyInMinutes': recipe['readyInMinutes'] ?? 0,
        };
      }).toList();
    } catch (e) {
      throw 'Failed to search recipes: $e';
    }
  }

  Map<String, dynamic> _mapRecipeData(Map<String, dynamic> recipe) {
    // Helper function to safely extract nutrient amounts
    double _getNutrientValue(List<dynamic>? nutrients, String name) {
      if (nutrients == null) return 0.0;
      final nutrient = nutrients.firstWhere(
        (n) => (n["name"] as String?) == name,
        orElse: () => {"amount": 0.0},
      );
      return (nutrient["amount"] as num?)?.toDouble() ?? 0.0;
    }

    final nutrients = recipe["nutrition"]?["nutrients"] as List<dynamic>?;

    // Add image URL validation
    String? imageUrl = recipe["image"];
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl = 'https://spoonacular.com/recipeImages/$imageUrl';
    }

    return {
      "image": imageUrl ?? "https://via.placeholder.com/150",
      "name": recipe["title"] ?? "No Title",
      "calories": _getNutrientValue(nutrients, "Calories").round(), // Keep rounded for calories
      "fats": _getNutrientValue(nutrients, "Fat"), // Exact value (e.g., 6.91)
      "protein": _getNutrientValue(nutrients, "Protein"), // Exact value
      "carbs": _getNutrientValue(nutrients, "Carbohydrates"), // Exact value
      "time": (recipe["readyInMinutes"] as num?)?.toInt() ?? 0,
      "ingredients": recipe["extendedIngredients"]
          ?.map<String>((ingredient) => ingredient["original"].toString())
          .toList() ?? ["No ingredients available."],
      "instructions": recipe["analyzedInstructions"]?.isNotEmpty == true
          ? recipe["analyzedInstructions"][0]["steps"]
              ?.map<String>((step) => step["step"].toString())
              .toList() ?? ["No instructions available."]
          : ["No instructions available."],
      "diets": (recipe["diets"] as List<dynamic>?)?.map((d) => d.toString()).toList() ?? [],
      "sourceName": recipe["sourceName"] ?? "Unknown source",
    };
  }

  Future<List<Map<String, dynamic>>> searchIngredients({
    required String query,
    int number = 10,
    bool metaInformation = false,
  }) async {
    try {
      final response = await http.get(
        Uri.https(
          _baseURL,
          '/food/ingredients/search',
          {
            'apiKey': apiKey,
            'query': query,
            'number': number.toString(),
            'metaInformation': metaInformation.toString(),
          },
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

Future<Map<String, dynamic>> getIngredientInfo(int id, {String? unit, double? amount}) async {
  try {
    final parameters = {
      'apiKey': apiKey,
      if (unit != null) 'unit': unit,
      if (amount != null) 'amount': amount.toString(),
    };

    final response = await http.get(
      Uri.https(
        _baseURL,
        '/food/ingredients/$id/information',
        parameters,
      ),
    );

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

  Future<Map<String, dynamic>> fetchMeal(int id) async {
    Map<String, String> parameters = {
      'apiKey': apiKey,
    };

    Uri uri = Uri.https(_baseURL, '/recipes/$id/information', parameters);
    Map<String, String> headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
    };

    try {
      var response = await http.get(uri, headers: headers);
      Map<String, dynamic> mealData = json.decode(response.body);
      return mealData;
    } catch (err) {
      throw err.toString();
    }
  }

  Future<List<Map<String, dynamic>>> searchMeals(String query) async {
  Map<String, String> parameters = {
    'apiKey': apiKey,
    'query': query,
    'addRecipeNutrition': 'true',
    'number': '10',
  };

  Uri uri = Uri.https(_baseURL, '/recipes/complexSearch', parameters);
  Map<String, String> headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
  };

  try {
    var response = await http.get(uri, headers: headers);
    Map<String, dynamic> data = json.decode(response.body);
    List<Map<String, dynamic>> meals = List.from(data["results"] ?? []); // Handle null results
    return meals;
  } catch (err) {
    throw err.toString();
  }
}
}