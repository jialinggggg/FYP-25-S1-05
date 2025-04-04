class SpoonacularRecipe {
  final int id;
  final String title;
  final String image;
  final int servings;
  final int readyInMinutes;
  final String? sourceName;
  final String? sourceURL;
  final List<String> diets;
  final List<String> dishTypes;
  final Nutrition nutrition;

  SpoonacularRecipe({
    required this.id,
    required this.title,
    required this.image,
    required this.servings,
    required this.readyInMinutes,
    this.sourceName,
    this.sourceURL,
    required this.diets,
    required this.dishTypes,
    required this.nutrition,
  });

  factory SpoonacularRecipe.fromJson(Map<String, dynamic> json) {
    return SpoonacularRecipe(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      servings: json['servings'],
      readyInMinutes: json['readyInMinutes'],
      sourceName: json['sourceName'],
      sourceURL: json['sourceUrl'],
      diets: List<String>.from(json['diets'] ?? []),
      dishTypes: List<String>.from(json['dishTypes'] ?? []),
      nutrition: Nutrition.fromJson(json['nutrition']['nutrients']),
    );
  }
}

class Nutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fats;

  Nutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  factory Nutrition.fromJson(List<dynamic> nutrients) {
    double getValue(String nutrientName) {
      return nutrients
          .firstWhere(
            (n) => n['title'] == nutrientName,
            orElse: () => {'amount': 0},
          )['amount']
          .toDouble();
    }

    return Nutrition(
      calories: getValue('Calories'),
      protein: getValue('Protein'),
      carbs: getValue('Carbohydrates'),
      fats: getValue('Fat'),
    );
  }
}
