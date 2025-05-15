import 'package:collection/collection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/spoonacular_api_service.dart';

class AdminStatisticsController {
  final SupabaseClient supabase;
  final SpoonacularApiService apiService;

  AdminStatisticsController({
    required this.supabase,
    required this.apiService,
  });

  Future<Map<String, dynamic>> fetchStatistics() async {
    final Map<String, dynamic> stats = {};

    // Fetch accounts and convert to entity
    final accountResponse = await supabase
        .from('accounts')
        .select('uid, status, type')
        .eq('status', 'active');
    final accounts = accountResponse as List;

    final activeUserUids = accounts.where((a) => a['type'] == 'user').map((a) => a['uid']).toSet();
    final activeBusinessUids = accounts.where((a) => a['type'] == 'business' || a['type'] == 'nutritionist').map((a) => a['uid']).toSet();
    stats['activeUsers'] = activeUserUids.length;

    // Mocked report count
    stats['reportCount'] = 8;

    // User profiles
    final userResponse = await supabase.from('user_profiles').select('gender, birth_date, country');
    final users = userResponse as List;

    final genderCount = {'Male': 0, 'Female': 0};
    final countryCount = {'Singapore': 0, 'Malaysia': 0, 'Others': 0};
    final ageGroups = {'18-25': 0, '26-35': 0, '36+': 0};
    final now = DateTime.now();

    for (final user in users) {
      final gender = user['gender'];
      genderCount[gender] = (genderCount[gender] ?? 0) + 1;

      final country = user['country'];
      if (country == 'Singapore' || country == 'Malaysia') {
        countryCount[country] = (countryCount[country] ?? 0) + 1;
      } else {
        countryCount['Others'] = countryCount['Others']! + 1;
      }

      final birthDate = DateTime.parse(user['birth_date']);
      final age = now.year - birthDate.year - ((now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) ? 1 : 0);

      if (age >= 18 && age <= 25) {
        ageGroups['18-25'] = ageGroups['18-25']! + 1;
      } else if (age <= 35) {
        ageGroups['26-35'] = ageGroups['26-35']! + 1;
      } else {
        ageGroups['36+'] = ageGroups['36+']! + 1;
      }
    }

    stats['genderCount'] = genderCount;
    stats['countryCount'] = countryCount;
    stats['ageGroups'] = ageGroups;

    // Business profiles
    final businessResponse = await supabase
        .from('business_profiles')
        .select('uid, country')
        .filter('uid', 'in', '(${activeBusinessUids.join(",")})');
    final nutritionistResponse = await supabase
        .from('nutritionist_profiles')
        .select('uid')
        .filter('uid', 'in', '(${activeBusinessUids.join(",")})');

    final businessTypes = {
      'Food & Meal Providers': businessResponse.length,
      'Dietitians & Nutritionists': nutritionistResponse.length
    };

    final businessCountries = {'Singapore': 0, 'Malaysia': 0, 'Others': 0};

    for (final b in businessResponse) {
      final country = b['country'];
      if (country == 'Singapore' || country == 'Malaysia') {
        businessCountries[country] = (businessCountries[country] ?? 0) + 1;
      } else {
        businessCountries['Others'] = businessCountries['Others']! + 1;
      }
    }

    stats['activeBusinesses'] = businessResponse.length;
    stats['activeNutritionists'] = nutritionistResponse.length;
    stats['businessTypes'] = businessTypes;
    stats['businessCountries'] = businessCountries;

    // Fetch recipes
    final recipeResponse = await supabase.from('recipes').select('id, title, dish_types');
    final recipes = recipeResponse as List;
    stats['recipeCount'] = recipes.length;

    // Process dish types
    final recipeDishTypes = {'Breakfast': 0, 'Lunch': 0, 'Dinner': 0, 'Snack': 0, 'Dessert': 0, 'Appetizer': 0, 'Main Course': 0, 'Side Dish': 0};
    for (final recipe in recipes) {
      final List<String> dishTypes = List<String>.from(recipe['dish_types'] ?? []);
      for (final dish in dishTypes) {
        if (recipeDishTypes.containsKey(dish)) {
          recipeDishTypes[dish] = recipeDishTypes[dish]! + 1;
        }
      }
    }
    stats['dishTypeDistribution'] = recipeDishTypes;

    // Fetch recipe favourites
    final favResponse = await supabase.from('recipes_favourite').select('recipe_id');
    final favourites = favResponse as List;

    final Map<int, int> favCountMap = {};
    for (final fav in favourites) {
      final recipeId = fav['recipe_id'];
      favCountMap[recipeId] = (favCountMap[recipeId] ?? 0) + 1;
    }

    final top5 = favCountMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top5Ids = top5.take(5).toList();

    final topRecipeNames = <String>[];
    for (final entry in top5Ids) {
      // Check local recipe
      final recipe = recipes.firstWhereOrNull((r) => r['id'] == entry.key);

      if (recipe != null && recipe['title'] != null) {
        topRecipeNames.add('${recipe['title']} (${entry.value} favs)');
      } else {
        // Check Spoonacular
        final spoonacularRecipe = await apiService.fetchRecipeById(entry.key);
        if (spoonacularRecipe != null) {
          topRecipeNames.add('${spoonacularRecipe['title']} (${entry.value} favs)');
        }
      }
    }

    stats['topRecipes'] = topRecipeNames;

    return stats;
  }
}