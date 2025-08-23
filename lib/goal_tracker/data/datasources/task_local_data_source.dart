import 'package:hive/hive.dart';
import '../models/task_model.dart';

class TaskLocalDataSource {
  final Box<TaskModel> taskBox;

  TaskLocalDataSource(this.taskBox);

  // Retrieve all Tasks from the box
  List<TaskModel> getTasks() {
    return taskBox.values.toList();
  }

  // Get a single Task by id
  TaskModel? getTaskById(String id) {
    return taskBox.get(id);
  }

    // Get a single Task by id
  TaskModel? getTaskByName(String name) {
    return taskBox.get(name);
  }

  // Add a new Task
  Future<void> addTask(TaskModel task) async {
    await taskBox.put(task.id, task);
  }

  // Update an existing Task
  Future<void> updateTask(TaskModel task) async {
    await taskBox.put(task.id, task);
  }

  // Delete a Task by id
  Future<void> deleteTask(String id) async {
    await taskBox.delete(id);
  }

  // Additional utility: Clear all tasks (optional)
  Future<void> clearAll() async {
    await taskBox.clear();
  }

    // Retrieve all Tasks from the box
  List<TaskModel> getTasksForMilestone(String associatedMilestoneId) {
    return taskBox.values.toList().where((t) => t.associatedMilestoneId == associatedMilestoneId).toList();
  }
}
