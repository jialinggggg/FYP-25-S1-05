class Recipe {
  final int id;
  final String uid;
  final String? image;
  final String name;
  final int calories;
  final double carbs;
  final double protein;
  final double fats;
  final int servings;
  final int readyInMinutes;  // Added this field
  final Map<String, dynamic> ingredients;
  final Map<String, dynamic> instructions;
  final String dishType;
  final List<String>? diets;
  final String sourceName;
  final String sourceType;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.uid,
    this.image,
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fats,
    required this.servings,
    required this.readyInMinutes,  // Added to constructor
    required this.ingredients,
    required this.instructions,
    required this.dishType,
    this.diets,
    required this.sourceName,
    required this.sourceType,
    required this.createdAt,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as int,
      uid: map['uid'] as String,
      image: map['image'] as String?,
      name: map['name'] as String,
      calories: map['calories'] as int,
      carbs: (map['carbs'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      fats: (map['fats'] as num).toDouble(),
      servings: map['servings'] as int,
      readyInMinutes: map['ready_in_minutes'] as int,  // Added mapping
      ingredients: Map<String, dynamic>.from(map['ingredients'] as Map),
      instructions: Map<String, dynamic>.from(map['instructions'] as Map),
      dishType: map['dish_type'] as String,
      diets: map['diets'] != null ? List<String>.from(map['diets'] as List) : null,
      sourceName: map['source_name'] as String,
      sourceType: map['source_type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'image': image,
      'name': name,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fats': fats,
      'servings': servings,
      'ready_in_minutes': readyInMinutes,  // Added to map
      'ingredients': ingredients,
      'instructions': instructions,
      'dish_type': dishType,
      'diets': diets,
      'source_name': sourceName,
      'source_type': sourceType,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  Recipe copyWith({
    int? id,
    String? uid,
    String? image,
    String? name,
    int? calories,
    double? carbs,
    double? protein,
    double? fats,
    int? servings,
    int? readyInMinutes,  // Added to copyWith
    Map<String, dynamic>? ingredients,
    Map<String, dynamic>? instructions,
    String? dishType,
    List<String>? diets,
    String? sourceName,
    String? sourceType,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      image: image ?? this.image,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fats: fats ?? this.fats,
      servings: servings ?? this.servings,
      readyInMinutes: readyInMinutes ?? this.readyInMinutes,  // Added
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      dishType: dishType ?? this.dishType,
      diets: diets ?? this.diets,
      sourceName: sourceName ?? this.sourceName,
      sourceType: sourceType ?? this.sourceType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Recipe(id: $id, uid: $uid, image: $image, name: $name, calories: $calories, '
        'carbs: $carbs, protein: $protein, fats: $fats, servings: $servings, '
        'readyInMinutes: $readyInMinutes, '  // Added to toString
        'dishType: $dishType, diets: $diets, sourceName: $sourceName, '
        'sourceType: $sourceType, createdAt: $createdAt)';
  }
}