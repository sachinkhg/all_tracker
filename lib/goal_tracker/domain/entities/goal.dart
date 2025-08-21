class Goal {
  final String id;
  String title;
  String description;
  DateTime? targetDate;
  List<String> milestoneIds;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    this.targetDate,
    List<String>? milestoneIds,
  })  : milestoneIds = milestoneIds ?? [];

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? targetDate,
    List<String>? milestoneIds,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      milestoneIds: milestoneIds ?? this.milestoneIds,
    );
  }
}
