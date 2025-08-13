import 'package:hive/hive.dart';
import 'task_model.dart';

part 'milestone_model.g.dart';

@HiveType(typeId: 2)
class MilestoneModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  // Optional tasks
  @HiveField(2)
  List<TaskModel> tasks;

  MilestoneModel({
    required this.id,
    required this.title,
    List<TaskModel>? tasks,
  }) : tasks = tasks ?? [];
}
