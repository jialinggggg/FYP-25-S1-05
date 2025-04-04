class MealEntry {
  final String? mealId;
  final int spoonacularId;
  final String uid;
  final String name;
  final int calories;
  final double carbs;
  final double protein;
  final double fats;
  final String type;
  final DateTime createdAt;

  MealEntry({
    this.mealId,
    required this.spoonacularId,
    required this.uid,
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fats,
    required this.type,
    required this.createdAt,
  });

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      mealId: map['meal_id'] as String?,
      spoonacularId: map['spoonacular_id'] as int,
      uid: map['uid'] as String,
      name: map['name'] as String,
      calories: map['calories'] as int,
      carbs: (map['carbs'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      fats: (map['fats'] as num).toDouble(),
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (mealId != null) 'meal_id': mealId,
      'spoonacular_id': spoonacularId,
      'uid': uid,
      'name': name,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fats': fats,
      'type': type,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  MealEntry copyWith({
    String? mealId,
    int? spoonacularId,
    String? uid,
    String? name,
    int? calories,
    double? carbs,
    double? protein,
    double? fats,
    String? type,
    DateTime? createdAt,
  }) {
    return MealEntry(
      mealId: mealId ?? this.mealId,
      spoonacularId: spoonacularId ?? this.spoonacularId,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fats: fats ?? this.fats,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'MealEntry(mealId: $mealId, spoonacularId: $spoonacularId, uid: $uid, name: $name, calories: $calories, carbs: $carbs, protein: $protein, fats: $fats, type: $type, createdAt: $createdAt)';
  }
}