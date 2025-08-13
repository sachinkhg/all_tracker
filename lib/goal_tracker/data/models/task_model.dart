import 'package:hive/hive.dart';
import 'checklist_model.dart';

part 'task_model.g.dart';

@HiveType(typeId: 1)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;

  @HiveField(2)
  bool completed;

  // Optional list of checklists
  @HiveField(3)
  List<ChecklistModel> checklists;

  TaskModel({
    required this.id,
    required this.name,
    this.completed = false,
    List<ChecklistModel>? checklists,
  }) : checklists = checklists ?? [];
}
