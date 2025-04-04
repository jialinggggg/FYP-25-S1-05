class UserGoals {
  final String uid;
  final String goal; // 'Lose Weight', 'Gain Weight', 'Maintain Weight', 'Gain Muscle'
  final String activity; // Activity level
  final double targetWeight;
  final DateTime targetDate;
  final int dailyCalories;
  final double protein;
  final double carbs;
  final double fats;

  UserGoals({
    required this.uid,
    required this.goal,
    required this.activity,
    required this.targetWeight,
    required this.targetDate,
    required this.dailyCalories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  factory UserGoals.fromMap(Map<String, dynamic> map) {
    return UserGoals(
      uid: map['uid'] as String,
      goal: map['goal'] as String,
      activity: map['activity'] as String,
      targetWeight: (map['target_weight'] as num).toDouble(),
      targetDate: DateTime.parse(map['target_date'] as String),
      dailyCalories: map['daily_calories'] as int,
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fats: (map['fats'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'goal': goal,
      'activity': activity,
      'target_weight': targetWeight,
      'target_date': targetDate.toIso8601String(),
      'daily_calories': dailyCalories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }

  UserGoals copyWith({
    String? uid,
    String? goal,
    String? activity,
    double? targetWeight,
    DateTime? targetDate,
    int? dailyCalories,
    double? protein,
    double? carbs,
    double? fats,
  }) {
    return UserGoals(
      uid: uid ?? this.uid,
      goal: goal ?? this.goal,
      activity: activity ?? this.activity,
      targetWeight: targetWeight ?? this.targetWeight,
      targetDate: targetDate ?? this.targetDate,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
    );
  }

  @override
  String toString() {
    return 'UserGoals(uid: $uid, goal: $goal, activity: $activity, '
        'targetWeight: $targetWeight, targetDate: $targetDate, dailyCalories: $dailyCalories, '
        'protein: $protein, carbs: $carbs, fats: $fats)';
  }
}