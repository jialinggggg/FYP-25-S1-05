class RecipeReport {
  final String reportId;
  final String uid;
  final int recipeId;
  final String type;
  final String comment;
  final String status;
  final DateTime createdAt;

  RecipeReport({
    required this.reportId,
    required this.uid,
    required this.recipeId,
    required this.type,
    required this.comment,
    required this.status,
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
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  RecipeReport copyWith({
    String? reportId,
    String? uid,
    int? recipeId,
    String? type,
    String? comment,
    String? status,
    DateTime? createdAt,
  }) {
    return RecipeReport(
      reportId: reportId ?? this.reportId,
      uid: uid ?? this.uid,
      recipeId: recipeId ?? this.recipeId,
      type: type ?? this.type,
      comment: comment ?? this.comment,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'RecipeReport(reportId: $reportId, uid: $uid, recipeId: $recipeId, type: $type, comment: $comment, status: $status, createdAt: $createdAt)';
  }
}