class Milestone {
  final String id;
  String title;
  DateTime? targetDate; // Defaults to now if not provided
  String? associatedGoalID;
  // List<String> taskIds;

  Milestone({
    required this.id,
    required this.title,
    this.targetDate,
    this.associatedGoalID,
    // List<String>? taskIds,
  }); // ✅ constructor properly closed

  Milestone copyWith({
    String? id,
    String? title,
    DateTime? targetDate,
    String? associatedGoalID,
    // List<String>? taskIds,
  }) {
    return Milestone(
      id: id ?? this.id,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      associatedGoalID: associatedGoalID ?? this.associatedGoalID,
      // taskIds: taskIds ?? this.taskIds,
    );
  }
}
