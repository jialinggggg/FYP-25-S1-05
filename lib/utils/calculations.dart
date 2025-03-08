class Calculations {
  // Calculate IBW based on gender and height
  static double calculateIdealBodyWeight(String gender, double heightInCm) {
    if (gender == 'Male'){
      return 22 * (heightInCm / 100) * (heightInCm / 100);
    } else {
      return 22 * ((heightInCm - 10)/ 100) * ((heightInCm - 10)/ 100);
    }
  }

  // Calculate BMR based on gender, weight, height, and age
  static double calculateBMR(String gender, double weightInKg, double heightInCm, int age) {
    if (gender == 'Male') {
      return (10 * weightInKg) + (6.25 * heightInCm) - (5 * age) + 5;
    } else {
      return (10 * weightInKg) + (6.25 * heightInCm) - (5 * age) - 161;
   }
  }

  // Calculate macronutrient goals (protein, fats, carbs) based on daily calories
  static Map<String, double> calculateMacronutrients(int dailyCalories) {
    return {
      'protein': (dailyCalories * 0.3 / 4).roundToDouble(), // 30% of calories from protein
      'fats': (dailyCalories * 0.3 / 9).roundToDouble(), // 30% of calories from fats
      'carbs': (dailyCalories * 0.4 / 4).roundToDouble(), // 40% of calories from carbs
    };
  }
}