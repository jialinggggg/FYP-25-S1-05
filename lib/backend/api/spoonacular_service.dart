import 'dart:convert';
import 'package:http/http.dart' as http;
import '../entities/recipes.dart';
import '../entities/analyzed_instruction.dart';
import '../entities/extended_ingredient.dart';
import '../entities/nutrition.dart';


class SpoonacularService {
  static const String _apiKey = 'c7d01e732db448c09ab3be35a5aef922'; // Replace with your actual API key
  static const String _baseUrl = 'https://api.spoonacular.com';

  Future<List<Map<String, dynamic>>> searchIngredients({
    required String query,
    int number = 3,
    int offset = 0,
    bool metaInformation = true,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/food/ingredients/autocomplete?apiKey=$_apiKey'
          '&query=$query'
          '&number=$number'
          '&offset=$offset'
          '&metaInformation=$metaInformation',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          return {
            'id': item['id'],
            'name': item['name'],
            'image': item['image'] != null 
                ? 'https://spoonacular.com/cdn/ingredients_100x100/${item['image']}'
                : null,
          };
        }).toList();
      } else {
        throw Exception('Failed to load ingredients: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search ingredients: $e');
    }
  }

  Future<ExtendedIngredient> getIngredientInformation(
    int id, {
    String? unit,
    double? amount,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/food/ingredients/$id/information?apiKey=$_apiKey'
          '${unit != null ? '&unit=$unit' : ''}'
          '${amount != null ? '&amount=$amount' : ''}',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Parse nutrition data
        List<Nutrient> nutrients = [];
        if (data['nutrition'] != null && data['nutrition']['nutrients'] != null) {
          nutrients = (data['nutrition']['nutrients'] as List)
              .map((n) => Nutrient(
                    title: n['name'],
                    amount: (n['amount'] as num).toDouble(),
                    unit: n['unit'],
                  ))
              .toList();
        }

        return ExtendedIngredient(
          id: data['id'],
          name: data['name'],
          amount: amount ?? 100,
          unit: unit ?? (List<String>.from(data['possibleUnits'] ?? ['g'])).first,
          possibleUnits: List<String>.from(data['possibleUnits'] ?? ['g']),
          nutrition: Nutrition(nutrients: nutrients),
        );
      } else {
        throw Exception('Failed to load ingredient info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get ingredient information: $e');
    }
  }

  Future<List<Recipes>> fetchRecipes({
    String? query,
    int limit = 5,
    String? type, // For meal types: 'breakfast', 'lunch', etc.
    String? diet, // For dietary restrictions
    String? cuisine, // For specific cuisines
    String? intolerances, // For food intolerances
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/recipes/complexSearch?apiKey=$_apiKey'
          '${query != null ? '&query=$query' : ''}'
          '&number=$limit'
          '${type != null ? '&type=$type' : ''}'
          '${diet != null ? '&diet=$diet' : ''}'
          '${cuisine != null ? '&cuisine=$cuisine' : ''}'
          '${intolerances != null ? '&intolerances=$intolerances' : ''}'
          '&addRecipeNutrition=true'
          '&fillIngredients=true'
          '&instructionsRequired=true'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List).map((recipe) { 
          // Handle nutrition data
          Nutrition? nutrition;
          if (recipe['nutrition'] != null) {
            final nutrients = <Nutrient>[];
            
            if (recipe['nutrition']['nutrients'] != null) {
              for (var nutrient in recipe['nutrition']['nutrients']) {
                nutrients.add(Nutrient(
                  title: nutrient['name'],
                  amount: (nutrient['amount'] as num).toDouble(),
                  unit: nutrient['unit'],
                ));
              }
            }
            
            nutrition = Nutrition(nutrients: nutrients);
          }

          return Recipes(
            id: recipe['id'] as int,
            title: recipe['title'],
            image: recipe['image'],
            imageType: recipe['imageType'] ?? 'jpg',
            readyInMinutes: recipe['readyInMinutes'] ?? 0,
            servings: recipe['servings'] ?? 1,
            sourceName: recipe['sourceName'] ?? 'Spoonacular',
            sourceType: "spoonacular",
            analyzedInstructions: (recipe['analyzedInstructions'] as List?)?.map((i) => 
              AnalyzedInstruction(
                name: i['name'] ?? '',
                steps: (i['steps'] as List).map((step) => 
                  InstructionStep(
                    number: step['number'],
                    step: step['step'],
                  )
                ).toList(),
              )
            ).toList(),
            extendedIngredients: (recipe['extendedIngredients'] as List?)?.map((i) => 
              ExtendedIngredient(
                id: i['id'],
                name: i['name'] ?? i['original'] ?? 'Unknown ingredient',
                amount: (i['amount'] as num).toDouble(),
                unit: i['unit'] ?? '',
              )
            ).toList(),
            diets: List<String>.from(recipe['diets'] ?? []),
            dishTypes: List<String>.from(recipe['dishTypes'] ?? []),
            nutrition: nutrition,
          );
        }).toList();
      } else {
        throw Exception('Failed to load recipes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch Spoonacular recipes: $e');
    }
  }

  // Fetch Spoonacular recipe details by recipeId
  Future<Recipes> fetchRecipeById(int recipeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/recipes/$recipeId/information?apiKey=$_apiKey&addRecipeNutrition=true&fillIngredients=true&instructionsRequired=true'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Nutrition? nutrition;

        // 2. Check if nutrition exists in main response
        if (data['nutrition'] != null) {
          nutrition = _parseNutrition(data['nutrition']);
        } 
        // 3. If missing, make secondary API call
        else {
          final nutritionResponse = await http.get(
            Uri.parse('$_baseUrl/recipes/$recipeId/nutritionWidget.json?apiKey=$_apiKey'),
          );
          
          if (nutritionResponse.statusCode == 200) {
            nutrition = _parseNutrition(json.decode(nutritionResponse.body));
          }
        }

        // Return a single recipe object
        final recipe = Recipes(
          id: data['id'] as int,
          title: data['title'],
          image: data['image'],
          imageType: data['imageType'] ?? 'jpg',
          readyInMinutes: data['readyInMinutes'] ?? 0,
          servings: data['servings'] ?? 1,
          sourceName: data['sourceName'] ?? 'Spoonacular',
          sourceType: "spoonacular",
          analyzedInstructions: (data['analyzedInstructions'] as List?)
              ?.map((i) => AnalyzedInstruction(
                    name: i['name'] ?? '',
                    steps: (i['steps'] as List)
                        .map((step) => InstructionStep(
                              number: step['number'],
                              step: step['step'],
                            ))
                        .toList(),
                  ))
              .toList(),
          extendedIngredients: (data['extendedIngredients'] as List?)
              ?.map((i) => ExtendedIngredient(
                    id: i['id'],
                    name: i['name'] ?? i['original'] ?? 'Unknown ingredient',
                    amount: (i['amount'] as num).toDouble(),
                    unit: i['unit'] ?? '',
                  ))
              .toList(),
          diets: List<String>.from(data['diets'] ?? []),
          dishTypes: List<String>.from(data['dishTypes'] ?? []),
          nutrition: nutrition,  // Nutrition is now safely assigned
        );
        return recipe;
      } else {
        throw Exception("Error fetching Spoonacular recipe details");
      }
    } catch (e) {
      throw Exception("Error fetching Spoonacular recipe: $e");
    }
  }

  // Parse nutrition from the main recipe endpoint
  Nutrition _parseNutrition(Map<String, dynamic> nutritionJson) {
    final nutrients = <Nutrient>[];
    
    // Simply pass through all nutrients exactly as they come from the API
    if (nutritionJson['nutrients'] != null) {
      for (var nutrient in nutritionJson['nutrients']) {
        try {
          nutrients.add(Nutrient(
            title: nutrient['name']?.toString() ?? 'Unnamed Nutrient',
            amount: (nutrient['amount'] as num?)?.toDouble() ?? 0,
            unit: nutrient['unit']?.toString() ?? '',
          ));
        } catch (e) {
          // Skip malformed nutrient entries but log the error
          throw Exception('Failed to parse nutrient: $e');
        }
      }
    }
    return Nutrition(nutrients: nutrients);
  }
}