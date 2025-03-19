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
  static const String apiKey = "fede250789e24f828573be12cb0d08a8";

  Future<List<Map<String, dynamic>>> fetchRandomRecipes({String? tags, int number = 5}) async {
    Map<String, String> parameters = {
      'number': number.toString(),
      'apiKey': apiKey,
    };
    if (tags != null) {
      parameters['tags'] = tags;
    }

    Uri uri = Uri.https(_baseURL, '/recipes/random', parameters);
    Map<String, String> headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
    };

    try {
      var response = await http.get(uri, headers: headers);
      Map<String, dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> recipes = List.from(data["recipes"]);
      return recipes;
    } catch (err) {
      throw err.toString();
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