class Nutrition {
  final List<Nutrient> nutrients;

  Nutrition({
    required this.nutrients,
  });

  // toMap to convert Nutrition to a map
  Map<String, dynamic> toMap() {
    return {
      'nutrients': nutrients.map((n) => n.toMap()).toList(),
    };
  }

  // fromMap to create Nutrition object from a map
  factory Nutrition.fromMap(Map<String, dynamic> map) {
    return Nutrition(
      nutrients: (map['nutrients'] as List)
          .map((i) => Nutrient.fromMap(i as Map<String, dynamic>))
          .toList(),
    );
  }

  // Allows to copy and modify Nutrition object
  Nutrition copyWith({
    List<Nutrient>? nutrients,
  }) {
    return Nutrition(
      nutrients: nutrients ?? this.nutrients,
    );
  }
}

class Nutrient {
  final String title;
  final double amount;
  final String unit;

  Nutrient({
    required this.title,
    required this.amount,
    required this.unit,
  });

  // toMap for converting a Nutrient object to a map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'unit': unit,
    };
  }

  // fromMap to create Nutrient object from a map
  factory Nutrient.fromMap(Map<String, dynamic> map) {
    return Nutrient(
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      unit: map['unit'] as String,
    );
  }

  // Allows to copy and modify Nutrient object
  Nutrient copyWith({
    String? title,
    double? amount,
    String? unit,
  }) {
    return Nutrient(
      title: title ?? this.title,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
    );
  }
}
