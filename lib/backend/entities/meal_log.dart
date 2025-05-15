import 'nutrition.dart';

class MealLog {
  final String? mealId;
  final String uid;
  final int recipeId;
  final String sourceType;
  final String mealName;
  final String mealType;
  final String image;
  final Nutrition nutrition;
  final DateTime createdAt;

  MealLog({
    this.mealId,
    required this.uid,
    required this.recipeId,
    required this.sourceType,
    required this.mealName,
    required this.mealType,
    required this.image,
    required this.nutrition,
    required this.createdAt,
  });

  // Updated fromJson to properly map the nutrition field to a Nutrition object
  factory MealLog.fromMap(Map<String, dynamic> map) {
    return MealLog(
      mealId: map['meal_id'] as String?,
      uid: map['uid'] as String,
      recipeId: map['recipe_id'] as int,
      sourceType: map['source_type'] as String,
      mealName: map['meal_name'] as String,
      mealType: map['meal_type'] as String,
      image: map['image'] as String,
      nutrition: Nutrition.fromMap(map['nutrition'] as Map<String, dynamic>), // Parse nutrition field correctly
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  // toMap to convert MealLog to a map
  Map<String, dynamic> toMap() {
    return {
      if (mealId != null) 'meal_id': mealId,
      'uid': uid,
      'recipe_id': recipeId,
      'source_type': sourceType,
      'meal_name': mealName,
      'meal_type': mealType,
      'image': image,
      'nutrition': nutrition.toMap(), // Convert nutrition to map for serialization
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}

