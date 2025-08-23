class Task {
  final String id;
  String associatedMilestoneId;
  String name;
  bool completed;
  DateTime? dueDate;

  Task({
    required this.id,
    required this.associatedMilestoneId,
    required this.name,
    this.completed = false,
    this.dueDate,
  });
}