import '../entities/nutrition.dart';
import '../entities/recipes.dart';

class MedicalFilterController {
  static bool matchesMedicalCriteria(Recipes recipe, List<String> conditions) {
    if (recipe.nutrition == null) return false;
    final nutrients = recipe.nutrition!.nutrients;

    bool pass = true;

    if (conditions.contains('type 2 diabetes')) {
      final sugar = _getAmount(nutrients, 'Sugar');
      final carbs = _getAmount(nutrients, 'Carbohydrates');
      pass &= sugar < 5 && carbs < 30;
    }

    if (conditions.contains('high blood pressure')) {
      final sodium = _getAmount(nutrients, 'Sodium');
      pass &= sodium < 140;
    }

    return pass;
  }

  static bool matchesAllergies(Recipes recipe, List<String> allergies) {
    if (recipe.extendedIngredients == null) return true;

    for (final allergy in allergies) {
      if (recipe.extendedIngredients!.any((ing) =>
          ing.name.toLowerCase().contains(allergy.toLowerCase()))) {
        return false;
      }
    }
    return true;
  }

  static double _getAmount(List<Nutrient> nutrients, String key) {
    return nutrients.firstWhere((n) =>
      n.title.toLowerCase() == key.toLowerCase(),
      orElse: () => Nutrient(title: key, amount: 0, unit: ''),
    ).amount;
  }
}
