import 'task.dart';

class Milestone {
  final String id;
  String title;
  DateTime? targetDate; // Defaults to now if not provided
  List<Task> tasks;

  Milestone({
    required this.id,
    required this.title,
    this.targetDate,
    List<Task>? tasks,
  })  : tasks = tasks ?? [];                // ✅ default to empty list
}