import 'recipe.dart';
import 'spoonacular_recipe.dart';

class RecipeItem {
  final String id;
  final String title;
  final String image;
  final int calories;
  final String sourceType;
  final bool isFromDatabase;

  RecipeItem({
    required this.id,
    required this.title,
    required this.image,
    required this.calories,
    required this.sourceType,
    required this.isFromDatabase,
  });

  factory RecipeItem.fromDatabaseRecipe(Recipe recipe) {
    return RecipeItem(
      id: recipe.id.toString(),
      title: recipe.name,
      image: recipe.image ?? 'https://via.placeholder.com/150',
      calories: recipe.calories,
      sourceType: recipe.sourceType,
      isFromDatabase: true,
    );
  }

  factory RecipeItem.fromSpoonacularRecipe(SpoonacularRecipe recipe) {
    return RecipeItem(
      id: recipe.id.toString(),
      title: recipe.title,
      image: recipe.image,
      calories: recipe.nutrition.calories.round(),
      sourceType: recipe.sourceName ?? 'Spoonacular',
      isFromDatabase: false,
    );
  }
}