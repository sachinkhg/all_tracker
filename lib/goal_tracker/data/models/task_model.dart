import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 1) // keep your existing typeId if already used
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  /// FK → MilestoneModel.id
  @HiveField(1)
  String associatedMilestoneId;

  @HiveField(2)
  String name;

  /// Authoritative flag for task completion.
  @HiveField(3)
  bool completed;

  @HiveField(4)
  DateTime? dueDate;

  TaskModel({
    required this.id,
    required this.associatedMilestoneId,
    required this.name,
    this.completed = false,
    this.dueDate,
  });
}
