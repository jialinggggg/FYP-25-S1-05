import 'nutrition.dart';

class ExtendedIngredient {
  final int id;
  final String name;
  final double amount;
  final String unit;
  final List<String> possibleUnits;
  final Nutrition? nutrition;

  ExtendedIngredient({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    this.possibleUnits = const [],
    this.nutrition,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'unit': unit,
      'possibleUnits': possibleUnits,
      'nutrition': nutrition?.toMap(),
    };
  }

  factory ExtendedIngredient.fromMap(Map<String, dynamic> map) {
    return ExtendedIngredient(
      id: map['id'] as int,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      unit: map['unit'] as String,
      possibleUnits: List<String>.from(map['possibleUnits'] ?? []),
      nutrition: map['nutrition'] != null ? Nutrition.fromMap(map['nutrition']) : null,
    );
  }

  ExtendedIngredient copyWith({
    int? id,
    String? name,
    double? amount,
    String? unit,
    List<String>? possibleUnits,
    Nutrition? nutrition,
  }) {
    return ExtendedIngredient(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      possibleUnits: possibleUnits ?? this.possibleUnits,
      nutrition: nutrition ?? this.nutrition,
    );
  }
}