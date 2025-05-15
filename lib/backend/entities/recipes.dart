import 'nutrition.dart';
import 'analyzed_instruction.dart';
import 'extended_ingredient.dart';

class Recipes {
  final int id;
  final String? uid;
  final String title;
  final String? image;
  final String? imageType;
  final int? servings;
  final int? readyInMinutes;
  final String? sourceName;
  final String? sourceType;
  final List<AnalyzedInstruction>? analyzedInstructions;
  final List<ExtendedIngredient>? extendedIngredients;
  final List<String>? diets;
  final List<String>? dishTypes;
  final Nutrition? nutrition;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Recipes({
    required this.id,
    this.uid,
    required this.title,
    this.image,
    this.imageType,
    this.servings,
    this.readyInMinutes,
    this.sourceName,
    this.sourceType,
    this.analyzedInstructions,
    this.extendedIngredients,
    this.diets,
    this.dishTypes,
    this.nutrition,
    this.createdAt,
    this.updatedAt,
  });

  // Convert Recipe to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'title': title,
      'image': image,
      'image_type': imageType,
      'servings': servings,
      'ready_in_minutes': readyInMinutes,
      'source_name': sourceName,
      'source_type': sourceType,
      'analyzed_instructions': analyzedInstructions?.map((i) => i.toMap()).toList(),
      'extended_ingredients': extendedIngredients?.map((i) => i.toMap()).toList(),
      'diets': diets,
      'dish_types': dishTypes,
      'nutrition': nutrition?.toMap(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create Recipe from Map (both from API and database)
  factory Recipes.fromMap(Map<String, dynamic> map) {
    return Recipes(
      id: map['id'] as int,
      uid: map['uid'] as String?,
      title: map['title'] as String,
      image: map['image'] as String?,
      imageType: map['imageType'] ?? map['image_type'] as String?,
      servings: map['servings'] as int?,
      readyInMinutes: map['readyInMinutes'] ?? map['ready_in_minutes'] as int?,
      sourceName: map['sourceName'] ?? map['source_name'] as String?,
      sourceType: map['sourceType'] ?? map['source_type'] as String?,
      analyzedInstructions: map['analyzedInstructions'] != null
          ? (map['analyzedInstructions'] as List).map((i) => AnalyzedInstruction.fromMap(i)).toList()
          : map['analyzed_instructions'] != null
              ? (map['analyzed_instructions'] as List).map((i) => AnalyzedInstruction.fromMap(i)).toList()
              : null,
      extendedIngredients: map['extendedIngredients'] != null
          ? (map['extendedIngredients'] as List).map((i) => ExtendedIngredient.fromMap(i)).toList()
          : map['extended_ingredients'] != null
              ? (map['extended_ingredients'] as List).map((i) => ExtendedIngredient.fromMap(i)).toList()
              : null,
      diets: map['diets'] != null ? List<String>.from(map['diets']) : null,
      dishTypes: map['dishTypes'] != null 
          ? List<String>.from(map['dishTypes'])
          : map['dish_types'] != null
              ? List<String>.from(map['dish_types'])
              : null,
      nutrition: map['nutrition'] != null ? Nutrition.fromMap(map['nutrition']) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  // Copy with method for immutability
  Recipes copyWith({
    int? id,
    String? uid,
    String? title,
    String? image,
    String? imageType,
    int? servings,
    int? readyInMinutes,
    String? sourceName,
    String? sourceType,
    List<AnalyzedInstruction>? analyzedInstructions,
    List<ExtendedIngredient>? extendedIngredients,
    List<String>? diets,
    List<String>? dishTypes,
    Nutrition? nutrition,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipes(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      image: image ?? this.image,
      imageType: imageType ?? this.imageType,
      servings: servings ?? this.servings,
      readyInMinutes: readyInMinutes ?? this.readyInMinutes,
      sourceName: sourceName ?? this.sourceName,
      sourceType: sourceType ?? this.sourceType,
      analyzedInstructions: analyzedInstructions ?? this.analyzedInstructions,
      extendedIngredients: extendedIngredients ?? this.extendedIngredients,
      diets: diets ?? this.diets,
      dishTypes: dishTypes ?? this.dishTypes,
      nutrition: nutrition ?? this.nutrition,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}