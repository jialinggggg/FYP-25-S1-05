class RecipeReport {
  final String reportId;
  final String uid;
  final int recipeId;
  final String type;
  final String comment;
  final String status;
  final String? sourceType;
  final DateTime createdAt;

  RecipeReport({
    required this.reportId,
    required this.uid,
    required this.recipeId,
    required this.type,
    required this.comment,
    this.status = 'pending',
    this.sourceType,
    required this.createdAt,
  });

  factory RecipeReport.fromMap(Map<String, dynamic> map) {
    return RecipeReport(
      reportId: map['report_id'] as String,
      uid: map['uid'] as String,
      recipeId: map['recipe_id'] as int,
      type: map['report_type'] as String,
      comment: map['comment'] as String,
      status: map['status'] as String,
      sourceType: map['source_type'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'report_id': reportId,
      'uid': uid,
      'recipe_id': recipeId,
      'report_type': type,
      'comment': comment,
      'status': status,
      'source_type': sourceType,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}